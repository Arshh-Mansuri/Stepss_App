//
//  DatabaseManager.swift
//  StepLock
//
//  Created by Aditya Sanap on 4/5/2026.
//


import Foundation
import GRDB

final class DatabaseManager {
    static let shared = DatabaseManager()

    let dbQueue: DatabaseQueue

    private init() {
        do {
            let fileManager = FileManager.default
            
            guard let containerURL = fileManager.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.steplock.shared"
            ) else {
                fatalError("App Group container not found")
            }

            let dbFolder = containerURL.appendingPathComponent("db", isDirectory: true)
            let dbURL = dbFolder.appendingPathComponent("steplock.sqlite")

            // Create directory if needed
            try fileManager.createDirectory(
                at: dbFolder,
                withIntermediateDirectories: true
            )

            // Create database queue
            dbQueue = try DatabaseQueue(path: dbURL.path)

            // Run migrations
            try migrator.migrate(dbQueue)

            // Remove later
            print("✅ Database initialized at:", dbURL.path)

        } catch {
            fatalError("❌ Database init failed: \(error)")
        }
    }
}

private var migrator: DatabaseMigrator {
    var migrator = DatabaseMigrator()

    // MARK: - PointsBalance
    migrator.registerMigration("createPointsBalance") { db in
        try db.create(table: "PointsBalance") { t in
            t.column("id", .integer).primaryKey()
            t.column("balance", .integer).notNull()
            t.column("updated_at", .datetime).notNull()
        }

        // Insert initial balance row
        try db.execute(sql: """
            INSERT INTO PointsBalance (id, balance, updated_at)
            VALUES (1, 0, CURRENT_TIMESTAMP)
        """)
    }

    // MARK: - Transaction
    migrator.registerMigration("createTransaction") { db in
        try db.create(table: "Transaction") { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("type", .text).notNull()              // earn, spend, refund
            t.column("points", .integer).notNull()
            t.column("balance_after", .integer).notNull()
            t.column("metadata", .blob)                   // JSON
            t.column("created_at", .datetime).notNull()
        }
    }

    // MARK: - UnlockRequest
    migrator.registerMigration("createUnlockRequest") { db in
        try db.create(table: "UnlockRequest") { t in
            t.column("id", .text).primaryKey()            // UUID
            t.column("token_data", .blob).notNull()
            t.column("duration_minutes", .integer).notNull()
            t.column("points_spent", .integer).notNull()
            t.column("start_date", .datetime).notNull()
            t.column("end_date", .datetime).notNull()
            t.column("status", .text).notNull()           // pending, scheduled, failed
            t.column("created_at", .datetime).notNull()
        }
    }

    return migrator
}
