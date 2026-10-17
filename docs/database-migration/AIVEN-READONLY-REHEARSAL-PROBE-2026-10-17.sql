-- Read-only metadata probe for the existing isolated Aiven rehearsal candidate.
-- This file is NOT a migration. Do not run against production or with a write-capable session.
-- The wrapper sets default_transaction_read_only=on; BEGIN READ ONLY is a second guard.
BEGIN READ ONLY;

SELECT
  current_database() AS database_name,
  current_user AS connected_role,
  current_setting('transaction_read_only') AS transaction_read_only,
  version() AS server_version,
  inet_server_addr()::text AS server_address,
  inet_server_port() AS server_port,
  pg_database_size(current_database()) AS database_bytes;

SELECT
  current_user AS connected_role,
  r.rolsuper AS is_superuser,
  r.rolcreaterole AS can_create_roles,
  r.rolcreatedb AS can_create_databases,
  r.rolreplication AS can_replicate,
  r.rolbypassrls AS bypasses_rls
FROM pg_roles AS r
WHERE r.rolname = current_user;

SELECT extname AS extension_name, extversion AS extension_version
FROM pg_extension
ORDER BY extname;

SELECT
  n.nspname AS schema_name,
  count(*) FILTER (WHERE c.relkind IN ('r','p')) AS table_or_partition_count,
  count(*) FILTER (WHERE c.relkind = 'v') AS view_count,
  count(*) FILTER (WHERE c.relkind = 'm') AS materialized_view_count,
  count(*) FILTER (WHERE c.relkind = 'S') AS sequence_count
FROM pg_class AS c
JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname NOT IN ('information_schema')
  AND n.nspname NOT LIKE 'pg_%'
GROUP BY n.nspname
ORDER BY n.nspname;

SELECT
  n.nspname AS schema_name,
  c.relname AS relation_name,
  c.relkind AS relation_kind,
  c.relrowsecurity AS rls_enabled,
  c.relforcerowsecurity AS force_rls,
  pg_get_userbyid(c.relowner) AS relation_owner
FROM pg_class AS c
JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname IN ('public','auth','storage','private')
  AND (c.relname LIKE 'schoolpro_%'
       OR c.relname IN ('profiles','virtual_accounts','audit_logs'))
  AND c.relkind IN ('r','p','v','m')
ORDER BY n.nspname, c.relname;

SELECT
  to_regclass('public.schoolpro_schools') IS NOT NULL AS has_schoolpro_schools,
  to_regclass('public.schoolpro_students') IS NOT NULL AS has_schoolpro_students,
  to_regclass('public.schoolpro_results') IS NOT NULL AS has_schoolpro_results,
  to_regclass('public.schoolpro_document_issues') IS NOT NULL AS has_schoolpro_document_issues,
  to_regclass('auth.users') IS NOT NULL AS has_auth_users,
  to_regclass('storage.objects') IS NOT NULL AS has_storage_objects;

ROLLBACK;
