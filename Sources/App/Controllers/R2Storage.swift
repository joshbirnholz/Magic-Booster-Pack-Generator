//
//  R2Storage.swift
//  TabletopSimulatorMagicBoosterPackServer
//
//  Caches Scryfall card images in Cloudflare R2 so Tabletop Simulator can load
//  them from us instead of hotlinking Scryfall directly (UnityPlayer's user
//  agent is blocked by Scryfall). Reads are served straight from R2's public
//  custom domain (free egress); this type only handles the write side.
//

import Vapor
import SotoS3
import NIOCore
import NIOFoundationCompat

/// Descriptive User-Agent for the server's own requests to Scryfall, so we
/// identify ourselves and don't end up being the next user agent they block.
let scryfallUserAgent = "MagicBoosterServer/1.0 (+https://tts-magic-booster.fly.dev; mailto:compc76@gmail.com)"

/// Configuration for image proxying/caching, read once from the environment.
///
/// All values must be present for caching to activate. When they're absent
/// (e.g. local development), proxying is disabled and the server emits raw
/// Scryfall URLs exactly as before.
struct R2Config: Sendable {
	let accountID: String
	let bucket: String
	let accessKeyID: String
	let secretAccessKey: String
	let publicBaseURL: URL

	static let shared: R2Config? = {
		guard let accountID = Environment.get("R2_ACCOUNT_ID"),
			  let bucket = Environment.get("R2_BUCKET"),
			  let accessKeyID = Environment.get("R2_ACCESS_KEY_ID"),
			  let secretAccessKey = Environment.get("R2_SECRET_ACCESS_KEY"),
			  let publicBase = Environment.get("R2_PUBLIC_BASE_URL"),
			  let publicBaseURL = URL(string: publicBase) else {
			return nil
		}
		return R2Config(accountID: accountID,
						bucket: bucket,
						accessKeyID: accessKeyID,
						secretAccessKey: secretAccessKey,
						publicBaseURL: publicBaseURL)
	}()
}

/// Rewrites Scryfall image URLs to point at our own `/i` proxy route.
enum ImageProxy {
	/// Base URL where the `/i` route is served (this server). When unset, no
	/// rewriting happens and original Scryfall URLs are emitted.
	static let baseURL: URL? = Environment.get("IMAGE_PROXY_BASE_URL").flatMap { URL(string: $0) }

	/// Hosts we proxy. These are the Scryfall-hosted image domains that
	/// UnityPlayer can no longer load directly.
	static let proxiedHosts: Set<String> = ["cards.scryfall.io", "backs.scryfall.io"]

	/// Returns a proxied URL of the form `<base>/i/<host>/<path>` for Scryfall
	/// image URLs, or the original URL unchanged for anything else (or when
	/// proxying is disabled). The query string (a cache-busting timestamp) is
	/// dropped so the same image always maps to the same proxy path / R2 key.
	static func rewrite(_ url: URL) -> URL {
		guard let base = baseURL,
			  let host = url.host,
			  proxiedHosts.contains(host) else {
			return url
		}

		var result = base
		result.appendPathComponent("i")
		result.appendPathComponent(host)
		for component in url.pathComponents where component != "/" {
			result.appendPathComponent(component)
		}
		return result
	}
}

/// Wraps a Soto S3 client configured for Cloudflare R2's S3-compatible API.
final class R2Storage: Sendable {
	private let client: AWSClient
	private let s3: S3
	private let bucket: String
	private let publicBaseURL: URL
	private let logger: Logger

	init(config: R2Config, logger: Logger) {
		self.bucket = config.bucket
		self.publicBaseURL = config.publicBaseURL
		self.logger = logger
		self.client = AWSClient(
			credentialProvider: .static(accessKeyId: config.accessKeyID,
										secretAccessKey: config.secretAccessKey)
		)
		// R2 uses the "auto" region and a per-account endpoint. The S3-style
		// service config signs with this region; R2 accepts it.
		self.s3 = S3(
			client: client,
			region: Region(rawValue: "auto"),
			endpoint: "https://\(config.accountID).r2.cloudflarestorage.com"
		)
	}

	/// Public URL clients (Tabletop Simulator) should fetch the object from.
	func publicURL(forKey key: String) -> URL {
		var url = publicBaseURL
		for component in key.split(separator: "/") {
			url.appendPathComponent(String(component))
		}
		return url
	}

	/// Whether an object already exists in the bucket. A 404 means a genuine
	/// cache miss (expected, quiet). Any *other* error — a 403 from bad
	/// credentials, an R2 outage, a network blip — is logged, because it makes
	/// the caller re-fetch from Scryfall and re-upload, which is exactly the
	/// bulk-hotlinking we're trying to avoid; we still return false (PutObject
	/// is idempotent, so a spurious re-upload is harmless) but it shouldn't be
	/// silent.
	func objectExists(key: String) async -> Bool {
		do {
			_ = try await s3.headObject(.init(bucket: bucket, key: key))
			return true
		} catch {
			let isNotFound = (error as? AWSErrorType)?.context?.responseCode == .notFound
			if !isNotFound {
				logger.warning("R2 HEAD failed for \(key): \(error)")
			}
			return false
		}
	}

	/// Uploads image data under `key`. Marked immutable + long-lived so the
	/// public CDN/domain caches aggressively (Scryfall image URLs never change).
	func put(key: String, data: Data, contentType: String) async throws {
		let body = AWSHTTPBody(buffer: ByteBuffer(data: data))
		let request = S3.PutObjectRequest(
			body: body,
			bucket: bucket,
			cacheControl: "public, max-age=31536000, immutable",
			contentType: contentType,
			key: key
		)
		_ = try await s3.putObject(request)
	}

	func shutdown() async {
		try? await client.shutdown()
	}

	/// Synchronous shutdown for Vapor's sync teardown path (`app.shutdown()`),
	/// which invokes `LifecycleHandler.shutdown(_:)` rather than the async one.
	func shutdownSync() {
		try? client.syncShutdown()
	}
}

// MARK: - Application integration

extension Application {
	private struct R2StorageKey: StorageKey {
		typealias Value = R2Storage
	}

	var r2: R2Storage? {
		get { storage[R2StorageKey.self] }
		set { storage[R2StorageKey.self] = newValue }
	}
}

/// Shuts down the Soto `AWSClient` when the application stops. Both the sync
/// and async teardown paths are covered; Vapor calls whichever matches how the
/// app was shut down (`main.swift` uses the synchronous `app.shutdown()`).
struct R2StorageLifecycle: LifecycleHandler {
	func shutdown(_ application: Application) {
		application.r2?.shutdownSync()
	}

	func shutdownAsync(_ application: Application) async {
		await application.r2?.shutdown()
	}
}
