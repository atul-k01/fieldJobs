import 'package:flutter_test/flutter_test.dart';
import 'package:field_jobs/features/jobs/models/checklist_item_model.dart';
import 'package:field_jobs/features/jobs/models/job_model.dart';
import 'package:field_jobs/features/jobs/models/job_photo_model.dart';
import 'package:field_jobs/features/jobs/providers/jobs_provider.dart';
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

    test('JobModel isOverdue correctly detects past incomplete jobs', () {
      const pastIncompleteJob = JobModel(
        id: 'job-past-1',
        assignedTo: 'alex@fieldjobs.com',
        customerName: 'Old Customer',
        customerPhone: '+44 7700 900111',
        address: '10 Old Road',
        scheduledDate: '2020-01-01',
        timeWindow: '09:00 - 11:00 AM',
        appliance: 'Oven',
        problemDescription: 'Faulty heating element',
        status: 'assigned',
        updatedAt: '2020-01-01T09:00:00Z',
      );
      expect(pastIncompleteJob.isOverdue, true);

      // If it was completed, it is not overdue
      final pastCompletedJob = pastIncompleteJob.copyWith(status: 'completed');
      expect(pastCompletedJob.isOverdue, false);

      // Today's job is not overdue
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      final todayJob = pastIncompleteJob.copyWith(scheduledDate: todayStr);
      expect(todayJob.isOverdue, false);
    });

    test('JobModel isUpcoming correctly detects future scheduled jobs', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowStr = tomorrow.toIso8601String().split('T').first;
      final todayStr = DateTime.now().toIso8601String().split('T').first;

      final upcomingJob = JobModel(
        id: 'job-future',
        assignedTo: 'alex@fieldjobs.com',
        customerName: 'Future Customer',
        customerPhone: '123',
        address: '456 St',
        scheduledDate: tomorrowStr,
        timeWindow: '10:00 - 12:00 PM',
        appliance: 'Dishwasher',
        problemDescription: 'Door latch broken',
        status: 'assigned',
        updatedAt: '2026-11-13T10:00:00Z',
      );
      expect(upcomingJob.isUpcoming, true);

      // Today's job is not upcoming
      final todayJob = upcomingJob.copyWith(scheduledDate: todayStr);
      expect(todayJob.isUpcoming, false);

      // Past job is not upcoming
      final pastJob = upcomingJob.copyWith(scheduledDate: '2020-01-01');
      expect(pastJob.isUpcoming, false);
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

    test('JobsState filters: completed or cancelled jobs move to history and are removed from today', () {
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      final activeToday = JobModel(
        id: 'job-active',
        assignedTo: 'alex@fieldjobs.com',
        customerName: 'Active Customer',
        customerPhone: '123',
        address: '123 St',
        scheduledDate: todayStr,
        timeWindow: '09:00 - 11:00 AM',
        appliance: 'Fridge',
        problemDescription: 'Leaking',
        status: 'on_site',
        updatedAt: '2026-11-13T10:00:00Z',
      );

      final completedToday = activeToday.copyWith(
        id: 'job-done',
        status: 'completed',
      );

      final cancelledToday = activeToday.copyWith(
        id: 'job-cancelled',
        status: 'cancelled',
      );

      final state = JobsState(allJobs: [activeToday, completedToday, cancelledToday]);

      // Today must only contain active jobs
      expect(state.todayJobs.length, 1);
      expect(state.todayJobs.first.id, 'job-active');

      // History must contain completed and cancelled jobs
      expect(state.historyJobs.length, 2);
      expect(state.historyJobs.map((j) => j.id), containsAll(['job-done', 'job-cancelled']));
    });
  });
}
