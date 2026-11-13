# AI Usage Report (AI_USAGE.md)

**Project:** FieldJobs Mobile App  
**Date:** November 13, 2026  

---

## 1. Tools Used and Their Purpose

- **Antigravity / Gemini 3.8 Flash:**
  - Initial scaffolding of Clean Architecture layers (`core`, `features/auth`, `features/jobs`, `features/sync`).
  - Generating realistic demo datasets (200 jobs spread over 14 days, appliances, error descriptions, and standard repair checklists).
  - Drafting comprehensive SQL schema scripts compatible with Supabase PostgreSQL.
- **Dart Analysis & Testing Tools:**
  - `flutter analyze` for static type checking and deprecation verification.
  - `flutter test` for validating conflict resolution and durability logic.

---

## 2. Specific Example Where AI Was Wrong or a Poor Fit, and How It Was Caught

### The Issue: Naive Last-Write-Wins and Destructive Conflict Handling
During the initial design of the conflict resolution mechanism, the AI suggested a conventional timestamp-based **"Server-Wins"** strategy:
> *"If the server updated_at timestamp is newer than the client's mutation, discard the local change and overwrite the local SQLite record with the incoming server state."*

### Why This Was a Poor Fit:
In field operations for appliance repair, a technician frequently works in zero-signal basements for 45 to 60 minutes. While offline:
- The technician diagnoses the appliance, replaces parts, ticks off safety checklists, writes technical notes, and attaches photos.
- Concurrently, a customer might call dispatch to cancel or request a reschedule because they thought the technician was running late.
- Under a naive "Server-Wins" rule, when the technician returned to cellular range, the app would receive the server's cancellation and **silently wipe out all 45 minutes of the technician's completed labor, notes, and photos**.
- Conversely, a naive "Client-Wins" rule would resurrect a job the customer no longer wanted.

### How It Was Caught and Corrected:
1. **Detection:** During architectural review of the prompt's core requirement (*"A durable queue; no lost or doubled changes... sensible written conflict rules that the code actually follows"*), we identified that discarding local offline work violates the zero-data-loss requirement.
2. **Correction:** We rejected the AI's proposal and implemented **Semantic Field-Level Merging with an Audit Trail**:
   - A numeric optimistic concurrency `version` integer was introduced instead of relying on fragile clock timestamps.
   - If the office cancels a job, the job is marked `cancelled`, but the technician's notes and checklist actions are automatically preserved as a appended audit trail (`[OFFICE CANCELLED WHILE TECH WORKED OFFLINE]: ...`).
   - If the office updates addresses or problem descriptions, field-level merge updates the metadata while keeping the technician's physical execution status intact.
   - Unit tests in `test/sync_conflict_test.dart` were written to enforce that field notes are never dropped under any conflict scenario.
