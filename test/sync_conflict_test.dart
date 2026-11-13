import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:field_jobs/features/jobs/models/job_model.dart';
import 'package:field_jobs/features/sync/services/conflict_resolver.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  group('Conflict Resolution Unit Tests (Zero-Data-Loss Verification)', () {
    late ConflictResolver resolver;

    setUp(() {
      resolver = ConflictResolver(autoPersist: false);
    });

    test('Rule 1: Office Cancellation preserves technician offline notes and photos', () async {
      // Technician worked offline: marked completed with notes
      const localJob = JobModel(
        id: 'job-001',
        assignedTo: 'alex@fieldjobs.com',
        customerName: 'John Doe',
        customerPhone: '+44 7700 900100',
        address: '10 Downing St',
        scheduledDate: '2026-11-13',
        timeWindow: '09:00 - 11:00 AM',
        appliance: 'Bosch Washing Machine',
        problemDescription: 'Leaking pump',
        status: 'completed',
        technicianNotes: 'Replaced main drainage pump seal. Unit fully operational.',
        version: 1,
        syncStatus: 'pending',
        updatedAt: '2026-11-13T10:00:00Z',
      );

      // Office cancelled the job concurrently on the server
      const serverJob = JobModel(
        id: 'job-001',
        assignedTo: 'alex@fieldjobs.com',
        customerName: 'John Doe',
        customerPhone: '+44 7700 900100',
        address: '10 Downing St',
        scheduledDate: '2026-11-13',
        timeWindow: '09:00 - 11:00 AM',
        appliance: 'Bosch Washing Machine',
        problemDescription: 'Leaking pump',
        status: 'cancelled',
        technicianNotes: 'Customer called office requesting cancellation',
        version: 2,
        syncStatus: 'synced',
        updatedAt: '2026-11-13T09:30:00Z',
      );

      // We test the conflict resolution logic
      final result = await resolver.resolveConflict(
        localJob: localJob,
        serverJob: serverJob,
      );

      // Assertions:
      // 1. Status reflects cancellation
      expect(result.resolvedJob.status, 'cancelled');
      // 2. Technician work notes are NOT dropped or wiped
      expect(result.resolvedJob.technicianNotes, contains('Replaced main drainage pump seal'));
      expect(result.resolvedJob.technicianNotes, contains('Customer called office'));
      // 3. Marked with 'conflict' sync status so technician is notified
      expect(result.resolvedJob.syncStatus, 'conflict');
      expect(result.strategy, ConflictResolutionStrategy.serverWinsWithFieldAudit);
    });

    test('Rule 2: Office Reassignment preserves technician work for dispatch audit', () async {
      const localJob = JobModel(
        id: 'job-002',
        assignedTo: 'alex@fieldjobs.com',
        customerName: 'Alice Smith',
        customerPhone: '+44 7700 900200',
        address: '22 Baker St',
        scheduledDate: '2026-11-13',
        timeWindow: '11:00 - 01:00 PM',
        appliance: 'Samsung Refrigerator',
        problemDescription: 'Not cooling',
        status: 'on_site',
        technicianNotes: 'Cleaned compressor coils. Tested fan motor.',
        version: 1,
        syncStatus: 'pending',
        updatedAt: '2026-11-13T11:30:00Z',
      );

      const serverJob = JobModel(
        id: 'job-002',
        assignedTo: 'sarah@fieldjobs.com', // Reassigned to Sarah
        customerName: 'Alice Smith',
        customerPhone: '+44 7700 900200',
        address: '22 Baker St',
        scheduledDate: '2026-11-13',
        timeWindow: '11:00 - 01:00 PM',
        appliance: 'Samsung Refrigerator',
        problemDescription: 'Not cooling',
        status: 'assigned',
        version: 2,
        syncStatus: 'synced',
        updatedAt: '2026-11-13T11:15:00Z',
      );

      final result = await resolver.resolveConflict(
        localJob: localJob,
        serverJob: serverJob,
      );

      // Assertions:
      expect(result.resolvedJob.assignedTo, 'sarah@fieldjobs.com');
      expect(result.resolvedJob.technicianNotes, contains('Cleaned compressor coils'));
      expect(result.resolvedJob.syncStatus, 'conflict');
    });

    test('Rule 3: Office Schedule/Problem Update performs Field-Level Merge', () async {
      const localJob = JobModel(
        id: 'job-003',
        assignedTo: 'alex@fieldjobs.com',
        customerName: 'Charlie Brown',
        customerPhone: '+44 7700 900300',
        address: '5 Oxford Rd',
        scheduledDate: '2026-11-13',
        timeWindow: '01:00 - 03:00 PM',
        appliance: 'LG Dryer',
        problemDescription: 'Squeaking noise',
        status: 'completed',
        version: 1,
        syncStatus: 'pending',
        updatedAt: '2026-11-13T14:00:00Z',
      );

      const serverJob = JobModel(
        id: 'job-003',
        assignedTo: 'alex@fieldjobs.com',
        customerName: 'Charlie Brown',
        customerPhone: '+44 7700 900300',
        address: '5 Oxford Rd, Suite 4B', // Address refined by office
        scheduledDate: '2026-11-13',
        timeWindow: '01:30 - 03:30 PM', // Time adjusted by office
        appliance: 'LG Dryer',
        problemDescription: 'Squeaking noise, customer says burning odor also observed',
        status: 'assigned',
        version: 2,
        syncStatus: 'synced',
        updatedAt: '2026-11-13T13:45:00Z',
      );

      final result = await resolver.resolveConflict(
        localJob: localJob,
        serverJob: serverJob,
      );

      // Assertions:
      // Technician's completed status is preserved!
      expect(result.resolvedJob.status, 'completed');
      // Office updated address and time window are merged!
      expect(result.resolvedJob.address, '5 Oxford Rd, Suite 4B');
      expect(result.resolvedJob.timeWindow, '01:30 - 03:30 PM');
      expect(result.resolvedJob.problemDescription, contains('burning odor also observed'));
      expect(result.strategy, ConflictResolutionStrategy.fieldLevelMerge);
    });
  });
}
