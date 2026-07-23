# ObjectTrack Mobile — dev_log
Updated: 2026-07-23

## Status
- Repo: `git@github.com:jjcc/objtrack_mobil.git`, branch `main`
- Reviewed baseline commit: `db2dd80`
- Flutter 3.35.7 / Dart 3.9.2
- Flutter analyze: no issues
- Flutter tests: all passed

## Fixed
1. **Invalid Supabase key**: `lib/core/supabase.dart` had a publishable key that did not match the web `.env.local`. Sync before running.
2. **PGRST200 transfer-profile relationship error**:
   - `events.e_from/e_to` have foreign keys to `user_profiles.id`.
   - `transfer_requests.from_user_id/to_user_id` have foreign keys to `auth.users.id`, so they cannot be embedded directly as `user_profiles`.
   - Fix: same-group profile directory/name RPCs return only `id`, `first_name`, and `last_name`; Flutter resolves all required names in one batched call.
3. **Transfer workflow blockers**:
   - Changed Flutter user IDs from `int` to UUID `String`.
   - Added sender/recipient RLS read access for their own transfer requests.
   - Removed the ordinary-user direct insert policy so creation cannot bypass RPC validation.
   - Added `request_transfer` RPC, deriving group membership from `user_profiles`.
   - Added atomic `approve_transfer` RPC with recipient authorization, row locking, owner update, status update, and audit event insertion.
   - Changed owner lookup to use `objects.current_owner_id`.
   - Added approval loading and error handling.
   - Reproducible SQL: `supabase/transfer_workflow.sql`.
   - Verification SQL: `supabase/verify_transfer_workflow.sql`.
4. **Windows Edge launch failure**: `flutter run -d edge` fails due to browser launch args conflicts. Use `flutter run -d web-server` instead.

## Verification
- Live database workflow passed with two temporary authenticated users:
  - Same-group directory returned both users.
  - Sender created and read the transfer request.
  - Direct transfer insertion was rejected by RLS.
  - Sender could not approve their own outgoing request.
  - Recipient read and approved the pending request.
  - Object ownership and request status changed atomically.
  - One matching transfer audit event was inserted.
  - Temporary test data was removed.

## Current blockers
- Full request/approve UI verification on a physical device still remains.

## Next steps
```powershell
git clone git@github.com:jjcc/objtrack_mobil.git
cd objtrack_mobil
flutter pub get
flutter run -d web-server
```

## Stack
- Flutter 3.x (Windows Dart 3.7.2, Linux 3.44.7)
- supabase_flutter + go_router + flutter_riverpod
- Shared Supabase backend: `hdpfxqqvrpmelcregemq`
