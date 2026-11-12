# SchoolPro attendance and punctuality calculations — design

**Status:** Design proposal only. No schema, application code, production records, or migrations have been changed.

## User-approved requirements carried forward

- Attendance percentage is **present days ÷ actual school-open days × 100**.
- The denominator comes from the school's configured instructional calendar, not a manually guessed weekday count.
- Capture must distinguish present/on-time, late, absent, and excused/approved absence.
- Calculate punctuality percentage and a punctuality grade.
- Schools may enter date-level daily records or a cumulative/periodic class/student summary; daily Form Master entry must not be the only supported method.
- Preserve session/term history and auditable corrections.
- Reports must show the actual numerator and denominator alongside percentages and grades.

## Canonical metric definitions

For a student and a defined school, session, term, and date range:

- `open_days`: count of dates marked instructional by the authoritative school/session calendar in the selected range.
- `present_days`: count of instructional days attended on time.
- `late_days`: count of instructional days attended late.
- `absent_days`: count of instructional days missed without an approved excuse.
- `excused_days`: count of instructional days missed with an approved excuse.

Reconciliation invariant:

`present_days + late_days + absent_days + excused_days = open_days`

A school may not submit an aggregate period unless the values reconcile to the configured calendar's open-day count for that student's enrolled period. If a student joined, transferred, withdrew, or was inactive for part of the range, calculate the eligible open-day denominator only for the student's valid enrollment dates; do not penalize days before admission or after withdrawal.

### Attendance percentage

`attendance_percentage = (present_days / open_days) * 100`

This preserves the user's explicit formula. Late days are tracked separately and are not added to the present numerator. Excused absences remain in the open-day denominator because the day was open, while remaining separately visible. If `open_days = 0`, return null/not-applicable, never divide by zero or show 0%.

### Punctuality percentage

`punctuality_percentage = (present_days / (present_days + late_days)) * 100`

This measures punctuality only on days the student attended. Absences and approved absences do not become punctual attendances and do not distort the punctuality denominator. If the student has no attended days (`present_days + late_days = 0`), return null/not-applicable.

The UI and reports must label these metrics distinctly. Attendance percentage is not punctuality percentage.

## Data capture modes

### Date-level capture

- Retain the canonical attendance record for each student and instructional date.
- Status values remain present, absent, late, and excused.
- Database enforcement checks the configured calendar, enrollment, class, school, session and term.
- Daily register must require explicit status for every learner before saving.
- Bulk/date-range capture may generate individual dated records; it must not bypass the calendar or per-student validation.

### Cumulative/periodic capture

- Provide a controlled summary-entry path for an authorized role to enter present, late, absent, and excused day totals for a student/class over a defined period.
- The period must resolve to one school, session, term and date range. The server calculates `open_days` from the calendar and the student's enrollment interval; users must not override the denominator.
- Enforce the reconciliation invariant and reject negative values, fractional days unless an explicit partial-day policy is introduced, totals above open days, overlapping duplicate summaries, and edits to locked/published periods without the designated correction workflow.
- Store the source mode, period boundaries, submitted counts, computed denominator, submitting user, timestamps, approval/lock state, and correction reason.
- Cumulative summaries must remain clearly identified as aggregate-origin data; do not fabricate individual daily attendance rows from totals.
- If date-level rows and cumulative summaries coexist for the same student/period, define one authoritative source and prevent double counting. The safe default is to reject overlapping active sources until a deliberate reconciliation workflow is implemented.

## Configurable punctuality grades

Do not hardcode A–F bands, percentage cutoffs, or an institution-wide threshold. Provide school-owned, versioned grade bands with:

- school ID and effective session/term;
- grade label and optional description;
- inclusive lower/upper percentage bounds, with no gaps or overlaps across the configured scale;
- effective-from date and status;
- creator/editor and audit timestamps.

A grade scale version becomes immutable once used to calculate or publish a result. Later changes create a new version and apply prospectively, unless an authorized correction explicitly recalculates a historical period with a recorded reason and retains the previous calculation version/result.

A result stores the calculation version, raw counts, denominators, unrounded metric values, displayed rounded values, grade band/version, and calculation timestamp. Grade is null/not-applicable where punctuality percentage is undefined.

## Roles and workflow

- Proprietor/School Administrator: school-wide calendar, grade-scale, aggregate-entry policy and correction authority.
- Form Master: daily class register and authorized class-period capture.
- Subject Teacher: no default attendance write access; only explicit scoped grants if delegated.
- Other staff: only their assigned module/class scope.
- Board designation alone does not grant school-wide access.
- Every cumulative submission, approval, correction, lock, unlock, and recalculation is auditable with actor, timestamp, old/new values, and reason.

## Reporting

Student, class, arm, section, term and session views show:
- present, late, absent, excused;
- open-day denominator and eligible enrollment days;
- attendance percentage;
- punctuality percentage and grade;
- capture mode (daily or cumulative);
- grade-scale/calculation version and last correction metadata where authorized.

Report cards must not display a percentage without its denominator context. For example, display `Attendance: 42/50 open days (84%)`, and `Punctuality: 42/45 attended days on time (93.3%)`. Example values are illustrative only, not school records or grading thresholds.

## Regression requirements

1. Attendance percentage follows present/open-days × 100.
2. Late days are excluded from the present numerator and remain separately counted.
3. Punctuality percentage follows present/(present+late) × 100.
4. Absences and excused absences do not inflate punctuality.
5. Excused absences remain visible and reconcile to open days.
6. Zero open days returns not-applicable, not a divide-by-zero or false 0%.
7. Zero attended days returns punctuality not-applicable.
8. Calendar closures/holidays are excluded from open-day denominator.
9. Approved make-up days are included.
10. Enrollment start/end boundaries adjust eligible open days.
11. Cumulative totals must reconcile with the calendar-derived denominator.
12. Negative, fractional (unless explicitly supported), excessive, duplicate, or overlapping aggregates are rejected.
13. Daily and cumulative sources cannot double-count a period.
14. Historical calculations retain their exact grading-rule version.
15. New grading bands cannot retroactively mutate published results.
16. Role and RLS checks prevent cross-school or unauthorized writes.
17. Corrections and recalculations preserve prior values and audit reasons.
18. Student/class/section/session reports show consistent raw counts, denominators, percentages and grade.

## Implementation dependency

This design depends on the instructional calendar model documented in `SCHOOLPRO-INSTRUCTIONAL-CALENDAR-DESIGN.md`. The calendar must become the sole authority for school-open days before production calculations are enabled.

The connected environment does not expose the local Supabase CLI required by the repository's migration workflow. This is a design-only artifact; do not invent migration timestamps, implement partial frontend calculations against guessed denominators, or apply production SQL.
