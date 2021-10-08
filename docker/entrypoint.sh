#!/bin/bash

set -e

if [ -v DB_PASSWORD_FILE ]; then
    DB_PASSWORD="$(< $DB_PASSWORD_FILE)"
fi

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file
: ${DB_HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${DB_PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${DB_USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${DB_PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then       
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" |cut -d " " -f3|sed 's/["\n\r]//g')
    fi;
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}

# READ ADDONS
if [ -d "/mnt/src-addons/*" ]; then
    for dir in /mnt/src-addons/*; do export ERP_ADDONS_PATH=$ERP_ADDONS_PATH",$dir"; done
fi

if [ -d "/mnt/vendor-addons/*" ]; then
    for dir in /mnt/vendor-addons/*; do export ERP_ADDONS_PATH=$ERP_ADDONS_PATH",$dir"; done
fi

if [ -d "/mnt/vendor-addons/OCA/*" ]; then
    for dir in /mnt/vendor-addons/OCA/*; do export ERP_ADDONS_PATH=$ERP_ADDONS_PATH",$dir"; done
fi

if [ -d "/mnt/vendor-addons/odoo/ee/*" ]; then
    for dir in /mnt/vendor-addons/odoo/ee/*; do export ERP_ADDONS_PATH=$ERP_ADDONS_PATH",$dir"; done
fi

# MAKE ODOO.CONF FILE
# envsubst < /etc/odoo/tmpl.conf > "$ODOO_RC"
compgen -A variable ERP_ | while read v; do
    var_name="$v";
    var=${var_name/ERP_/};
    echo "${var,,} = ${!v}" >> "$ODOO_RC"; done

# SET DATABASE PARAMETERS
check_config "db_host" "$DB_HOST"
check_config "db_port" "$DB_PORT"
check_config "db_user" "$DB_USER"
check_config "db_password" "$DB_PASSWORD"

case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            exec odoo "$@"
        else
            # wait-for-psql.py ${DB_ARGS[@]} --timeout=30
            exec odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        # wait-for-psql.py ${DB_ARGS[@]} --timeout=30
        exec odoo "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1