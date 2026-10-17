#!/usr/bin/env bash
set -euo pipefail

# Never enable shell tracing here: the connection string is sensitive.
: "${AIVEN_REHEARSAL_URL:?Set AIVEN_REHEARSAL_URL through your local secret manager/environment; do not paste it into chat or commit it.}"
case "${AIVEN_REHEARSAL_URL}" in
  *sslmode=verify-full*) ;;
  *)
    echo "Refusing connection: configure TLS with sslmode=verify-full and the correct Aiven CA certificate." >&2
    exit 2
    ;;
esac

# Extra guard against accidental writes; the SQL itself also starts READ ONLY.
export PGOPTIONS="${PGOPTIONS:+${PGOPTIONS} }-c default_transaction_read_only=on"
psql "${AIVEN_REHEARSAL_URL}" --set ON_ERROR_STOP=1 --file docs/database-migration/AIVEN-READONLY-REHEARSAL-PROBE-2026-10-17.sql
