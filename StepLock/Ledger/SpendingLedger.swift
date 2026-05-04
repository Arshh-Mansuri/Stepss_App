//
//  SpendingLedger.swift
//  StepLock
//
//  Created by Aditya Sanap on 4/5/2026.
//


import Foundation
import GRDB

actor SpendingLedger {

    static let shared = SpendingLedger()

    private let db: DatabaseQueue

    init(db: DatabaseQueue = DatabaseManager.shared.dbQueue) {
        self.db = db
    }
}