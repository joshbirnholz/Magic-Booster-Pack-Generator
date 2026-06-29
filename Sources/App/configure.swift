import Fluent
import FluentPostgresDriver
import Vapor

// Called before your application initializes.
public func configure(_ app: Application) throws {
	// Serves files from `Public/` directory
	// app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
	// Configure SQLite database
//	app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

	// Configure migrations
//	app.migrations.add(CreateTodo())

//	app.middleware.use(FileMiddleware.self)
//	app.middleware.use(ErrorMiddleware.self)
	
  let cors = CORSMiddleware(configuration: .init(
    allowedOrigin: .all,
    allowedMethods: [.GET, .POST, .OPTIONS],
    allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
  ))
  app.middleware.use(cors, at: .beginning)

  let file = FileMiddleware(publicDirectory: app.directory.publicDirectory, defaultFile: "index.html")
	app.middleware.use(file)

	// Cloudflare R2 image cache (only active when the R2_* env vars are set).
	if let r2Config = R2Config.shared {
		app.r2 = R2Storage(config: r2Config, logger: app.logger)
		app.lifecycle.use(R2StorageLifecycle())
		app.logger.notice("R2 image cache enabled (bucket: \(r2Config.bucket)).")
	} else {
		app.logger.notice("R2 image cache disabled; serving raw Scryfall image URLs.")
	}

	try routes(app)
}

//import FluentSQLite
//import Vapor
//
///// Called before your application initializes.
//public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
//	// Register providers first
//	try services.register(FluentSQLiteProvider())
//
//	// Register routes to the router
//	let router = EngineRouter.default()
//	try routes(router)
//	services.register(router, as: Router.self)
//
//	// Register middleware
//	var middlewares = MiddlewareConfig() // Create _empty_ middleware config
//	middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
//	middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
//	services.register(middlewares)
//
//	// Configure a SQLite database
//	let sqlite = try SQLiteDatabase(storage: .memory)
//
//	// Register the configured SQLite database to the database config.
//	var databases = DatabasesConfig()
//	databases.add(database: sqlite, as: .sqlite)
//	services.register(databases)
//
//	// Configure migrations
//	var migrations = MigrationConfig()
//	migrations.add(model: Todo.self, database: .sqlite)
//	services.register(migrations)
//}
