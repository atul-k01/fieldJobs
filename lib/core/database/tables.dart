/// Database table and column constants for FieldJobs SQLite storage.
class DbTables {
  DbTables._();

  static const String technicians = 'technicians';
  static const String jobs = 'jobs';
  static const String checklists = 'job_checklists';
  static const String photos = 'job_photos';
  static const String syncQueue = 'sync_queue';
}

class JobColumns {
  JobColumns._();

  static const String id = 'id';
  static const String assignedTo = 'assigned_to';
  static const String customerName = 'customer_name';
  static const String customerPhone = 'customer_phone';
  static const String address = 'address';
  static const String scheduledDate = 'scheduled_date';
  static const String timeWindow = 'time_window';
  static const String appliance = 'appliance';
  static const String problemDescription = 'problem_description';
  static const String status = 'status';
  static const String cannotCompleteReason = 'cannot_complete_reason';
  static const String technicianNotes = 'technician_notes';
  static const String version = 'version';
  static const String syncStatus = 'sync_status';
  static const String updatedAt = 'updated_at';
}

class ChecklistColumns {
  ChecklistColumns._();

  static const String id = 'id';
  static const String jobId = 'job_id';
  static const String title = 'title';
  static const String isCompleted = 'is_completed';
  static const String sortOrder = 'sort_order';
}

class PhotoColumns {
  PhotoColumns._();

  static const String id = 'id';
  static const String jobId = 'job_id';
  static const String localPath = 'local_path';
  static const String remoteUrl = 'remote_url';
  static const String createdAt = 'created_at';
}

class SyncQueueColumns {
  SyncQueueColumns._();

  static const String id = 'id';
  static const String jobId = 'job_id';
  static const String actionType = 'action_type';
  static const String payload = 'payload';
  static const String baseVersion = 'base_version';
  static const String createdAt = 'created_at';
  static const String retryCount = 'retry_count';
  static const String status = 'status';
}
