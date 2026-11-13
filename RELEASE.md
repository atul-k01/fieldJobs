# Production Release Strategy (RELEASE.md)

**Project:** FieldJobs  
**Document Version:** 1.0.0 (Production Roadmap)  

---

## 1. Environments & Build Flavours
We define three distinct build flavours using Flutter flavours and Dart defines:
- **`dev` (Development):** Points to local or staging Supabase instance with verbose debug logging, fake GPS simulation, and bypassable auth for rapid UI testing.
- **`staging` (UAT / Dispatch Testing):** Mirrors production database schemas with sanitized demo data; used by dispatch teams and QA on TestFlight / Firebase App Distribution.
- **`prod` (Production):** Stripped debug symbols, strict RLS policies on Supabase, obfuscated Dart code (`--obfuscate --split-debug-info`), pinned SSL certificates, and release API keys via CI/CD secrets.

---

## 2. Continuous Integration & Delivery (CI/CD)
Using GitHub Actions:
1. **Pull Request Quality Gate:**
   - Run `flutter analyze --fatal-infos --fatal-warnings`.
   - Run `flutter test --coverage` (enforcing minimum 85% test coverage on `features/sync` and `core/database`).
2. **Automated Release Pipeline:**
   - Semantic tagging triggers signed builds (`.aab` for Google Play internal track and `.ipa` for Apple TestFlight).
   - Environment credentials injected at compile time via encrypted repository secrets.

---

## 3. Crash Reporting & Observability
- **Crashlytics / Sentry:** Real-time crash capture with custom keys (`technician_id`, `connectivity_status`, `pending_sync_count`).
- **Telemetry on Sync Failures:** Log non-fatal sync errors, SQLite constraint violations, and serialization mismatches to OpenTelemetry / Datadog.
- **Offline Diagnostics:** Local circular ring buffer of the last 100 sync events; technicians can export this log from app settings when reporting issues.

---

## 4. Safe Rollout Strategy for Sync Changes
Changing sync protocol or database schema in an offline-first app poses high risk of client corruption. We mitigate this through:
- **Phased Feature Flags:** Guarding sync engine changes behind server-driven remote config flags (e.g. LaunchDarkly / Firebase Remote Config).
- **Additive Database Migrations Only:** Local SQLite migrations (`onUpgrade`) must be purely additive (adding nullable columns or new tables). Never drop columns used by older app versions.
- **Canary Rollouts:** Roll out new app versions to 5% of technicians for 48 hours, monitoring conflict spikes and deadlocks before widening to 100%.
- **Force Upgrade Mechanism:** For breaking backend protocol revisions, older client versions display a non-dismissible update prompt upon connecting online.

---

## 5. Production Metrics: What to Measure
1. **Queue Drain Latency:** Time elapsed between a technician reconnecting to the network and all queued offline changes reaching `synced` status (target: < 2.5 seconds on 3G).
2. **Conflict Frequency:** Percentage of sync mutations triggering a conflict (target: < 1.5% of total job updates).
3. **Queue Drop / Orphan Rate:** Alerts triggered if any `sync_queue` item exceeds 5 retry attempts or remains uncompleted for > 24 hours.
4. **App Cold Start Time:** Time from app launch to rendering cached jobs from SQLite (target: < 800ms).
5. **Wipe Verification:** Confirmation telemetry that all local database tables were truncated upon sign-out.
