# SchoolPro 79 cross-boundary FK target-schema disposition — 2026-10-17

## Canonical count and target distribution

The live source catalog review contains exactly 79 FKs crossing the boundary of a `public.schoolpro_*` table; all 79 are validated. Parsing the committed 79-entry register confirms this target distribution:

| Current referenced target | FK count | Target disposition |
|---|---:|---|
| `auth.users(id)` | 52 | External Supabase Auth identity reference; no cross-database FK in Aiven. Preserve UUID as an external subject identifier only where needed; trusted API validates signed JWT/session and authorization. No user/credential/session export. |
| `public.profiles(id)` | 21 | Shared profile/control-plane reference; no bulk profile copy and no cross-database FK. Preserve external actor UUID only where required; role/tenant authority must be resolved from trusted current authorization data, not a stale copied profile. |
| `public.virtual_accounts(id)` | 3 | Shared DataSub/payment integration reference; keep authoritative record in Supabase. Replace impossible cross-database FK with a documented correlation/adapter contract and explicit ownership checks. No broad virtual-account or DataSub ledger copy. |
| `public.schoolpro_schools(id)` | 2 | Inbound shared/private dependencies (`ihlink_email_queue`, `private.schoolpro_academic_clock`) reference SchoolPro tenant roots. Keep those services in Supabase for the initial rehearsal or separately redesign them; they cannot retain a physical FK to Aiven. Define synchronization/transaction semantics before moving either service. |
| `public.schoolpro_payment_intents(id)` | 1 | Referenced by shared `payment_transactions`. Keep shared payment ledger in Supabase; preserve only approved intent/correlation state via idempotent adapter. Do not split authority or migrate shared payment rows as SchoolPro data. |
| **Total** | **79** | **All target relations require an explicit cross-database disposition; FK validation does not establish tenant authorization.** |

## Target-schema consequence

Aiven PostgreSQL cannot enforce a foreign key to a table that remains in Supabase. Therefore, do not blindly recreate the 79 source constraints as if all referenced relations were part of the Aiven database. The proposed target mapping is:

1. **SchoolPro-owned tables moved together:** retain/recreate FKs that are wholly internal to the approved SchoolPro schema. For each relationship, also enforce tenant consistency with composite tenant keys/constraints where practical, or with transactionally scoped trusted-API logic. A valid parent ID alone is not sufficient authorization.
2. **Auth/profile targets (73 FKs):** retain actor UUIDs as external identity references, not as a claim that Aiven can enforce referential existence. The trusted API must verify the signed Supabase identity and active school membership/role for the requested school and row. Never trust client-supplied `school_id`, user metadata, or copied profile role as sole authority.
3. **Virtual-account/payment targets (4 FKs):** preserve external correlation IDs and define allowed state transitions/idempotency in the shared payment service boundary. No second ledger and no cross-product bulk copy.
4. **Inbound school-root targets (2 FKs):** keep email queue and private academic clock coupled to Supabase during initial migration/rehearsal, or explicitly redesign them before moving school roots. Do not leave dangling source FKs while assuming the school table has moved.
5. **Nullability and delete/update behavior:** before target DDL, compare each FK's columns, `convalidated`, `condeferrable`, `condeferred`, `confupdtype`, `confdeltype`, and nullable cardinality. Target actions must preserve required behavior or be deliberately changed with a documented rationale.

## Separate referential-integrity and tenant-authorization gates

- **Referential integrity:** source shows 79/79 validated. This only means referenced rows exist under current constraints.
- **Tenant authorization:** remains unapproved. Required tests must use at least two distinct schools and two school-scoped identities, plus a platform super-admin control case. Attempt cross-school SELECT, INSERT, UPDATE (including changing school/parent/actor IDs), DELETE, RPC, Storage object read/download and signed-URL issuance. Verify denials at the trusted API and target DB boundary; do not rely on a passing FK or a UI-hidden control.
- **Source row consistency:** run child-parent same-school anti-joins for every applicable FK/relationship; report counts, not only zero/nonzero. Existing checks for assignment submissions, CBT attempts/answers/questions, candidate attempts, and fee items were clean at the snapshot, but are not exhaustive for all 79 relationships.

## Status

The target disposition is now explicit for all 79 entries by referenced-target class, and the per-constraint inventory remains in [the canonical 79-entry review](SCHOOLPRO-79-CROSS-BOUNDARY-FK-REVIEW-2026-10-17.md). Exact target DDL and tenant-authorization test evidence are still open; no Aiven schema or production data has been changed.
