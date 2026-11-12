# SchoolPro instructional calendar — database design

**Status:** Design proposal only. No migration, application code, production data, or schema has been changed.

## Problem and existing behavior

The current academic calendar stores session/term date ranges in `public.schoolpro_result_term_settings`. The attendance trigger chain stamps a session/term and rejects activity dates outside the selected session's overall term boundaries. It does not determine whether an individual date is an instructional day.

`public.schoolpro_calendar_events` is a general-purpose event list with a free-text `event_type`. Event titles and free-text types must not be interpreted as attendance policy. A calendar event named “Holiday” is not authoritative evidence that the school is closed.

## Proposed model

Keep academic term dates and instructional-day policy as separate concepts. Add a session-scoped instructional calendar, with an explicit weekly pattern and explicit date overrides.

### 1. Session calendar configuration

Proposed table: `public.schoolpro_instructional_calendar_settings`

- `id uuid primary key`
- `school_id uuid not null references public.schoolpro_schools(id)`
- `session text not null`
- `is_configured boolean not null default false`
- `created_at`, `updated_at` timestamps
- `created_by`, `updated_by` user UUID audit fields
- Unique key: (`school_id`, `session`)

A calendar becomes enforceable only after a complete seven-day weekly pattern is saved. This avoids silently assuming a school's working days and avoids applying an incomplete setup. The UI must clearly show an unconfigured session and prevent attendance entry for dates in that session until configuration is completed; do not silently fall back to weekdays.

### 2. Weekly instructional pattern

Proposed table: `public.schoolpro_instructional_weekdays`

- `school_id uuid not null`
- `session text not null`
- `iso_weekday smallint not null check (iso_weekday between 1 and 7)` (Monday=1, Sunday=7)
- `is_instructional boolean not null`
- Primary/unique key: (`school_id`, `session`, `iso_weekday`)
- Exactly seven rows are required before the parent setting can be marked configured.

Store a session-specific snapshot. Do not let changing the current session's pattern rewrite historical sessions.

### 3. Date-specific exceptions

Proposed table: `public.schoolpro_instructional_calendar_exceptions`

- `id uuid primary key`
- `school_id uuid not null`
- `session text not null`
- `calendar_date date not null`
- `exception_type text not null check in ('public_holiday','school_holiday','emergency_closure','make_up_instructional')`
- `title text not null`
- `notes text null`
- `created_by uuid not null`, `updated_by uuid null`
- timestamps
- Unique key: (`school_id`, `session`, `calendar_date`)

A date exception takes precedence over the weekly pattern. The first three exception types make a date non-instructional. `make_up_instructional` explicitly makes a normally closed date instructional (for example, a Saturday make-up day). A date can have only one authoritative override per school/session; editing it replaces the existing classification and is audited.

Public holidays must be entered or imported as explicit date records and confirmed by the school. Do not infer a holiday from an event title, free text, or an external holiday feed without an explicit school-approved record.

## Attendance enforcement

Add a dedicated `BEFORE INSERT OR UPDATE` trigger on `public.schoolpro_attendance` that:

1. Runs after the existing session-stamping trigger in PostgreSQL's alphabetical trigger order (name it so ordering is explicit and verify it in the test).
2. Resolves `school_id`, `session`, and `attendance_date` against the existing term settings; reject if the date is outside the selected session's configured term range.
3. Requires a configured instructional calendar for that school/session.
4. Looks up a date exception first. If present, its explicit classification wins; otherwise use the weekly ISO weekday row.
5. Rejects a new attendance record or a changed attendance date when the resolved day is non-instructional.
6. Does not reject status/notes corrections to an existing attendance row when its date and school/session identity have not changed. This preserves legitimate correction of historical records even if the school later changes its calendar.
7. Leaves existing student/class ownership, inactive-student, workspace activation, session-stamping, and audit triggers intact.

The implementation must not rely on frontend validation as the enforcement boundary. It must also avoid changing the existing attendance status enum or its explicit-marking behavior.

## Access-control requirements

- RLS enabled on every new table.
- Read access limited to active members of the same school (and platform Super Admin through the established helper).
- Only Proprietor or School Administrator can create, edit, activate, or remove instructional calendar configuration and exceptions.
- Other staff may read the calendar for their attendance and timetable workflows but cannot modify school-wide instructional policy.
- Grant only the required Data API privileges and pair grants with RLS. Supabase changed the default exposure behavior for newly created `public` tables; do not assume a new table is automatically reachable.
- Internal trigger functions stay in the `private` schema, use an empty/fixed `search_path`, and have execution revoked from `PUBLIC`, `anon`, and `authenticated` where appropriate.

## Required PostgreSQL regression coverage

Use transaction-scoped fixtures and roll back all test data. No production school records or production test accounts.

1. A configured Monday–Friday pattern accepts a weekday attendance row.
2. The same pattern rejects Saturday and Sunday attendance.
3. A public/school holiday exception rejects a normally instructional weekday.
4. An emergency closure rejects a normally instructional weekday.
5. A make-up instructional exception accepts a normally closed Saturday/Sunday.
6. Date exceptions override weekly rules deterministically.
7. School A's pattern/exception never affects School B.
8. Session A's historical rules remain unchanged when Session B is configured differently.
9. An unconfigured session cannot accept new attendance.
10. Changing an existing attendance date to a closed day is rejected.
11. Correcting status/notes on an existing row without changing its date remains allowed.
12. General calendar events with titles or free-text `event_type` values such as “Holiday” do not change instructional status.
13. Existing term-boundary, student/class ownership, inactive-student, workspace activation, and audit behavior remains effective.
14. Ordinary teacher/Board-scoped access cannot modify the school-wide instructional pattern; Proprietor/Administrator can.
15. RLS prevents cross-school reads and writes.

## Implementation sequence

1. Generate the migration using `supabase migration new <descriptive-name>` from the repository's supported Supabase CLI. Do not hand-invent a migration timestamp.
2. Implement the three tables, RLS/grants, audited save/configuration RPC, and attendance trigger.
3. Add the PostgreSQL regression script and wire it into the existing PostgreSQL CI workflow.
4. Run the disposable PostgreSQL tests, existing attendance tests, typecheck, and production build.
5. Review trigger ordering and policy behavior against the live schema using read-only inspection only.
6. Open a PR. No merge, production migration, production data write, or Render deployment without separate approval.

## Current tooling constraint

The connected GitHub and Supabase tools can inspect and edit repository content and perform read-only SQL inspection, but they do not provide a local Supabase CLI invocation. The repository's Supabase skill explicitly requires generating migration filenames with `supabase migration new`. Therefore this change is intentionally a design artifact only; implementation must wait until the supported CLI is available. Do not fabricate a migration filename or claim database enforcement is implemented.
