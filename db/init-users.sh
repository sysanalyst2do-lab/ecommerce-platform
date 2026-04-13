#!/bin/sh
set -eu

if [ -z "${TECH_RO_PASSWORD:-}" ] || [ -z "${TECH_ADMIN_PASSWORD:-}" ]; then
  echo "ERROR: TECH_RO_PASSWORD and TECH_ADMIN_PASSWORD must be set (for example via .env)." >&2
  exit 1
fi

escape_sql_literal() {
  # Escape single quotes for SQL string literal.
  printf "%s" "$1" | sed "s/'/''/g"
}

RO_PASS_ESCAPED="$(escape_sql_literal "$TECH_RO_PASSWORD")"
ADMIN_PASS_ESCAPED="$(escape_sql_literal "$TECH_ADMIN_PASSWORD")"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<EOF
ALTER ROLE ecom_tech_ro WITH PASSWORD '${RO_PASS_ESCAPED}';
ALTER ROLE ecom_tech_admin WITH PASSWORD '${ADMIN_PASS_ESCAPED}';
EOF
