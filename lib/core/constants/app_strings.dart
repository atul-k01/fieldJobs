/// Centralized application strings for FieldJobs.
/// All user-facing strings are strictly defined here to prevent hardcoding.
class AppStrings {
  AppStrings._();

  // App Metadata
  static const String appName = 'FieldJobs';
  static const String appTagline = 'Field Technician Operations';

  // Auth Strings
  static const String loginTitle = 'Technician Sign In';
  static const String loginSubtitle =
      'Sign in with your technician account to access your assigned jobs.';
  static const String emailLabel = 'Technician Email';
  static const String passwordLabel = 'Password';
  static const String loginButton = 'Sign In';
  static const String loggingIn = 'Signing in...';
  static const String demoAccountsNotice = 'Demo Accounts:';
  static const String demoAccount1 = 'alex@fieldjobs.com';
  static const String demoAccount2 = 'sarah@fieldjobs.com';
  static const String demoPasswordNotice =
      'Password: password123 (or tap to autofill)';
  static const String signOut = 'Sign Out';
  static const String signOutConfirmTitle = 'Sign Out';
  static const String signOutConfirmMsg =
      'Are you sure you want to sign out? Your session on this device will end safely.';
  static const String unsyncedWarningTitle = 'Unsynced Changes Warning';
  static const String unsyncedWarningMsg =
      'Signing out clears local device storage. These changes will be permanently lost unless you reconnect and sync first.';
  static const String cancel = 'Cancel';
  static const String proceedSignOut = 'Sign Out Anyway';
  static const String syncAndSignOut = 'Sync Now & Sign Out';

  // Navigation & Tabs
  static const String myJobs = 'My Jobs';
  static const String todayTab = 'Today';
  static const String upcomingTab = 'Upcoming';
  static const String historyTab = 'History';
  static const String jobDetails = 'Job Details';
  static const String backToJobs = 'Back to Jobs';
  static const String overdueBadge = 'OVERDUE';

  // Status & Connectivity Labels
  static const String statusAssigned = 'Assigned';
  static const String statusTravelling = 'Travelling';
  static const String statusOnSite = 'On Site';
  static const String statusCompleted = 'Completed';
  static const String statusCouldNotComplete = "Couldn't Complete";
  static const String statusCancelled = 'Cancelled by Office';
  static const String online = 'Online';
  static const String offline = 'Offline';

  // Section Headers
  static const String overdueJobsHeader = 'OVERDUE JOBS';
  static const String actionRequired = 'Action Required';
  static const String todayScheduleHeader = "TODAY'S SCHEDULE";
  static const String activeJobs = 'Active Jobs';
  static const String overdueAttentionSingle = '1 Overdue Job Needs Attention';
  static const String overdueAttentionPlural = 'Overdue Jobs Need Attention';
  static const String overdueAttentionDesc =
      'Scheduled prior to today and pending completion. Prioritized at top.';
  static const String overdueHighPriority = 'Overdue Job - High Priority';
  static const String overdueNoticeAction =
      'Action required: complete or update status promptly.';

  // Upcoming Lock Notification
  static const String upcomingJobTitle = 'Upcoming Job';
  static const String upcomingLockedMsg =
      'This job is scheduled for future work. Workflow actions will unlock on scheduled date.';

  // Workflow Actions
  static const String startTravelling = 'Start Travelling';
  static const String arriveOnSite = 'Arrive On Site';
  static const String completeJob = 'Complete Job';
  static const String markCannotComplete = "Couldn't Complete";
  static const String cannotCompleteReasonTitle =
      "Reason Job Couldn't Be Completed";
  static const String cannotCompleteHint =
      'e.g. Customer not home, parts unavailable, safety hazard...';
  static const String submitReason = 'Confirm Status';
  static const String viewSchedule = 'View Schedule';
  static const String workJob = 'Work Job';

  // Customer & Job Details
  static const String customerInfo = 'Customer Information';
  static const String customerName = 'Customer Name';
  static const String contactPhone = 'Contact Phone';
  static const String notProvided = 'Not provided';
  static const String address = 'Address';
  static const String timeWindow = 'Time Window';
  static const String appliance = 'Appliance';
  static const String problemDescription = 'Problem Description';
  static const String scheduledLabel = 'Scheduled:';
  static const String versionPrefix = 'Version';

  // Actions & Buttons
  static const String call = 'Call';
  static const String map = 'Map';
  static const String copyAddress = 'Copy Address';
  static const String addressCopied = 'Address copied to clipboard';

  // Checklist & Notes
  static const String checklistTitle = 'Job Checklist';
  static const String checklistSubtitle =
      'Items must be ticked before completing the job';
  static const String checklistRequiredWarning =
      'Please complete all checklist items before completing the job.';
  static const String notesTitle = 'Technician Notes';
  static const String notesHint =
      'Add any notes, parts used, or observations here...';
  static const String saveNotes = 'Save Notes';
  static const String notesSavedSuccess =
      'Notes saved locally and queued for sync.';
  static const String cannotCompleteReasonRequired =
      'Please provide a reason why this job cannot be completed.';

  // Photos
  static const String photosTitle = 'Job Photos (Up to 3)';
  static const String addPhoto = 'Add Photo';
  static const String takePhoto = 'Take Photo with Camera';
  static const String chooseFromGallery = 'Choose from Gallery';
  static const String photoLimitReached = 'Maximum of 3 photos reached.';
  static const String photoAttachError = 'Failed to attach photo';

  // Map & External Launcher
  static const String openAddressInMaps = 'Open Address in Maps';
  static const String appleMaps = 'Apple Maps';
  static const String appleMapsDesc = 'Default iOS Navigation';
  static const String googleMaps = 'Google Maps';
  static const String googleMapsDesc = 'Google Navigation & Traffic';
  static const String noValidPhoneError = 'No valid phone number provided.';
  static const String dialerLaunchError =
      'Could not launch phone dialer on this device.';
  static const String noAddressError = 'No address available for navigation.';
  static const String appleMapsError = 'Could not open Apple Maps.';
  static const String googleMapsError =
      'Could not open Google Maps on this device.';

  // Offline & Sync
  static const String offlineMode = 'Offline Mode - Changes saved locally';
  static const String onlineMode = 'Online - Connected to Office Server';
  static const String syncNow = 'Sync Now';
  static const String syncing = 'Syncing...';
  static const String allSynced = 'All changes synced';
  static const String unsyncedChanges = 'unsynced changes';
  static const String syncConflictNotice = 'Office Conflict Detected';
  static const String conflictResolvedMsg =
      'Office updated this job while you were offline. Field changes preserved.';

  // Sync Badges
  static const String syncBadgePending = 'Not Synced';
  static const String syncBadgeConflict = 'Office Conflict';
  static const String syncBadgeSynced = 'Synced';

  // Empty States & Errors
  static const String noJobsToday = 'No pending jobs for today.';
  static const String noUpcomingJobs = 'No upcoming jobs scheduled.';
  static const String noHistoryJobs = 'No completed job history found.';
  static const String pullToRefresh = 'Pull down to refresh jobs';
  static const String genericError = 'Something went wrong. Please try again.';
}
