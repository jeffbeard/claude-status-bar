import Foundation
import SQLite3
import os

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "ClaudeStatusBar",
    category: "SQLiteStore"
)

public struct DailyComponentStatus: Sendable, Identifiable, Equatable {
    public var id: String { "\(dateString)_\(componentId)" }
    public let dateString: String
    public let componentId: String
    public let componentName: String
    public let status: ComponentStatus

    public init(dateString: String, componentId: String, componentName: String, status: ComponentStatus) {
        self.dateString = dateString
        self.componentId = componentId
        self.componentName = componentName
        self.status = status
    }
}

public struct IncidentLogRecord: Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let status: IncidentStatus
    public let impact: String?
    public let createdAt: Date?
    public let updatedAt: Date?

    public init(id: String, name: String, status: IncidentStatus, impact: String?, createdAt: Date?, updatedAt: Date?) {
        self.id = id
        self.name = name
        self.status = status
        self.impact = impact
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public actor SQLiteStore: Sendable {
    public static let shared: SQLiteStore = {
        do {
            return try SQLiteStore()
        } catch {
            fatalError("Failed to initialize shared SQLiteStore: \(error)")
        }
    }()

    nonisolated(unsafe) private var db: OpaquePointer?
    public private(set) var isInitialized: Bool = false

    public init(dbPath: String? = nil) throws {
        let path: String
        if let dbPath = dbPath {
            path = dbPath
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appDir = appSupport.appendingPathComponent("ClaudeStatusBar", isDirectory: true)
            try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true, attributes: nil)
            path = appDir.appendingPathComponent("status_history.sqlite").path
        }

        var dbPointer: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        if sqlite3_open_v2(path, &dbPointer, flags, nil) != SQLITE_OK {
            let errMsg = String(cString: sqlite3_errmsg(dbPointer))
            sqlite3_close(dbPointer)
            throw NSError(domain: "SQLiteStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to open SQLite DB at \(path): \(errMsg)"])
        }

        self.db = dbPointer
        try Self.createTables(db: dbPointer)
        self.isInitialized = true
    }

    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }

    // MARK: - Schema Initialization

    private static func createTables(db: OpaquePointer?) throws {
        let createStatusSnapshots = """
        CREATE TABLE IF NOT EXISTS status_snapshots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp REAL NOT NULL,
            indicator TEXT NOT NULL,
            description TEXT
        );
        """

        let createComponentSnapshots = """
        CREATE TABLE IF NOT EXISTS component_snapshots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            snapshot_id INTEGER NOT NULL,
            component_id TEXT NOT NULL,
            component_name TEXT NOT NULL,
            status TEXT NOT NULL,
            updated_at REAL,
            FOREIGN KEY(snapshot_id) REFERENCES status_snapshots(id) ON DELETE CASCADE
        );
        """

        let createIncidents = """
        CREATE TABLE IF NOT EXISTS incidents (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            status TEXT NOT NULL,
            impact TEXT,
            created_at REAL,
            updated_at REAL
        );
        """

        try execute(db: db, sql: createStatusSnapshots)
        try execute(db: db, sql: createComponentSnapshots)
        try execute(db: db, sql: createIncidents)
    }

    private static func execute(db: OpaquePointer?, sql: String) throws {
        var errMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errMsg) != SQLITE_OK {
            let message = errMsg.map { String(cString: $0) } ?? "Unknown error"
            sqlite3_free(errMsg)
            throw NSError(domain: "SQLiteStore", code: 2, userInfo: [NSLocalizedDescriptionKey: "SQLite exec error: \(message)"])
        }
    }

    // MARK: - Snapshot Recording

    public func recordSnapshot(summary: SummaryResponse, timestamp: Date = Date()) throws {
        guard let db = db else { return }

        // 1. Insert Status Snapshot
        let insertStatusSQL = "INSERT INTO status_snapshots (timestamp, indicator, description) VALUES (?, ?, ?);"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertStatusSQL, -1, &stmt, nil) == SQLITE_OK else {
            throw NSError(domain: "SQLiteStore", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to prepare insert status SQL"])
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_double(stmt, 1, timestamp.timeIntervalSince1970)
        sqlite3_bind_text(stmt, 2, (summary.status.indicator.rawValue as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (summary.status.description as NSString).utf8String, -1, nil)

        if sqlite3_step(stmt) != SQLITE_DONE {
            throw NSError(domain: "SQLiteStore", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to insert status snapshot"])
        }

        let snapshotId = sqlite3_last_insert_rowid(db)

        // 2. Insert Component Snapshots
        let insertComponentSQL = "INSERT INTO component_snapshots (snapshot_id, component_id, component_name, status, updated_at) VALUES (?, ?, ?, ?, ?);"
        for component in summary.components where component.shouldDisplay {
            var compStmt: OpaquePointer?
            if sqlite3_prepare_v2(db, insertComponentSQL, -1, &compStmt, nil) == SQLITE_OK {
                sqlite3_bind_int64(compStmt, 1, snapshotId)
                sqlite3_bind_text(compStmt, 2, (component.id as NSString).utf8String, -1, nil)
                sqlite3_bind_text(compStmt, 3, (component.name as NSString).utf8String, -1, nil)
                sqlite3_bind_text(compStmt, 4, (component.status.rawValue as NSString).utf8String, -1, nil)
                if let updatedAt = component.updatedAt {
                    sqlite3_bind_double(compStmt, 5, updatedAt.timeIntervalSince1970)
                } else {
                    sqlite3_bind_null(compStmt, 5)
                }
                sqlite3_step(compStmt)
                sqlite3_finalize(compStmt)
            }
        }

        // 3. Upsert Incidents
        let upsertIncidentSQL = """
        INSERT INTO incidents (id, name, status, impact, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
            name = excluded.name,
            status = excluded.status,
            impact = excluded.impact,
            updated_at = excluded.updated_at;
        """
        for incident in summary.incidents {
            var incStmt: OpaquePointer?
            if sqlite3_prepare_v2(db, upsertIncidentSQL, -1, &incStmt, nil) == SQLITE_OK {
                sqlite3_bind_text(incStmt, 1, (incident.id as NSString).utf8String, -1, nil)
                sqlite3_bind_text(incStmt, 2, (incident.name as NSString).utf8String, -1, nil)
                sqlite3_bind_text(incStmt, 3, (incident.status.rawValue as NSString).utf8String, -1, nil)
                if let impact = incident.impact {
                    sqlite3_bind_text(incStmt, 4, (impact as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(incStmt, 4)
                }
                if let createdAt = incident.createdAt {
                    sqlite3_bind_double(incStmt, 5, createdAt.timeIntervalSince1970)
                } else {
                    sqlite3_bind_null(incStmt, 5)
                }
                if let updatedAt = incident.updatedAt {
                    sqlite3_bind_double(incStmt, 6, updatedAt.timeIntervalSince1970)
                } else {
                    sqlite3_bind_null(incStmt, 6)
                }
                sqlite3_step(incStmt)
                sqlite3_finalize(incStmt)
            }
        }
    }

    // MARK: - Availability Queries

    public func fetchAvailability(days: Int) throws -> (availabilityPercentage: Double, totalSnapshots: Int, operationalSnapshots: Int) {
        guard let db = db else { return (100.0, 0, 0) }

        let cutoffDate = Date().addingTimeInterval(-Double(days * 24 * 3600)).timeIntervalSince1970
        let sql = "SELECT indicator FROM status_snapshots WHERE timestamp >= ?;"

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return (100.0, 0, 0)
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_double(stmt, 1, cutoffDate)

        var total = 0
        var operational = 0

        while sqlite3_step(stmt) == SQLITE_ROW {
            total += 1
            if let cStr = sqlite3_column_text(stmt, 0) {
                let indicatorStr = String(cString: cStr)
                let indicator = StatusIndicator(rawValue: indicatorStr)
                if indicator == .operational {
                    operational += 1
                }
            }
        }

        guard total > 0 else { return (100.0, 0, 0) }
        let percentage = (Double(operational) / Double(total)) * 100.0
        return (percentage, total, operational)
    }

    // MARK: - Daily Component Status Query

    public func fetchDailyComponentStatuses(days: Int) throws -> [DailyComponentStatus] {
        guard let db = db else { return [] }

        let cutoffDate = Date().addingTimeInterval(-Double(days * 24 * 3600)).timeIntervalSince1970
        let sql = """
        SELECT
            strftime('%Y-%m-%d', datetime(s.timestamp, 'unixepoch', 'localtime')) as date_str,
            c.component_id,
            c.component_name,
            c.status
        FROM component_snapshots c
        JOIN status_snapshots s ON c.snapshot_id = s.id
        WHERE s.timestamp >= ?
        ORDER BY date_str ASC, c.component_name ASC;
        """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_double(stmt, 1, cutoffDate)

        // Store worst status for each date + component
        var statusMap: [String: [String: (name: String, worstStatus: ComponentStatus)]] = [:]

        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let dateCString = sqlite3_column_text(stmt, 0),
                  let compIdCString = sqlite3_column_text(stmt, 1),
                  let compNameCString = sqlite3_column_text(stmt, 2),
                  let statusCString = sqlite3_column_text(stmt, 3) else { continue }

            let dateStr = String(cString: dateCString)
            let compId = String(cString: compIdCString)
            let compName = String(cString: compNameCString)
            let status = ComponentStatus(rawValue: String(cString: statusCString))

            if statusMap[dateStr] == nil {
                statusMap[dateStr] = [:]
            }

            if let existing = statusMap[dateStr]?[compId] {
                let worst = worseStatus(existing.worstStatus, status)
                statusMap[dateStr]?[compId] = (compName, worst)
            } else {
                statusMap[dateStr]?[compId] = (compName, status)
            }
        }

        var results: [DailyComponentStatus] = []
        for (dateStr, components) in statusMap {
            for (compId, val) in components {
                results.append(DailyComponentStatus(
                    dateString: dateStr,
                    componentId: compId,
                    componentName: val.name,
                    status: val.worstStatus
                ))
            }
        }

        return results.sorted { $0.dateString < $1.dateString }
    }

    private func worseStatus(_ a: ComponentStatus, _ b: ComponentStatus) -> ComponentStatus {
        let severity: (ComponentStatus) -> Int = { status in
            switch status {
            case .majorOutage: return 5
            case .partialOutage: return 4
            case .degradedPerformance: return 3
            case .underMaintenance: return 2
            case .unknown: return 1
            case .operational: return 0
            }
        }
        return severity(a) >= severity(b) ? a : b
    }

    // MARK: - Incident History Query

    public func fetchIncidentHistory(limit: Int = 50) throws -> [IncidentLogRecord] {
        guard let db = db else { return [] }

        let sql = """
        SELECT id, name, status, impact, created_at, updated_at
        FROM incidents
        ORDER BY created_at DESC
        LIMIT ?;
        """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, Int32(limit))

        var records: [IncidentLogRecord] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = String(cString: sqlite3_column_text(stmt, 0))
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let statusRaw = String(cString: sqlite3_column_text(stmt, 2))
            let status = IncidentStatus(rawValue: statusRaw) ?? .unknown
            let impact = sqlite3_column_text(stmt, 3).map { String(cString: $0) }

            let createdAt: Date?
            if sqlite3_column_type(stmt, 4) != SQLITE_NULL {
                createdAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 4))
            } else {
                createdAt = nil
            }

            let updatedAt: Date?
            if sqlite3_column_type(stmt, 5) != SQLITE_NULL {
                updatedAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 5))
            } else {
                updatedAt = nil
            }

            records.append(IncidentLogRecord(
                id: id,
                name: name,
                status: status,
                impact: impact,
                createdAt: createdAt,
                updatedAt: updatedAt
            ))
        }

        return records
    }

    // MARK: - Retention Purge

    public func purgeOldSnapshots(olderThanDays: Int = 90) throws -> Int {
        guard let db = db else { return 0 }

        let cutoffDate = Date().addingTimeInterval(-Double(olderThanDays * 24 * 3600)).timeIntervalSince1970
        let countSQL = "SELECT COUNT(*) FROM status_snapshots WHERE timestamp < ?;"

        var countStmt: OpaquePointer?
        var countToPurge = 0
        if sqlite3_prepare_v2(db, countSQL, -1, &countStmt, nil) == SQLITE_OK {
            sqlite3_bind_double(countStmt, 1, cutoffDate)
            if sqlite3_step(countStmt) == SQLITE_ROW {
                countToPurge = Int(sqlite3_column_int(countStmt, 0))
            }
            sqlite3_finalize(countStmt)
        }

        let deleteSQL = "DELETE FROM status_snapshots WHERE timestamp < ?;"
        var deleteStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteSQL, -1, &deleteStmt, nil) == SQLITE_OK {
            sqlite3_bind_double(deleteStmt, 1, cutoffDate)
            sqlite3_step(deleteStmt)
            sqlite3_finalize(deleteStmt)
        }

        return countToPurge
    }
}
