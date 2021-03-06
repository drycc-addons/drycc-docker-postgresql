#!/bin/bash
#
# Drycc PostgreSQL setup

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail

# Load libraries
. /opt/drycc/scripts/liblog.sh
. /opt/drycc/scripts/libos.sh
. /opt/drycc/scripts/libvalidations.sh
. /opt/drycc/scripts/libpostgresql.sh

# Load PostgreSQL environment variables
. /opt/drycc/scripts/postgresql-env.sh

# Ensure PostgreSQL environment variables settings are valid
info "*******postgresql_validate******"
postgresql_validate
# Ensure PostgreSQL is stopped when this script ends.
trap "postgresql_stop" EXIT
# Ensure 'daemon' user exists when running as 'root'
info "*******ensure_user_exists******"
am_i_root && ensure_user_exists "$POSTGRESQL_DAEMON_USER" --group "$POSTGRESQL_DAEMON_GROUP" --uid 1001
# Fix logging issue when running as root
am_i_root && chmod o+w "$(readlink /dev/stdout)"
# Remove flags and postmaster files from a previous run
postgresql_clean_from_restart
# Allow running custom pre-initialization scripts
postgresql_custom_pre_init_scripts
# Ensure PostgreSQL is initialized
postgresql_initialize
# Allow running custom initialization scripts
postgresql_custom_init_scripts

# Allow remote connections once the initialization is finished
if ! postgresql_is_file_external "postgresql.conf" && is_boolean_yes "$POSTGRESQL_ALLOW_REMOTE_CONNECTIONS"; then
    info "Enabling remote connections"
    postgresql_enable_remote_connections
fi

# Remove any pg_hba.conf lines that match the given filters
if ! postgresql_is_file_external "pg_hba.conf" && [[ -n "$POSTGRESQL_PGHBA_REMOVE_FILTERS" ]]; then
    info "Removing lines that match these filters: ${POSTGRESQL_PGHBA_REMOVE_FILTERS}"
    postgresql_remove_pghba_lines
fi
