# FieldJobs - Implementation Plan (PLAN.md)

**Time Committed:** 0h 15m (Within first 30 minutes)  
**Author:** FieldJobs Engineering  
**Project:** Offline-First Mobile App for Field Technicians  

---

## 1. What We Will Build & In What Order

### Phase 1: Core Foundation & Design System (Hours 0.0 - 0.75)
- Project directory setup following Feature-First Clean Architecture.
- Design System: Sky Blue (`#0288D1` / `#0EA5E9`) and Crisp White (`#FFFFFF`, `#F8FAFC`) theme.
- Centralized constants: `AppColors`, `AppStrings`, `AppTextStyles`, `AppDimens`.
- Local Database initialization using SQLite (`sqflite`) for rock-solid relational offline caching and durable sync queues.

### Phase 2: Domain Models & Durable Local Database (Hours 0.75 - 1.5)
- Domain entities: `Technician`, `Job`, `ChecklistItem`, `JobPhoto`, `SyncQueueItem`.
- SQLite schema with transactions:
  - `jobs` (includes `version`, `sync_status`, `assigned_to`, timestamps, address, customer info)
  - `checklists` (linked to `job_id`)
  - `photos` (local file path + remote URL if synced)
  - `sync_queue` (durable outbox pattern for offline mutations: `action_type`, `payload`, `retry_count`, `created_at`)

### Phase 3: Authentication & Multi-User Isolation (Hours 1.5 - 2.0)
- Sign-in flow for technicians (Demo accounts: `alex@fieldjobs.com`, `sarah@fieldjobs.com`).
- Secure token/session storage.
- Sign-out safety guard:
  - Check for unsynced queue items.
  - Warn technician if pending offline changes exist before signing out.
  - Complete cache & database wipe on confirmed sign-out to guarantee zero data leakage between technicians.

### Phase 4: "My Jobs" List (Hours 2.0 - 2.5)
- Segmented view: **Today's Jobs** (priority order) and **Upcoming Jobs** (next 14 days).
- Job Cards displaying: Customer name, appliance type, address, time window, problem description, status badge, and **Unsynced Changes indicator**.
- Pull-to-refresh & connectivity banner ("Offline Mode - Changes will sync automatically").

### Phase 5: "Work a Job" Execution Flow (Hours 2.5 - 3.25)
- Status state machine: `Assigned` → `Travelling` → `On site` → `Completed`.
- Alternative flow: `Couldn't complete` with mandatory reason dialog/form.
- Interactive server-provided checklist (checkboxes with instant local persistence).
- Technician notes (auto-saved).
- Photo attachments (up to 3 photos with camera/gallery picker and thumbnail previews).
- Every action updates local SQLite immediately (Optimistic UI) and enqueues a mutation in `sync_queue`.

### Phase 6: Sync Engine & Conflict Resolution (Hours 3.25 - 4.0)
- Durable queue worker triggered on network reconnect (`connectivity_plus`) and manual trigger.
- Conflict rules (Optimistic Concurrency Control with integer `version`):
  1. **Office Cancellation Rule:** If the office marked the job as `Cancelled` or reassigned it, the technician's completed status yields to cancellation, but technician notes/photos are preserved and logged as an audit trail.
  2. **Office Reschedule / Details Edit Rule:** Technician's on-site status and checklist work take precedence for field execution, while office updates to customer notes merge without overwriting field logs.
  3. **Version Increment:** Every successful sync increments the job's server version.

### Phase 7: Supabase Backend Schema & Seed Script (Hours 4.0 - 4.25)
- Ready-to-run Supabase PostgreSQL schema with RLS policies.
- Seed script with 200 realistic jobs distributed over 2 weeks across 2 technicians.
- Office change simulation scripts/queries for demo (reschedule, cancel, update description).

### Phase 8: Verification, Tests & Deliverable Docs (Hours 4.25 - 4.5)
- Unit & integration tests for Sync Queue and Conflict Resolution.
- Complete `README.md`, `AI_USAGE.md`, and `RELEASE.md`.

---

## 2. Architecture in a Few Lines

We employ a **Feature-First Architecture with an Outbox Pattern**:
- **Presentation Layer:** Flutter widgets with Riverpod for predictable, unidirectional reactive state.
- **Repository / Domain Layer:** Single Source of Truth is the **Local SQLite Database**. The UI never waits on network calls; all user actions write locally first.
- **Sync Engine (Outbox Pattern):** Writes push an immutable mutation entry into the `sync_queue` table. A background Sync Service processes queue items in FIFO order when connectivity is available, reconciling server responses and version conflicts.
- **Remote Data Layer:** Supabase Client interacting with PostgreSQL tables with versioned optimistic locking.

---

## 3. What We Expect to Cut (Scope Trade-offs)

1. **Native GPS Turn-by-Turn Navigation:** We cut embedded interactive map SDKs (Mapbox/Google Maps). Instead, we display clean address cards with a one-tap external Maps launcher intent.
2. **Real-time Push WebSockets:** We cut persistent real-time streaming sockets in favor of robust polling on reconnect + pull-to-refresh + event-driven queue drains. This dramatically simplifies offline state management and avoids socket reconnect storms.
3. **Multi-MB High-Res Raw Photo Uploads:** Photos are compressed locally to lightweight JPEG thumbnails (< 200KB) before queueing to ensure rapid offline storage and fast upload over weak 2G/3G connections.

---

## 4. The Riskiest Part & Mitigation Strategy

**The Riskiest Part:** **Offline Conflicts between Office Dispatches and Field Work.**  
*Risk Scenario:* A technician goes into a basement with zero connectivity, spends 45 minutes fixing a refrigerator, completes the checklist, and attaches 3 photos. Meanwhile, the customer called the office, and the office reassigned or cancelled the job. When the technician comes back online, a naive "server-wins" rule would wipe out the technician's 45 minutes of real labor, while a naive "client-wins" rule would corrupt dispatch scheduling.

**Mitigation Strategy:**
- We implement **Semantic Field-Level Merging with an Audit Trail**:
  - The job record has a numeric `version`.
  - If a status conflict occurs (Office Cancelled vs. Tech Completed), the job status is set to `Office Cancelled / Field Work Recorded`.
  - The technician's checklist, completion timestamp, notes, and photos are **never dropped or deleted**. They are safely attached as completed field attachments.
  - The technician receives an explicit conflict notification banner explaining what happened.
