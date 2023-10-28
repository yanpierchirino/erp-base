#!/bin/bash

set -e

# Directorio de extra addons
extra_addons_path="/var/lib/odoo/extra_addons"

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

# Verifica si existe directorio extra addons e instala librerias requeridad si hubiere
if [ -d "$extra_addons_path" ]; then
    
    # Verifica si el archivo requirements.txt existe en el directorio
    if [ -f "$directory/requirements.txt" ]; then

        # Instala las dependencias utilizando pip
        pip install -r "$extra_addons_path/requirements.txt"
        
        echo "Dependencias de extra addons instaladas correctamente."
    else
        echo "requirements.txt no existe en el directorio."
    fi
else
    echo "No hay extra addons: $directory"
fi

# MAKE ODOO.CONF FILE
envsubst < /etc/odoo/tmpl.conf > "$ODOO_RC"
compgen -A variable ERP_ | while read v; do
    var_name="$v";
    var=${var_name/ERP_/};
    echo "${var,,} = ${!v}" >> "$ODOO_RC"; done


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