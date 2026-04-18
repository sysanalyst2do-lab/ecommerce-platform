#!/bin/sh
set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if [ -f ".env" ]; then
  set -a
  # shellcheck disable=SC1091
  . ".env"
  set +a
fi

if [ -z "${TECH_RO_PASSWORD:-}" ] || [ -z "${TECH_ADMIN_PASSWORD:-}" ]; then
  echo "ERROR: TECH_RO_PASSWORD and TECH_ADMIN_PASSWORD must be set in .env." >&2
  exit 1
fi

escape_sql_literal() {
  printf "%s" "$1" | sed "s/'/''/g"
}

RO_PASS_ESCAPED="$(escape_sql_literal "$TECH_RO_PASSWORD")"
ADMIN_PASS_ESCAPED="$(escape_sql_literal "$TECH_ADMIN_PASSWORD")"

docker compose exec -T db psql -v ON_ERROR_STOP=1 --username ecommerce --dbname ecommerce <<EOF
ALTER ROLE ecom_tech_ro WITH PASSWORD '${RO_PASS_ESCAPED}';
ALTER ROLE ecom_tech_admin WITH PASSWORD '${ADMIN_PASS_ESCAPED}';
EOF

echo "Tech users password sync completed."
