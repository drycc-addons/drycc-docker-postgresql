#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# Load libraries
. /opt/drycc/scripts/libpostgresql.sh
. /opt/drycc/scripts/libautoctl.sh
. /opt/drycc/scripts/libos.sh

# Load PostgreSQL environment variables
. /opt/drycc/scripts/postgresql-env.sh

export HOME="$POSTGRESQL_AUTOCTL_VOLUME_DIR"

autoctl_initialize

flags=("run" "--pgdata" "$POSTGRESQL_DATA_DIR")
cmd=$(command -v pg_autoctl)

info "** Starting PostgreSQL autoctl_node (Mode: $POSTGRESQL_AUTOCTL_MODE) **"
if am_i_root; then
    exec gosu "$POSTGRESQL_DAEMON_USER" "$cmd" "${flags[@]}"
else
    PGPASSWORD=$POSTGRESQL_REPLICATION_PASSWORD exec "$cmd" "${flags[@]}"
fi
