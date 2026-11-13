import 'package:flutter_test/flutter_test.dart';
import 'package:field_jobs/features/jobs/models/checklist_item_model.dart';
import 'package:field_jobs/features/jobs/models/job_model.dart';
import 'package:field_jobs/features/jobs/models/job_photo_model.dart';
import 'package:field_jobs/features/sync/models/sync_queue_item.dart';

void main() {
  group('Model Serialization & Durability Tests', () {
    test('JobModel converts to and from Map without data loss', () {
      const job = JobModel(
        id: 'job-100',
        assignedTo: 'alex@fieldjobs.com',
        customerName: 'Robert Langdon',
        customerPhone: '+44 7700 900456',
        address: 'Harvard Square, Oxford',
        scheduledDate: '2026-11-13',
        timeWindow: '10:00 - 12:00 PM',
        appliance: 'Miele Dishwasher',
        problemDescription: 'Error 78: Circulation pump failure',
        status: 'on_site',
        cannotCompleteReason: null,
        technicianNotes: 'Inspected sensor wiring',
        version: 3,
        syncStatus: 'pending',
        updatedAt: '2026-11-13T10:30:00.000Z',
      );

      final map = job.toMap();
      final restored = JobModel.fromMap(map);

      expect(restored.id, job.id);
      expect(restored.assignedTo, job.assignedTo);
      expect(restored.customerName, job.customerName);
      expect(restored.appliance, job.appliance);
      expect(restored.status, job.status);
      expect(restored.version, job.version);
      expect(restored.syncStatus, job.syncStatus);
      expect(restored.technicianNotes, job.technicianNotes);
    });

    test('ChecklistItemModel toggles and maps properly', () {
      const item = ChecklistItemModel(
        id: 'chk-1',
        jobId: 'job-100',
        title: 'Check ground continuity',
        isCompleted: false,
        sortOrder: 1,
      );

      final toggled = item.copyWith(isCompleted: true);
      expect(toggled.isCompleted, true);

      final map = toggled.toMap();
      expect(map['is_completed'], 1);

      final restored = ChecklistItemModel.fromMap(map);
      expect(restored.isCompleted, true);
    });

    test('JobPhotoModel limits and maps paths properly', () {
      const photo = JobPhotoModel(
        id: 'p-1',
        jobId: 'job-100',
        localPath: '/data/user/0/app/cache/photo_1.jpg',
        createdAt: '2026-11-13T10:35:00Z',
      );

      final map = photo.toMap();
      final restored = JobPhotoModel.fromMap(map);
      expect(restored.localPath, '/data/user/0/app/cache/photo_1.jpg');
    });

    test('SyncQueueItem encapsulates mutation payload for durable offline queue', () {
      const queueItem = SyncQueueItem(
        id: 'q-uuid-1234',
        jobId: 'job-100',
        actionType: 'update_status',
        payload: {
          'status': 'completed',
          'notes': 'All tests passed',
        },
        baseVersion: 2,
        createdAt: '2026-11-13T10:40:00Z',
      );

      final map = queueItem.toMap();
      final restored = SyncQueueItem.fromMap(map);

      expect(restored.id, 'q-uuid-1234');
      expect(restored.actionType, 'update_status');
      expect(restored.payload['status'], 'completed');
      expect(restored.baseVersion, 2);
    });
  });
}
