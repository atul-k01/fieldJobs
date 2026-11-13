# FieldJobs - Mobile Technician Operations App

FieldJobs is an offline-first mobile application built with Flutter, designed for appliance repair technicians operating in low-signal environments (basements, elevators, rural regions). It features durable offline queueing, zero-data-loss conflict resolution, and multi-user data isolation.

---

## 1. Quick Start (Fresh Clone)

### Prerequisites
- **Flutter SDK:** 3.24+ (Dart 3.5+)
- **Target Platforms:** Android Emulator / Physical Device or iOS Simulator

### Run the App
```bash
# 1. Clone the repository
git clone https://github.com/atul-k01/fieldJobs.git
cd fieldJobs

# 2. Install dependencies
flutter pub get

# 3. Run on connected device or emulator
flutter run
```

### Backend (Supabase) Setup
By default, the app runs in **Full Offline Mode** with a durable SQLite local database and at least 200 pre-seeded jobs.

To connect a live Supabase backend:
1. Create a free project at [supabase.com](https://supabase.com).
2. Go to the **SQL Editor** tab in your Supabase dashboard.
3. Open `supabase_schema.sql` from this repository, copy its entire contents, paste it into the SQL Editor, and click **Run**.
4. Run the app with your Supabase credentials:
```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

---

## 2. Demo Accounts & How to Make an "Office" Change

### Demo Accounts
Tap the quick-selector chips on the Sign In screen to autofill:
- **Technician 1:** `alex@fieldjobs.com` | Password: `password123`
- **Technician 2:** `sarah@fieldjobs.com` | Password: `password123`

### Making an "Office" Change During Demo
During a live review demo, simulate office changes in the Supabase SQL Editor (or using the queries below) while the technician is offline (Airplane Mode):

#### Scenario A: Office Cancels a Job
```sql
UPDATE public.jobs 
SET status = 'cancelled', version = version + 1, updated_at = now() 
WHERE id = 'job-0001';
```

#### Scenario B: Office Reschedules or Updates Problem Description
```sql
UPDATE public.jobs 
SET problem_description = 'URGENT: Customer reports unit is sparking and tripping main breaker. Rescheduled to afternoon.',
    time_window = '02:30 - 04:30 PM',
    version = version + 1, 
    updated_at = now() 
WHERE id = 'job-0002';
```

#### Scenario C: Office Reassigns Job to Another Technician
```sql
UPDATE public.jobs 
SET assigned_to = 'sarah@fieldjobs.com', 
    version = version + 1, 
    updated_at = now() 
WHERE id = 'job-0003';
```

---

## 3. Architecture & State Management

### Why Feature-First Architecture + Outbox Pattern?
- **Feature-First Organization:** `auth`, `jobs`, and `sync` each contain their domain models, local/remote data sources, and presentation layers.
- **Local Single Source of Truth:** All user actions (status transitions, checklist items, notes, photos) write synchronously to the local **SQLite (`sqflite`)** database first. The UI never blocks or waits on network round-trips.
- **Durable Outbox Queue (`sync_queue` table):** Mutations are committed in SQLite transactions alongside local state changes. If the device powers off, crashes, or stays in Airplane Mode, pending mutations remain safely persisted on disk.

### Why Riverpod?
- Compile-safe dependency injection without `BuildContext` coupling.
- Reactive streams for network connectivity (`isOnlineProvider`) and sync status (`syncStatusProvider`).
- Predictable and testable state mutation without boilerplate.

---

## 4. Sync & Conflict Rules (Zero Data Loss)

When a technician works offline and comes back online, their mutations push to the server. If `server.version > client.base_version`, a conflict is triggered:

1. **Office Cancellation Rule:**
   - **Resolution:** Status sets to `cancelled`, but the technician's checklist, completion timestamp, notes, and photos are **never discarded**. They are merged into a dispatch audit log: `[OFFICE CANCELLED WHILE TECH WORKED OFFLINE]: <Tech notes>`.
   - **UI:** Marked with a red **Office Conflict** badge and an explanatory banner.

2. **Office Reassignment Rule:**
   - **Resolution:** Job reassignment is recognized, but field work already executed is attached as proof of arrival/labor so dispatch can settle contractor pay.

3. **Office Schedule / Details Edit Rule:**
   - **Resolution:** **Field-Level Merge.** The office's updated address, problem description, and time window are adopted, while the technician's on-site execution state (`completed` / `on_site`), checklists, and photos remain intact.

4. **Multi-User Isolation & Sign-Out:**
   - Sign-out verifies `sync_queue`. If unsynced items exist, a prominent confirmation dialog warns the user.
   - Upon confirmed sign-out, all cached jobs, checklists, photos, and queues are completely wiped from SQLite to prevent customer privacy leaks between technicians.

---

## 5. Scope Cuts & Future Roadmap

### What We Cut & Why
1. **Interactive Embedded Map SDKs (Google Maps/Mapbox):** Replaced with one-tap clipboard copy and native map launcher intent. Native map SDKs add 40MB+ to binary size, require API keys, and fail completely offline.
2. **Real-time WebSockets:** Replaced with event-driven queue drains on network reconnect + manual pull-to-refresh. WebSockets cause reconnect storm thrashing in low-reception basements.
3. **Multi-MB Raw Photo Uploads:** Photos are compressed locally to lightweight JPEG thumbnails (< 200KB) to ensure rapid saving and upload over 2G/EDGE networks.

### What We Would Do With Another Week
- Background sync via WorkManager (Android) and BGAppRefresh (iOS) when the app is backgrounded.
- Binary differential compression for delta syncs.
- End-to-end encryption for offline cached customer addresses and phone numbers.
- Automated parts inventory reconciliation linked to job checklists.

---

## 6. Tests: Why These Matter Most

We focused our test suite on **what can break silently**:

1. **`test/sync_conflict_test.dart`:**
   - **Why:** In offline-first apps, silent data loss during conflict resolution is the highest business risk (e.g. wiping 45 minutes of technician labor because office touched the schedule). These tests verify all 3 conflict rules mathematically preserve field notes.
2. **`test/models_serialization_test.dart`:**
   - **Why:** Corrupted JSON serialization in the SQLite queue can brick the sync worker silently. These tests ensure all domain entities serialize and restore idempotently.
3. **`test/widget_test.dart`:**
   - **Why:** Verifies app root boots cleanly inside `ProviderScope` without missing dependencies.

Run tests via:
```bash
flutter test
```
