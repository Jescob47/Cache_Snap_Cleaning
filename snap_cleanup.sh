#!/bin/bash

# Limpieza de snaps deshabilitados

echo "=== Snap cleanup started: $(date) ==="

# Listar snaps deshabilitados (nombre + revisión)
snap list --all | awk '/disabled/{print $1 " " $3}' | while read name revision; do
    echo "Removing disabled snap: $name (revision $revision)"
    sudo snap remove "$name" --revision="$revision"
done

echo "=== Snap cleanup finished: $(date) ==="
