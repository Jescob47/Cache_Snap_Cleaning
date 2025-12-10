#!/bin/bash

echo "=== Snap cleanup started: $(date) ==="

##############################################
# 1. Eliminar revisiones deshabilitadas
##############################################

echo "[1/4] Removing disabled snaps..."
snap list --all | awk '/disabled/{print $1 " " $3}' | while read name revision; do
    echo " - Removing disabled snap: $name (rev $revision)"
    sudo snap remove "$name" --revision="$revision"
done

##############################################
# 2. Limpiar caché local de Snapd
##############################################

echo "[2/4] Cleaning snapd cache..."
sudo rm -f /var/lib/snapd/cache/* 2>/dev/null

##############################################
# 3. Identificar snaps activos (montados)
##############################################

echo "[3/4] Detecting active mounted snaps..."

mounted_snaps=$(mount | grep snap | awk -F'/' '{print $4 "_" $5}' | sed 's/\/.*//' )

##############################################
# 4. Identificar y borrar archivos .snap huérfanos
##############################################

echo "[4/4] Removing orphan .snap files..."

for snapfile in /var/lib/snapd/snaps/*.snap; do
    filename=$(basename "$snapfile")
    snapname=$(echo "$filename" | cut -d'_' -f1)
    rev=$(echo "$filename" | cut -d'_' -f2 | cut -d'.' -f1)

    # Formato usado por mount para compararlo: <nombre>_<rev>
    mounted="${snapname}_${rev}"

    # Si no está montado, es huérfano => SEGURO PARA BORRAR
    if ! echo "$mounted_snaps" | grep -q "$mounted"; then
        echo " - Removing orphan snap file: $filename"
        sudo rm -f "$snapfile"
    else
        echo " - Keeping active snap: $filename"
    fi
done

echo "=== Snap cleanup completed: $(date) ==="
