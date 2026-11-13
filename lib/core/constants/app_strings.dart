/// Centralized application strings for FieldJobs.
class AppStrings {
  AppStrings._();

  // App Title
  static const String appName = 'FieldJobs';
  static const String appTagline = 'Field Technician Operations';

  // Auth Strings
  static const String loginTitle = 'Technician Sign In';
  static const String loginSubtitle = 'Sign in with your technician account to access your assigned jobs.';
  static const String emailLabel = 'Technician Email';
  static const String passwordLabel = 'Password';
  static const String loginButton = 'Sign In';
  static const String loggingIn = 'Signing in...';
  static const String demoAccountsNotice = 'Demo Accounts:';
  static const String demoAccount1 = 'alex@fieldjobs.com';
  static const String demoAccount2 = 'sarah@fieldjobs.com';
  static const String demoPasswordNotice = 'Password: password123 (or tap to autofill)';
  static const String signOut = 'Sign Out';
  static const String signOutConfirmTitle = 'Sign Out?';
  static const String signOutConfirmMsg = 'Signing out will securely clear all local cached job data to protect customer privacy.';
  static const String unsyncedWarningTitle = 'Unsynced Changes Pending!';
  static const String unsyncedWarningMsg = 'You have offline changes that have not synced with the office server yet. If you sign out now, these changes may be lost. Do you still wish to sign out?';
  static const String cancel = 'Cancel';
  static const String proceedSignOut = 'Sign Out Anyway';
  static const String syncAndSignOut = 'Sync Now & Sign Out';

  // Navigation & Tabs
  static const String myJobs = 'My Jobs';
  static const String todayTab = 'Today';
  static const String upcomingTab = 'Upcoming';
  static const String historyTab = 'History';
  static const String jobDetails = 'Job Details';
  static const String overdueBadge = 'OVERDUE';

  // Status Labels
  static const String statusAssigned = 'Assigned';
  static const String statusTravelling = 'Travelling';
  static const String statusOnSite = 'On Site';
  static const String statusCompleted = 'Completed';
  static const String statusCouldNotComplete = "Couldn't Complete";
  static const String statusCancelled = 'Cancelled by Office';

  // Workflow Actions
  static const String startTravelling = 'Start Travelling';
  static const String arriveOnSite = 'Arrive On Site';
  static const String completeJob = 'Complete Job';
  static const String markCannotComplete = "Couldn't Complete";
  static const String cannotCompleteReasonTitle = "Reason Job Couldn't Be Completed";
  static const String cannotCompleteHint = 'e.g. Customer not home, parts unavailable, safety hazard...';
  static const String submitReason = 'Confirm Status';

  // Job Details Sections
  static const String customerInfo = 'Customer Information';
  static const String address = 'Address';
  static const String timeWindow = 'Time Window';
  static const String appliance = 'Appliance';
  static const String problemDescription = 'Problem Description';
  static const String checklistTitle = 'Job Checklist';
  static const String checklistSubtitle = 'Items must be ticked before completing the job';
  static const String notesTitle = 'Technician Notes';
  static const String notesHint = 'Add any notes, parts used, or observations here...';
  static const String saveNotes = 'Save Notes';
  static const String photosTitle = 'Job Photos (Up to 3)';
  static const String addPhoto = 'Add Photo';
  static const String takePhoto = 'Take Photo with Camera';
  static const String chooseFromGallery = 'Choose from Gallery';
  static const String photoLimitReached = 'Maximum of 3 photos reached.';

  // Offline & Sync
  static const String offlineMode = 'Offline Mode - Changes saved locally';
  static const String onlineMode = 'Online - Connected to Office Server';
  static const String syncNow = 'Sync Now';
  static const String syncing = 'Syncing...';
  static const String allSynced = 'All changes synced';
  static const String unsyncedChanges = 'unsynced changes';
  static const String syncConflictNotice = 'Office Conflict Detected';
  static const String conflictResolvedMsg = 'Office updated this job while you were offline. Field changes preserved.';

  // Empty states & Errors
  static const String noJobsToday = 'No pending jobs for today.';
  static const String noUpcomingJobs = 'No upcoming jobs scheduled.';
  static const String noHistoryJobs = 'No completed job history found.';
  static const String pullToRefresh = 'Pull down to refresh jobs';
  static const String genericError = 'Something went wrong. Please try again.';
  static const String openMap = 'Navigate in Maps';
}
