import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../sync/models/sync_queue_item.dart';
import '../models/checklist_item_model.dart';
import '../models/job_model.dart';
import '../models/job_photo_model.dart';
import 'demo_data_seeder.dart';

class JobLocalDataSource {
  final AppDatabase _dbManager;
  static const _uuid = Uuid();

  JobLocalDataSource({AppDatabase? dbManager})
      : _dbManager = dbManager ?? AppDatabase.instance;

  /// Ensures at least 200 demo jobs are populated across technicians
  Future<void> ensureDemoDataSeeded(String technicianEmail) async {
    final db = await _dbManager.database;
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DbTables.jobs} WHERE ${JobColumns.assignedTo} = ?',
      [technicianEmail.toLowerCase()],
    );
    final count = Sqflite.firstIntValue(countResult) ?? 0;

    if (count == 0) {
      final allJobs = DemoDataSeeder.generate200Jobs();
      final techJobs = allJobs.where(
        (j) => j.assignedTo.toLowerCase() == technicianEmail.toLowerCase(),
      );

      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final job in techJobs) {
          batch.insert(
            DbTables.jobs,
            job.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          for (final chk in job.checklists) {
            batch.insert(
              DbTables.checklists,
              chk.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
        await batch.commit(noResult: true);
      });
    } else {
      // Ensure existing seeded database has both Overdue jobs and Today's jobs visible for demo testing
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final yesterdayStr = DateFormat('yyyy-MM-dd').format(
        DateTime.now().subtract(const Duration(days: 1)),
      );

      // 1. Ensure at least 2 Overdue jobs from past
      final overdueResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DbTables.jobs} WHERE ${JobColumns.assignedTo} = ? AND ${JobColumns.scheduledDate} < ? AND ${JobColumns.status} NOT IN (?, ?, ?)',
        [technicianEmail.toLowerCase(), todayStr, 'completed', 'could_not_complete', 'cancelled'],
      );
      final overdueCount = Sqflite.firstIntValue(overdueResult) ?? 0;

      if (overdueCount < 2) {
        final needed = 2 - overdueCount;
        final candidateFutureJobs = await db.query(
          DbTables.jobs,
          columns: [JobColumns.id],
          where: '${JobColumns.assignedTo} = ? AND ${JobColumns.scheduledDate} > ? AND ${JobColumns.status} = ?',
          whereArgs: [technicianEmail.toLowerCase(), todayStr, 'assigned'],
          limit: needed,
        );

        for (final jobRow in candidateFutureJobs) {
          await db.update(
            DbTables.jobs,
            {JobColumns.scheduledDate: yesterdayStr},
            where: '${JobColumns.id} = ?',
            whereArgs: [jobRow[JobColumns.id]],
          );
        }
      }

      // 2. Ensure at least 5 active/unfinished jobs for Today
      final activeTodayResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DbTables.jobs} WHERE ${JobColumns.assignedTo} = ? AND ${JobColumns.scheduledDate} = ? AND ${JobColumns.status} NOT IN (?, ?, ?)',
        [technicianEmail.toLowerCase(), todayStr, 'completed', 'could_not_complete', 'cancelled'],
      );
      final activeTodayCount = Sqflite.firstIntValue(activeTodayResult) ?? 0;

      if (activeTodayCount < 5) {
        final needed = 5 - activeTodayCount;
        final candidateFutureJobs = await db.query(
          DbTables.jobs,
          columns: [JobColumns.id],
          where: '${JobColumns.assignedTo} = ? AND ${JobColumns.scheduledDate} > ? AND ${JobColumns.status} = ?',
          whereArgs: [technicianEmail.toLowerCase(), todayStr, 'assigned'],
          limit: needed,
        );

        for (int i = 0; i < candidateFutureJobs.length; i++) {
          final id = candidateFutureJobs[i][JobColumns.id];
          String status = 'assigned';
          if (activeTodayCount == 0 && i == 0) {
            status = 'on_site';
          } else if (activeTodayCount == 0 && i == 1) {
            status = 'travelling';
          }
          await db.update(
            DbTables.jobs,
            {
              JobColumns.scheduledDate: todayStr,
              JobColumns.status: status,
            },
            where: '${JobColumns.id} = ?',
            whereArgs: [id],
          );
        }
      }
    }
  }

  /// Get all jobs for a technician, including their checklists and photos
  Future<List<JobModel>> getJobsForTechnician(String email) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> jobRows = await db.query(
      DbTables.jobs,
      where: '${JobColumns.assignedTo} = ?',
      whereArgs: [email.toLowerCase()],
      orderBy: '${JobColumns.scheduledDate} ASC, ${JobColumns.timeWindow} ASC',
    );

    if (jobRows.isEmpty) return [];

    final jobIds = jobRows.map((r) => r[JobColumns.id] as String).toList();

    // Fetch checklists in batch
    final placeholders = List.filled(jobIds.length, '?').join(',');
    final List<Map<String, dynamic>> chkRows = await db.rawQuery(
      'SELECT * FROM ${DbTables.checklists} WHERE ${ChecklistColumns.jobId} IN ($placeholders) ORDER BY ${ChecklistColumns.sortOrder} ASC',
      jobIds,
    );

    // Fetch photos in batch
    final List<Map<String, dynamic>> photoRows = await db.rawQuery(
      'SELECT * FROM ${DbTables.photos} WHERE ${PhotoColumns.jobId} IN ($placeholders) ORDER BY ${PhotoColumns.createdAt} ASC',
      jobIds,
    );

    final Map<String, List<ChecklistItemModel>> checklistsByJob = {};
    for (final row in chkRows) {
      final item = ChecklistItemModel.fromMap(row);
      checklistsByJob.putIfAbsent(item.jobId, () => []).add(item);
    }

    final Map<String, List<JobPhotoModel>> photosByJob = {};
    for (final row in photoRows) {
      final photo = JobPhotoModel.fromMap(row);
      photosByJob.putIfAbsent(photo.jobId, () => []).add(photo);
    }

    return jobRows.map((r) {
      final id = r[JobColumns.id] as String;
      return JobModel.fromMap(
        r,
        checklists: checklistsByJob[id] ?? [],
        photos: photosByJob[id] ?? [],
      );
    }).toList();
  }

  /// Get a single job by its ID
  Future<JobModel?> getJobById(String id) async {
    final db = await _dbManager.database;
    final List<Map<String, dynamic>> rows = await db.query(
      DbTables.jobs,
      where: '${JobColumns.id} = ?',
      whereArgs: [id],
    );

    if (rows.isEmpty) return null;

    final chkRows = await db.query(
      DbTables.checklists,
      where: '${ChecklistColumns.jobId} = ?',
      whereArgs: [id],
      orderBy: '${ChecklistColumns.sortOrder} ASC',
    );

    final photoRows = await db.query(
      DbTables.photos,
      where: '${PhotoColumns.jobId} = ?',
      whereArgs: [id],
      orderBy: '${PhotoColumns.createdAt} ASC',
    );

    return JobModel.fromMap(
      rows.first,
      checklists: chkRows.map((c) => ChecklistItemModel.fromMap(c)).toList(),
      photos: photoRows.map((p) => JobPhotoModel.fromMap(p)).toList(),
    );
  }

  /// Work a job: Update status (Travelling -> On Site -> Completed / Couldn't complete)
  /// Durable: updates local job and immediately inserts sync queue item
  Future<void> updateJobStatus(
    String jobId,
    String newStatus, {
    String? reason,
  }) async {
    final db = await _dbManager.database;
    final job = await getJobById(jobId);
    if (job == null) return;

    if (job.isUpcoming) {
      throw Exception('Upcoming jobs cannot be started before their scheduled date.');
    }

    final nowStr = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.update(
        DbTables.jobs,
        {
          JobColumns.status: newStatus,
          JobColumns.cannotCompleteReason: reason,
          JobColumns.syncStatus: 'pending',
          JobColumns.updatedAt: nowStr,
        },
        where: '${JobColumns.id} = ?',
        whereArgs: [jobId],
      );

      final queueItem = SyncQueueItem(
        id: _uuid.v4(),
        jobId: jobId,
        actionType: (newStatus == 'could_not_complete') ? 'cannot_complete' : 'update_status',
        payload: {
          'status': newStatus,
          'cannot_complete_reason': reason,
          'timestamp': nowStr,
        },
        baseVersion: job.version,
        createdAt: nowStr,
      );

      await txn.insert(DbTables.syncQueue, queueItem.toMap());
    });
  }

  /// Toggle checklist item
  Future<void> toggleChecklistItem(
    String itemId,
    String jobId,
    bool isCompleted,
  ) async {
    final db = await _dbManager.database;
    final job = await getJobById(jobId);
    if (job == null) return;

    if (job.isUpcoming) {
      throw Exception('Upcoming jobs cannot be started before their scheduled date.');
    }

    final nowStr = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.update(
        DbTables.checklists,
        {ChecklistColumns.isCompleted: isCompleted ? 1 : 0},
        where: '${ChecklistColumns.id} = ?',
        whereArgs: [itemId],
      );

      await txn.update(
        DbTables.jobs,
        {
          JobColumns.syncStatus: 'pending',
          JobColumns.updatedAt: nowStr,
        },
        where: '${JobColumns.id} = ?',
        whereArgs: [jobId],
      );

      final queueItem = SyncQueueItem(
        id: _uuid.v4(),
        jobId: jobId,
        actionType: 'update_checklist',
        payload: {
          'checklist_id': itemId,
          'is_completed': isCompleted,
          'timestamp': nowStr,
        },
        baseVersion: job.version,
        createdAt: nowStr,
      );

      await txn.insert(DbTables.syncQueue, queueItem.toMap());
    });
  }

  /// Save technician notes
  Future<void> saveNotes(String jobId, String notes) async {
    final db = await _dbManager.database;
    final job = await getJobById(jobId);
    if (job == null) return;

    if (job.isUpcoming) {
      throw Exception('Upcoming jobs cannot be started before their scheduled date.');
    }

    final nowStr = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.update(
        DbTables.jobs,
        {
          JobColumns.technicianNotes: notes,
          JobColumns.syncStatus: 'pending',
          JobColumns.updatedAt: nowStr,
        },
        where: '${JobColumns.id} = ?',
        whereArgs: [jobId],
      );

      final queueItem = SyncQueueItem(
        id: _uuid.v4(),
        jobId: jobId,
        actionType: 'save_notes',
        payload: {
          'technician_notes': notes,
          'timestamp': nowStr,
        },
        baseVersion: job.version,
        createdAt: nowStr,
      );

      await txn.insert(DbTables.syncQueue, queueItem.toMap());
    });
  }

  /// Attach a photo (up to 3 photos limit)
  Future<bool> attachPhoto(String jobId, String localPath) async {
    final db = await _dbManager.database;
    final job = await getJobById(jobId);
    if (job == null) return false;

    if (job.isUpcoming) {
      return false; // Future jobs are read-only
    }

    if (job.photos.length >= 3) {
      return false; // Limit reached
    }

    final nowStr = DateTime.now().toIso8601String();
    final photoId = _uuid.v4();

    await db.transaction((txn) async {
      final photo = JobPhotoModel(
        id: photoId,
        jobId: jobId,
        localPath: localPath,
        createdAt: nowStr,
      );

      await txn.insert(DbTables.photos, photo.toMap());

      await txn.update(
        DbTables.jobs,
        {
          JobColumns.syncStatus: 'pending',
          JobColumns.updatedAt: nowStr,
        },
        where: '${JobColumns.id} = ?',
        whereArgs: [jobId],
      );

      final queueItem = SyncQueueItem(
        id: _uuid.v4(),
        jobId: jobId,
        actionType: 'attach_photo',
        payload: {
          'photo_id': photoId,
          'local_path': localPath,
          'timestamp': nowStr,
        },
        baseVersion: job.version,
        createdAt: nowStr,
      );

      await txn.insert(DbTables.syncQueue, queueItem.toMap());
    });

    return true;
  }

  /// Delete photo
  Future<void> deletePhoto(String photoId, String jobId) async {
    final db = await _dbManager.database;
    await db.delete(
      DbTables.photos,
      where: '${PhotoColumns.id} = ?',
      whereArgs: [photoId],
    );
  }

  /// Updates a job from remote server sync
  Future<void> upsertRemoteJob(JobModel remoteJob) async {
    final db = await _dbManager.database;
    await db.transaction((txn) async {
      await txn.insert(
        DbTables.jobs,
        remoteJob.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final chk in remoteJob.checklists) {
        await txn.insert(
          DbTables.checklists,
          chk.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
