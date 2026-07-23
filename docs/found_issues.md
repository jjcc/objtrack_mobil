# ObjectTrack Mobile — Found Issues

Reviewed: 2026-07-23

Scope:

- `plan.md`
- `dev_log.md`
- Flutter application code
- Live Supabase schema, functions, and RLS policies for project `hdpfxqqvrpmelcregemq`

No application or database changes were made during this review.

## Resolution update — 2026-07-23

Issues 1–9 were addressed in the Flutter code and in
`supabase/transfer_workflow.sql`. The SQL was applied to the connected Supabase
project and verified with the reproducible test in
`supabase/verify_transfer_workflow.sql`.

The database verification covered same-group directory access, request creation,
sender and recipient RLS visibility, rejection of direct inserts that bypass RPC
validation, rejection of approval by the sender, successful approval by the
recipient, atomic owner/status updates, and audit event creation. Temporary
verification data was removed.

Flutter formatting, static analysis, and widget tests passed with Flutter 3.35.7
and Dart 3.9.2. Full request/approve UI verification on a physical device
remains pending.

## Summary

The PGRST200 change in commit `b64fdb0` removed an invalid transfer-request-to-profile embedding, but the request and approval workflow is still not functional. The main blockers are an incorrect UUID-to-`int` cast, a missing `approve_transfer` RPC, missing RLS read policies for transfer requests, and profile policies that prevent users from looking up other participants.

## Critical issues

### 1. Profile UUIDs are cast to `int`

**Location:** `lib/features/transfer/presentation/transfer_request_screen.dart`

- `selectedUserId` is declared as `int?`.
- `DropdownButtonFormField<int>` expects integer values.
- Each returned profile ID is cast with `u['id'] as int`.

The live schema defines the following columns as UUID:

- `user_profiles.id`
- `transfer_requests.from_user_id`
- `transfer_requests.to_user_id`

**Impact:** The transfer-recipient dropdown will throw a runtime type error when it tries to render a profile.

**Recommended direction:** Represent user IDs as `String` throughout the Flutter code and use `DropdownButtonFormField<String>`.

### 2. The `approve_transfer` RPC is missing

**Locations:**

- `plan.md`
- `lib/features/transfer/presentation/approvals_screen.dart`
- `lib/features/transfer/data/transfer_repository.dart`

`plan.md` marks the approval RPC as complete, and the application calls `rpc('approve_transfer')`. Inspection of the connected Supabase database found no `public.approve_transfer` function.

**Impact:** Every approval attempt will fail because the requested database function does not exist.

**Recommended direction:** Add and verify a secure approval function, or correct the application if the intended function has a different name or exists in another environment. The function must verify that the caller is authorized to approve the specified request.

### 3. Ordinary users cannot read transfer requests

**Locations:**

- `lib/features/transfer/presentation/my_requests_screen.dart`
- `lib/features/transfer/presentation/approvals_screen.dart`
- `lib/features/transfer/data/transfer_repository.dart`

The live `transfer_requests` table has:

- An administrator `ALL` policy.
- A user `INSERT` policy.
- No user `SELECT` policy.

**Impact:** An ordinary user cannot retrieve sent requests or pending approvals. RLS may simply return an empty result, causing the UI to misleadingly show that there are no requests.

**Recommended direction:** Add narrowly scoped `SELECT` policies that allow authenticated users to read requests where they are the sender or recipient.

## High-severity issues

### 4. Follow-up profile lookups are blocked by RLS

**Locations:**

- `lib/features/transfer/presentation/transfer_request_screen.dart`
- `lib/features/transfer/presentation/my_requests_screen.dart`
- `lib/features/transfer/presentation/approvals_screen.dart`
- `lib/features/object_details/data/object_repository.dart`

The only ordinary-user `SELECT` policy on `user_profiles` allows a user to read their own profile. The replacement queries attempt to read other users' profiles.

**Impact:**

- The recipient dropdown cannot list other users.
- Request and approval screens cannot resolve the other participant's name.
- Event enrichment cannot resolve other participants.

**Recommended direction:** Define a privacy-aware profile visibility policy, such as allowing users to see limited profile information for members of their group. Avoid exposing sensitive columns unnecessarily.

### 5. The foreign-key explanation in `dev_log.md` is inaccurate

**Location:** `dev_log.md`

The log states that `transfer_requests` and `events` have no foreign-key constraints. The live schema shows:

- `events.e_from` and `events.e_to` reference `user_profiles.id`.
- `transfer_requests.from_user_id` and `to_user_id` reference `auth.users.id`.
- The transfer columns do not directly reference `user_profiles.id`.

**Impact:** The documented root cause is misleading. It can lead to unnecessary query rewrites and obscure the real relationship mismatch.

**Assessment of the logged fix:**

- Removing the transfer-request embedding into `user_profiles` was appropriate because PostgREST has no direct FK relationship for that embedding.
- Removing the event-to-profile embeddings was not necessary under the current schema because the event foreign keys exist.
- The follow-up queries do not fully fix the feature because current profile RLS prevents the required lookups.

**Recommended direction:** Correct `dev_log.md` to distinguish between the valid event relationships and the transfer relationships that point to `auth.users`.

### 6. Transfer insertion relies on user-editable or absent metadata

**Location:** `lib/features/transfer/presentation/transfer_request_screen.dart`

The inserted `group_id` comes from:

```dart
me.userMetadata?['group_id']
```

The database insert policy validates `group_id` against `user_profiles.group_id`. User metadata is not a trustworthy authorization source and may not contain the group ID.

**Impact:** Valid requests can fail RLS validation. Relying on user metadata for authorization-related data is also unsafe.

**Recommended direction:** Obtain group membership from a protected database record or derive it inside a secure database function. Continue enforcing authorization in the database.

## Medium-severity issues

### 7. Current ownership is inferred from the latest event

**Location:** `lib/features/object_details/data/object_repository.dart`

`getCurrentOwner()` reads `e_to` from the newest event. The live `objects` table already has `current_owner_id` with a foreign key to `user_profiles.id`.

**Impact:** If the newest event is not an ownership transfer, or its `e_to` is null, the application can display an incorrect owner.

**Recommended direction:** Treat `objects.current_owner_id` as the authoritative current state and use events as history, assuming that matches the intended data model.

### 8. Profile enrichment uses sequential N+1 queries

**Locations:**

- `lib/features/object_details/data/object_repository.dart`
- `lib/features/transfer/presentation/my_requests_screen.dart`
- `lib/features/transfer/presentation/approvals_screen.dart`

The code performs one profile request for each distinct user ID and waits for each request sequentially.

**Impact:** Screens become slower as the number of participants increases, and failures are more likely because a single screen load requires many network requests.

**Recommended direction:**

- For events, use the valid PostgREST FK embeddings after confirming RLS.
- Where separate profile lookup is necessary, fetch all required IDs in one filtered query.

### 9. Approval failures are not handled

**Location:** `lib/features/transfer/presentation/approvals_screen.dart`

`_approve()` does not use `try/catch`, does not display errors, and does not disable the button while a request is running.

**Impact:** Missing-RPC, authorization, or network failures result in an unhandled asynchronous error. Users receive no actionable feedback and can submit repeatedly.

**Recommended direction:** Track approval state, disable repeat submissions, catch errors, and only show success or navigate after confirmed completion.

## Documentation and verification issues

### 10. `dev_log.md` is stale

- It lists `b64fdb0` as the latest commit, while the reviewed branch is at `db2dd80`.
- It says there are no current blockers, despite the blockers documented above.
- Its foreign-key diagnosis does not match the live schema.

### 11. `plan.md` does not match the implementation or database

- Supabase Flutter integration remains unchecked even though it is present.
- The approval RPC is marked complete but is absent from the connected database.
- The request/approval chain remains unverified.

### 12. The complete workflow is not covered by tests

The repository contains only a basic application-launch widget test. There are no tests for:

- UUID handling.
- Recipient loading and selection.
- Transfer insertion.
- RLS-visible request lists.
- Approval success and failure.
- Profile enrichment.
- Current-owner calculation.

At review time, the live application tables contained no representative groups, profiles, objects, events, or transfer requests. The end-to-end flow therefore could not be validated with existing data.

Follow-up verification on 2026-07-23 completed successfully:

- `dart format lib test`: clean.
- `flutter analyze`: no issues.
- `flutter test`: all tests passed.

## Suggested remediation order

1. Correct all user ID types from `int` to `String`.
2. Decide and document the intended transfer/profile foreign-key model.
3. Add secure, narrowly scoped RLS policies for transfer requests and profile visibility.
4. Implement and test the approval RPC with caller authorization and atomic updates.
5. Stop using user metadata as the source of group authorization.
6. Use `objects.current_owner_id` as the authoritative owner if that is the intended model.
7. Replace sequential profile lookups with valid embeddings or batched queries.
8. Add error handling and in-progress state to approval actions.
9. Add integration tests using at least two users, one group, one object, and one transfer request.
10. Update `plan.md` and `dev_log.md` only after the request/approval flow passes end-to-end verification.
