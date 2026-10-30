# Stage A operational tenant-index rollout runbook

**Status:** rehearsal procedure only; not production authorization.  
**Scope:** six tenant-leading indexes in `20261017180000_schoolpro_operational_tenant_indexes.sql`.  
**Guardrails:** no test accounts/schools, no application-row writes, no policy edits, no migration-ledger edits, and no production DDL without explicit approval.

## Current blockers

- Authenticated two-school acceptance previously timed out on `public.schoolpro_result_approvals`.
- The regular migration uses transactional `CREATE INDEX IF NOT EXISTS`. PostgreSQL's `CREATE INDEX CONCURRENTLY` cannot run inside a transaction block.
- The connected Supabase project has no separate development branch listed. Its listed `main` branch reports `MIGRATIONS_FAILED`. Do not reset or use it as the rehearsal target.
- Creating an isolated Supabase branch may incur cost. Obtain a quote and approval before creating one.

## 1. Rehearsal preconditions

1. Use an isolated development branch or approved disposable database with compatible PostgreSQL version and SchoolPro schema. Never use production as the rehearsal target.
2. Confirm the six target tables exist and record the PostgreSQL version.
3. Inspect all six index names. If a same-named index exists but `pg_index.indisvalid = false`, stop. `IF NOT EXISTS` does not repair an invalid index; use a separately reviewed concurrent drop/retry procedure.
4. Run each concurrent statement outside a transaction. Do not paste all statements into a tool that wraps them in a transaction.

## 2. Preflight

```sql
select current_database() as database_name,
       current_setting('server_version') as server_version,
       current_setting('transaction_read_only') as transaction_read_only;

with required(table_name, index_name) as (
  values
    ('schoolpro_library_books', 'schoolpro_library_books_school_id_idx'),
    ('schoolpro_transport_routes', 'schoolpro_transport_routes_school_id_idx'),
    ('schoolpro_hostel_rooms', 'schoolpro_hostel_rooms_school_id_idx'),
    ('schoolpro_inventory_assets', 'schoolpro_inventory_assets_school_id_idx'),
    ('schoolpro_result_approvals', 'schoolpro_result_approvals_school_id_idx'),
    ('schoolpro_promotions', 'schoolpro_promotions_school_id_idx')
)
select r.table_name,
       r.index_name,
       ns.nspname as index_schema,
       tbl.relname as index_table,
       i.indisvalid,
       i.indisready,
       pg_get_indexdef(c.oid) as index_definition
from required r
left join pg_class c on c.relname = r.index_name
left join pg_namespace ns on ns.oid = c.relnamespace
left join pg_index i on i.indexrelid = c.oid
left join pg_class tbl on tbl.oid = i.indrelid
order by r.table_name;
```

Before proceeding, verify every existing same-named index is in `public`, attached to its intended table, and valid/ready. An absent index is expected before creation; an invalid or misattached index is a stop condition.

## 3. Concurrent index statements

Run **one statement at a time**, outside a transaction, on the rehearsal database only. Stop immediately on any error.

```sql
create index concurrently if not exists schoolpro_library_books_school_id_idx
  on public.schoolpro_library_books (school_id);

create index concurrently if not exists schoolpro_transport_routes_school_id_idx
  on public.schoolpro_transport_routes (school_id);

create index concurrently if not exists schoolpro_hostel_rooms_school_id_idx
  on public.schoolpro_hostel_rooms (school_id);

create index concurrently if not exists schoolpro_inventory_assets_school_id_idx
  on public.schoolpro_inventory_assets (school_id);

create index concurrently if not exists schoolpro_result_approvals_school_id_idx
  on public.schoolpro_result_approvals (school_id);

create index concurrently if not exists schoolpro_promotions_school_id_idx
  on public.schoolpro_promotions (school_id);
```

Do not run these as one transaction. A failed concurrent build may leave an invalid index. If any statement fails, inspect `pg_index.indisvalid` and `indisready`, record the error, and stop for reviewed cleanup/retry; do not blindly rerun.

## 4. Postflight catalog verification

```sql
select ns.nspname as index_schema,
       idx.relname as index_name,
       tbl.relname as table_name,
       i.indisvalid,
       i.indisready,
       pg_get_indexdef(i.indexrelid) as index_definition,
       pg_get_expr(i.indpred, i.indrelid) as predicate
from pg_index i
join pg_class idx on idx.oid = i.indexrelid
join pg_namespace ns on ns.oid = idx.relnamespace
join pg_class tbl on tbl.oid = i.indrelid
where ns.nspname = 'public'
  and idx.relname in (
    'schoolpro_library_books_school_id_idx',
    'schoolpro_transport_routes_school_id_idx',
    'schoolpro_hostel_rooms_school_id_idx',
    'schoolpro_inventory_assets_school_id_idx',
    'schoolpro_result_approvals_school_id_idx',
    'schoolpro_promotions_school_id_idx'
  )
order by tbl.relname;
```

All six rows must exist, point to the intended table, have `indisvalid = true` and `indisready = true`, and show `school_id` as the first index key. Investigate any unexpected predicate or definition.

## 5. Acceptance and stop conditions

1. Capture the same authenticated-role `EXPLAIN (COSTS, VERBOSE, SETTINGS)` for the bounded `schoolpro_result_approvals` probe used in the previous read-only review; compare against the prior sequential scan.
2. Rerun the existing authenticated two-school acceptance workflow using existing authorized identities and existing fixtures only. Do not create replacement accounts, schools, or rows.
3. Require own-school visibility and foreign-school denial across tested operational tables. Any timeout, ambiguous status-0 transport failure, returned foreign row, invalid index, or unexpected plan is a failure. Do not skip or soften assertions.
4. Index success alone does not close Stage A. Only after reviewed index evidence and successful acceptance may the separate forward-only RLS posture migration and tenant-integrity trigger migration be considered, in that order, with explicit production-change approval.
5. Do not manually mark migrations applied or repair migration history by guesswork. Reconcile migration ledger, indexes, RLS flags, policies, and triggers after each separately approved change.

## 6. Production change gate

Before production execution, obtain explicit approval for the exact change set, order, and window. Review lock/availability impact, current index state, rollback/retry plan, and acceptance criteria. This runbook does not authorize production changes.
