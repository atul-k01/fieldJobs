# FieldJobs - Offline-First Mobile Technician Operations App

FieldJobs is a production-grade, offline-first mobile application built with **Flutter**, designed specifically for field service technicians repairing home appliances in environments with zero or intermittent network connectivity (basements, elevator shafts, industrial complexes, rural areas).

It couples a **durable local SQLite database** (Outbox Pattern) with a **live Supabase PostgreSQL backend**, guaranteeing instant UI responsiveness, zero data loss, strict technician data isolation, and automated conflict reconciliation.

---

## 🌟 Key Features

- **Offline-First Architecture (Outbox Pattern):** Every action (status change, checklist tick, notes, photos) writes instantly to local SQLite. Mutations are queued in a durable `sync_queue` table and automatically dispatched to Supabase upon network reconnection.
- **Live Supabase Cloud Backend:** Fully connected to a PostgreSQL database hosted on Supabase, featuring tables for `technicians`, `jobs`, and `job_checklists` with Row-Level Security (RLS).
- **Strict Technician Data Isolation (Tricity Realignment):**
  - **Atul Kumar** (`atul@fieldjobs.com`): Assigned 50 jobs across **Chandigarh & Mohali** (`job-atul-0001` to `job-atul-0050`).
  - **Nitin Sharma** (`nitin@fieldjobs.com`): Assigned 50 jobs across **Panchkula & Mohali Aerocity/JLPL** (`job-nitin-0001` to `job-nitin-0050`).
  - Technicians only ever see their own assigned jobs. Initial job history starts **100% empty/clean** until jobs are completed on-site.
- **Smart Tab Categorization:**
  - **Today Tab:** Clear visual separation between **Overdue Priority Jobs** (missed past jobs highlighted in red) and **Today's Active Jobs**.
  - **Upcoming Tab:** Future-scheduled jobs (tomorrow onwards).
  - **History Tab:** Completed or Couldn't Complete jobs with search, date filters, and audit summaries.
- **Live Sync Indicators:**
  - Green **Synced (☁️✓)** badge visible on job cards and detail screens once data is verified on the server.
  - Yellow **Not Synced** badge when changes are queued locally.
  - Red **Office Conflict** badge when the office made changes while the technician was offline.
- **One-Tap Customer Contact & Map Launcher:**
  - Tapping customer phone number launches the native dial pad (`tel:+91...`).
  - Tapping address launches Google Maps on Android; prompts user between **Apple Maps** and **Google Maps** on iOS.
- **Redesigned Dialogs & 100% Centralized Strings:**
  - **SignOutDialog:** Reusable confirmation modal with prominent warning when pending sync items exist, and clean side-by-side [Cancel] and [Sign Out] buttons.
  - **CannotCompleteDialog:** Intuitive icon-based radio card choices for reasons (Customer Not Home, Missing Spare Parts, Appliance Inaccessible, Electrical Issue, Customer Rescheduled).
  - **Zero Hardcoded Strings:** Centralized in `AppStrings` (`lib/core/constants/app_strings.dart`).
  - **Standardized Feedback:** All SnackBar notifications use `AppSnackBar` (`lib/core/utils/app_snackbar.dart`).

---

## 🏗️ Architecture & State Management

```
lib/
├── core/
│   ├── constants/       # AppColors, AppDimens, AppStrings, AppTextStyles
│   ├── data/            # BaseRepository with safeCall error handling
│   ├── database/        # AppDatabase (SQLite), schema, and tables
│   ├── navigation/      # AppNavigator & route keys
│   ├── network/         # SupabaseConfig & ConnectivityService
│   ├── theme/           # Material 3 light theme definition
│   ├── utils/           # AppLog, AppSnackBar, DateFormatter, ExternalLauncher
│   └── widgets/         # CustomButton, CustomTextField, OfflineBanner, SignOutDialog, SyncBadge
└── features/
    ├── auth/            # AuthRepository, LoginScreen, AuthProvider, TechnicianModel
    ├── jobs/            # JobModel, ChecklistItemModel, JobPhotoModel,
    │                    # JobLocalDataSource, JobRemoteDataSource, JobRepository,
    │                    # JobsProvider, JobsListScreen, JobDetailScreen, Widgets
    └── sync/            # SyncEngine, ConflictResolver, SyncQueueItem, SyncProvider
```

### Why Feature-First Architecture + Outbox Pattern?
1. **Local Single Source of Truth:** The UI reads strictly from the local SQLite database. It never blocks on slow network round-trips or spinner freezes.
2. **Durable Outbox Queue:** When a technician changes job status or writes notes offline, the change is written to `jobs` and an intent record is inserted into `sync_queue` inside a single atomic SQLite transaction. Even if the phone battery dies or the OS kills the process, the mutation is safely preserved on disk.
3. **Riverpod State Management:** Decouples UI from business logic with compile-time dependency injection and reactive streams (`syncStatusProvider`, `isOnlineProvider`, `jobsProvider`).

---

## ⚡ Supabase Backend Setup & Integration

The app connects to a live PostgreSQL backend on Supabase.

### 1. Database Schema Overview
The database comprises three tables with foreign key cascades and Row-Level Security (RLS) enabled:
- `public.technicians`: Stores technician IDs, emails, and full names.
- `public.jobs`: Stores job records, assigned technician email, status (`assigned`, `travelling`, `on_site`, `completed`, `could_not_complete`, `cancelled`), version, and schedule.
- `public.job_checklists`: Stores four standardized inspection checklist items per job with toggle state.

### 2. Setting Up in Supabase (Step-by-Step)
1. Log into your dashboard at [supabase.com](https://supabase.com) and create a project (e.g. `FieldJobs`).
2. Open the **SQL Editor** tab from the left sidebar.
3. Click **New Query**, copy the entire contents of [supabase_schema.sql](supabase_schema.sql), and click **Run**.
4. The script automatically:
   - Creates tables `technicians`, `jobs`, and `job_checklists` with appropriate indexes.
   - Enables Row Level Security (RLS) and grants public read-write policies for demo operations.
   - Seeds **Atul Kumar** (`atul@fieldjobs.com`) and **Nitin Sharma** (`nitin@fieldjobs.com`).
   - Seeds **50 isolated jobs each** (2 Overdue, 5 Today, 43 Upcoming) with authentic Tricity addresses and Indian appliances.
   - Leaves history clean and empty for both users.
5. In your Supabase Dashboard, go to **Project Settings ➔ API Keys** (or click the green **Connect** button at the top) to obtain:
   - **Project URL:** `https://atadzziyjoadkwotlvms.supabase.co`
   - **Publishable / Anon Key:** `sb_publishable_...`

### 3. Supabase Credentials in App
The credentials are pre-configured in `lib/core/network/supabase_config.dart`:
```dart
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://atadzziyjoadkwotlvms.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_O3qnTEJSOKKvGOB08-7cxg_8dvvlCyE',
  );
  ...
}
```
You can also override credentials via CLI parameters:
```bash
flutter run --dart-define=SUPABASE_URL=https://your-ref.supabase.co --dart-define=SUPABASE_ANON_KEY=your-key
```

---

## 👥 Demo Accounts & Interview Evaluation Scenarios

### Demo Credentials
On the Login Screen, tap the quick selector chips to autofill:
- **Technician 1:** `atul@fieldjobs.com` | Password: `password123` *(Chandigarh & Mohali)*
- **Technician 2:** `nitin@fieldjobs.com` | Password: `password123` *(Panchkula & Aerocity)*

---

### Live Evaluation Demo Scenarios

During live evaluation, simulate dispatch operations in the Supabase SQL Editor while the technician operates on the mobile app:

#### Scenario 1: Offline Field Work & Two-Way Sync
1. Turn on **Airplane Mode** on the device/simulator.
2. The blue/slate banner appears: `"Offline Mode • Working with local storage"`.
3. Open any Today job. Tap **Start Travel** ➔ **I Have Arrived** ➔ Complete checklists ➔ Save notes.
4. The banner updates: `"Offline Mode • 3 changes queued"`.
5. Turn off Airplane Mode (reconnect to WiFi/cellular).
6. Tap the **Sync Now** button on the banner (or the **🔄 Sync** icon in the top AppBar).
7. A blue SnackBar indicates *"Syncing..."*, changes flush to Supabase, and a green SnackBar confirms: *"All changes synchronized successfully!"*.
8. The job card and detail screen immediately display the green **Synced (☁️✓)** badge.

#### Scenario 2: Office Cancels Job while Technician Works Offline (Zero Data Loss)
1. Put mobile device into **Airplane Mode**.
2. Technician completes checklist items, writes diagnostic notes, and marks job completed.
3. In the Supabase SQL Editor, run:
```sql
UPDATE public.jobs 
SET status = 'cancelled', version = version + 1, updated_at = now() 
WHERE id = 'job-atul-0001';
```
4. Reconnect network on mobile and tap **Sync Now**.
5. **Outcome:** Field work is **never discarded**. The status changes to `cancelled`, but the technician's notes, checklists, and arrival timestamps are merged into the audit log: `[OFFICE CANCELLED WHILE TECH WORKED OFFLINE]: ...`. A red **Office Conflict** badge appears with an explanation.

#### Scenario 3: Office Edits Problem Description & Schedule (Field-Level Merge)
1. While technician is working offline on `job-atul-0002`:
2. In Supabase SQL Editor, simulate office schedule revision:
```sql
UPDATE public.jobs 
SET problem_description = 'URGENT: Unit sparking and tripping MCB. Rescheduled to 03:00 PM.',
    time_window = '03:00 - 05:00 PM',
    version = version + 1, 
    updated_at = now() 
WHERE id = 'job-atul-0002';
```
3. Reconnect network and sync.
4. **Outcome:** **Field-Level Merge.** The office's updated description and time window are adopted, while the technician's completed status, notes, and photos remain fully intact.

#### Scenario 4: Safe Sign-Out with Unsynced Data Protection
1. Turn on Airplane Mode and make local edits.
2. Tap the **Logout** icon in the AppBar.
3. The custom `SignOutDialog` appears displaying:
   - Warning icon and header: *"Unsynced Changes Warning"*.
   - Exact count of pending items: *"You have X unsynced changes..."*.
   - Side-by-side action buttons: **[Cancel]** (left) and **[Sign Out Anyway]** (right).
4. If cancelled, data remains safe. If confirmed, local SQLite is safely wiped to ensure privacy between technicians.

---

## 📱 Hardware & OS Permissions

- **Android (`android/app/src/main/AndroidManifest.xml`):**
  - `INTERNET` and `ACCESS_NETWORK_STATE` permissions enabled.
  - `android:usesCleartextTraffic="true"` configured.
  - Intent `<queries>` configured for `tel` (phone dialer), `geo` (maps), `https`, and `http`.
- **iOS (`ios/Runner/Info.plist`):**
  - `NSAppTransportSecurity` with `NSAllowsArbitraryLoads: true`.
  - `LSApplicationQueriesSchemes` configured for `tel`, `maps`, `comgooglemaps`, `https`, and `http`.
  - `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` configured for appliance repair photo attachments.

---

## 🧪 Verification & Testing

### Running Unit & Durability Tests
The test suite validates data serialization durability, conflict resolution rules, and widget bootstrapping:
```bash
flutter test
```
**Test Results:**
- `test/sync_conflict_test.dart`: Validates Office Cancellation preservation, Reassignment audit trails, and Field-Level Merge rules.
- `test/models_serialization_test.dart`: Validates JSON and SQLite round-trip fidelity for jobs, checklists, photos, and sync queue items.
- `test/widget_test.dart`: Validates dependency injection and app launch inside `ProviderScope`.
- **Outcome:** **11 / 11 tests passing!**

### Static Analysis
```bash
flutter analyze
```
- **Outcome:** **0 issues found!** (Clean, linted code according to flutter_lints).

---

## 🚀 Running the Project

```bash
# 1. Clone repository
git clone https://github.com/atul-k01/fieldJobs.git
cd fieldJobs

# 2. Get dependencies
flutter pub get

# 3. Analyze codebase
flutter analyze

# 4. Run test suite
flutter test

# 5. Run application
flutter run
```
