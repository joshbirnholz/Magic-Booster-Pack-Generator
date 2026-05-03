//
//  RateLimiter.swift
//  Spellbook
//
//  Created by Josh Birnholz on 6/27/25.
//
import Foundation

public actor RateLimiter {
  private let maxRequests: Int
  private let interval: TimeInterval
  private let margin: TimeInterval
  private var requestTimestamps: [Date] = []

  /// When non-nil, all requests are held until this date (used for 429 penalty periods).
  private var penaltyUntil: Date?

  /// - Parameters:
  ///   - maxRequests: Maximum requests allowed per interval.
  ///   - interval: The sliding window duration in seconds.
  ///   - margin: Extra delay added after each wait to absorb network jitter.
  init(maxRequests: Int, interval: TimeInterval = 1.0, margin: TimeInterval = 0.05) {
    self.maxRequests = maxRequests
    self.interval = interval
    self.margin = margin
  }

  /// Blocks all requests until `date`. Call this on every rate limiter when a 429 is received.
  func applyPenalty(until date: Date) {
    if penaltyUntil == nil || date > penaltyUntil! {
      penaltyUntil = date
    }
  }

  func execute<T>(_ block: @Sendable () async throws -> T) async rethrows -> T {
    // Re-check after each sleep because awaiting suspends the actor,
    // allowing other callers in who may consume the capacity we expected.
    while true {
      // Check penalty period first. A 429 from any endpoint blocks all Scryfall
      // traffic until the server-side ban lifts, so we wait here before
      // attempting to acquire a rate-limit slot.
      if let penalty = penaltyUntil {
        if penalty > Date() {
          let wait = penalty.timeIntervalSinceNow + margin
          try? await Task.sleep(for: .seconds(wait))
          // After waking, clear and re-evaluate from the top.
          penaltyUntil = nil
          continue
        } else {
          penaltyUntil = nil
        }
      }

      if hasCapacity() { break }

      let waitTime = requestTimestamps.first!.addingTimeInterval(interval).timeIntervalSinceNow + margin
      if waitTime > 0 {
        try? await Task.sleep(for: .seconds(waitTime))
      }
    }

    requestTimestamps.append(Date())
    return try await block()
  }

  private func hasCapacity() -> Bool {
    let now = Date()
    requestTimestamps.removeAll { $0 <= now.addingTimeInterval(-interval) }
    return requestTimestamps.count < maxRequests
  }
}
