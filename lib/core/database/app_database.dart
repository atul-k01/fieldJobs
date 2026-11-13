import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'tables.dart';

/// Singleton manager for SQLite local storage.
/// Provides offline-first persistence and durable sync queue execution.
class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'field_jobs_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // 1. Technicians table (Profiles)
    await db.execute('''
      CREATE TABLE ${DbTables.technicians} (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL
      )
    ''');

    // 2. Jobs table
    await db.execute('''
      CREATE TABLE ${DbTables.jobs} (
        ${JobColumns.id} TEXT PRIMARY KEY,
        ${JobColumns.assignedTo} TEXT NOT NULL,
        ${JobColumns.customerName} TEXT NOT NULL,
        ${JobColumns.customerPhone} TEXT NOT NULL,
        ${JobColumns.address} TEXT NOT NULL,
        ${JobColumns.scheduledDate} TEXT NOT NULL,
        ${JobColumns.timeWindow} TEXT NOT NULL,
        ${JobColumns.appliance} TEXT NOT NULL,
        ${JobColumns.problemDescription} TEXT NOT NULL,
        ${JobColumns.status} TEXT NOT NULL,
        ${JobColumns.cannotCompleteReason} TEXT,
        ${JobColumns.technicianNotes} TEXT,
        ${JobColumns.version} INTEGER NOT NULL DEFAULT 1,
        ${JobColumns.syncStatus} TEXT NOT NULL DEFAULT 'synced',
        ${JobColumns.updatedAt} TEXT NOT NULL
      )
    ''');

    // Index for faster queries on technician & date
    await db.execute('''
      CREATE INDEX idx_jobs_assigned_date 
      ON ${DbTables.jobs} (${JobColumns.assignedTo}, ${JobColumns.scheduledDate})
    ''');

    // 3. Job Checklists table
    await db.execute('''
      CREATE TABLE ${DbTables.checklists} (
        ${ChecklistColumns.id} TEXT PRIMARY KEY,
        ${ChecklistColumns.jobId} TEXT NOT NULL,
        ${ChecklistColumns.title} TEXT NOT NULL,
        ${ChecklistColumns.isCompleted} INTEGER NOT NULL DEFAULT 0,
        ${ChecklistColumns.sortOrder} INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (${ChecklistColumns.jobId}) REFERENCES ${DbTables.jobs} (${JobColumns.id}) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_checklists_job_id 
      ON ${DbTables.checklists} (${ChecklistColumns.jobId})
    ''');

    // 4. Job Photos table
    await db.execute('''
      CREATE TABLE ${DbTables.photos} (
        ${PhotoColumns.id} TEXT PRIMARY KEY,
        ${PhotoColumns.jobId} TEXT NOT NULL,
        ${PhotoColumns.localPath} TEXT NOT NULL,
        ${PhotoColumns.remoteUrl} TEXT,
        ${PhotoColumns.createdAt} TEXT NOT NULL,
        FOREIGN KEY (${PhotoColumns.jobId}) REFERENCES ${DbTables.jobs} (${JobColumns.id}) ON DELETE CASCADE
      )
    ''');

    // 5. Durable Sync Queue table (Outbox Pattern)
    await db.execute('''
      CREATE TABLE ${DbTables.syncQueue} (
        ${SyncQueueColumns.id} TEXT PRIMARY KEY,
        ${SyncQueueColumns.jobId} TEXT NOT NULL,
        ${SyncQueueColumns.actionType} TEXT NOT NULL,
        ${SyncQueueColumns.payload} TEXT NOT NULL,
        ${SyncQueueColumns.baseVersion} INTEGER NOT NULL,
        ${SyncQueueColumns.createdAt} TEXT NOT NULL,
        ${SyncQueueColumns.retryCount} INTEGER NOT NULL DEFAULT 0,
        ${SyncQueueColumns.status} TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_sync_queue_created 
      ON ${DbTables.syncQueue} (${SyncQueueColumns.createdAt})
    ''');
  }

  /// Check if there are any pending unsynced changes in the queue
  Future<int> getPendingSyncCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DbTables.syncQueue} WHERE ${SyncQueueColumns.status} != ?',
      ['completed'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Wipes all user-specific data from local SQLite on Sign-out
  /// to ensure no data from previous technician leaks to the next.
  Future<void> wipeAllUserData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(DbTables.syncQueue);
      await txn.delete(DbTables.photos);
      await txn.delete(DbTables.checklists);
      await txn.delete(DbTables.jobs);
      await txn.delete(DbTables.technicians);
    });
  }

  /// Close the database instance
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
