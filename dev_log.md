# ObjectTrack Mobile — dev_log
Updated: 2026-07-22

## Status
- Repo: `git@github.com:jjcc/objtrack_mobil.git`, branch `main`
- Latest commit: `b64fdb0`
- Flutter analyze: 0 errors / 0 warnings / 1 info (pre-existing)

## Fixed
1. **Invalid Supabase key**: `lib/core/supabase.dart` had a publishable key that did not match the web `.env.local`. Sync before running.
2. **PGRST200 FK alias error**: `transfer_requests` / `events` tables in Supabase have no foreign key constraints, so PostgREST rejects `user_profiles!..._fkey(...)` Jackson expansions.
   - Fix: split into two queries — fetch the main rows first, then resolve `to_user_id / from_user_id / e_from / e_to` against `user_profiles` in separate lookups.
   - Files affected:
     - `my_requests_screen.dart`
     - `approvals_screen.dart`
     - `transfer_repository.dart`
     - `scan_result_screen.dart`
     - `object_repository.dart`
3. **Windows Edge launch failure**: `flutter run -d edge` fails due to browser launch args conflicts. Use `flutter run -d web-server` instead.

## Current blockers
- None. Codebase is clean; clone and run on Windows.

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
