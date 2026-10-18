# SchoolPro trusted API (migration rehearsal)

This service is an **isolated, fail-closed starting point** for moving SchoolPro database reads to Aiven. It does not replace the current frontend's direct Supabase calls and must not be considered a completed application migration.

## Runtime contract

Required server-only environment variables:

- `SUPABASE_URL`: existing Supabase Auth project URL. Auth remains the identity provider during the first migration phase.
- `SUPABASE_PUBLISHABLE_KEY`: public/publishable key used only to call Supabase Auth's `/auth/v1/user` endpoint. Never use a service-role key here.
- `DATABASE_URL`: Aiven PostgreSQL URL for a dedicated least-privileged runtime role. Do not use `avnadmin`, a superuser, or a role with `BYPASSRLS`.
- `DATABASE_CA_CERT`: Aiven CA certificate PEM text. TLS certificate validation is mandatory.
- `PLATFORM_ADMIN_USER_IDS`: comma-separated, server-configured Supabase Auth UUIDs allowed platform-wide visibility. Do not derive this privilege from user-editable metadata or a client-supplied role.
- `SCHOOLPRO_ALLOWED_ORIGINS`: comma-separated exact browser origins; do not use `*`.
- `PORT`: supplied by the hosting platform.

## Routes

- `GET /health/live`: process liveness only.
- `GET /health/ready`: database connection plus required SchoolPro table check; returns 503 until the target schema exists.
- `GET /v1/me`: verifies the access token against Supabase Auth, then returns only schools owned by or linked through `public.schoolpro_members`; platform-wide access is granted only to UUIDs in the server allowlist.
- `GET /v1/schools/:schoolId`: verifies the access token and rechecks owner/member membership in the SQL query. Non-members receive a non-disclosing 404.

All SQL values are parameterized. Responses are non-cacheable. Database errors, credentials, and SQL details are not returned to clients.

## Important limitations / acceptance gates

1. The Aiven target currently has no SchoolPro schema; readiness must fail until a reviewed, curated migration is applied.
2. Only read-only school-context endpoints exist. Academic/results/payment/storage workflows are not migrated. Keep the current production frontend pointed at its current service until each workflow is moved and tested.
3. Auth is checked online with Supabase for each request. This preserves identity without copying Supabase password hashes or Auth internals into Aiven.
4. Create the dedicated Aiven runtime role only after the target schema is designed. Grant the minimum required table privileges; it must not be superuser or have `BYPASSRLS`.
5. Configure this as a separate Render **Web Service** with root directory `server`, build command `npm install`, start command `npm start`. The current SchoolPro Render service is a static site and cannot host this Node server.
6. Do not set production environment variables, create/deploy a live service, merge this branch, or switch frontend traffic until the rehearsal and rollback criteria are approved.
7. Test with two real isolated school identities and the platform-admin identity: member can read own school; another school's ID returns 404; anonymous/expired token returns 401; admin visibility is explicit and audited; readiness fails before schema migration.
