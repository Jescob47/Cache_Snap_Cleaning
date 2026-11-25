#!/bin/bash
# Limpieza general mensual — corregida el 2026-11-25 (ver README).
# Libera disco en los EC2 sin tocar lo que usan los programas que están corriendo:
#   1. journal de systemd: deja los últimos 100 MB (journalctl --vacuum-size);
#   2. apt: borra los .deb descargados y los paquetes que ya nada necesita;
#   3. /tmp: borra solo archivos que nadie tocó en 7 días o más, y luego las carpetas vacías igual de viejas.
#
# Quitado el 2026-11-25:
#   - el ciclo de snaps: pasaba la VERSIÓN como nombre del snap (el log decía
#     `snap "3.3.5226.0" is not installed`), así que nunca borró nada; eso lo hace snap_cleanup.sh;
#   - `truncate -s 0 /var/log/syslog` y `kern.log`: borraba el historial (logrotate ya los rota y comprime);
#   - `rm -rf /tmp/*`: borraba archivos que estaban usando los procesos y los cron en marcha.
set -u

echo "=== Cache cleanup started: $(date) ==="

echo "[1/3] Journal: keep the last 100 MB"
sudo journalctl --vacuum-size=100M

echo "[2/3] apt: downloaded packages and packages nothing needs"
sudo apt-get clean
sudo apt-get autoremove -y

echo "[3/3] /tmp: files untouched for 7+ days"
removed=$(sudo find /tmp -xdev -mindepth 1 -type f -mtime +7 -print -delete 2>/dev/null | wc -l)
echo " - files removed: $removed"
sudo find /tmp -xdev -mindepth 1 -type d -empty -mtime +7 -delete 2>/dev/null

echo "=== Cache cleanup completed: $(date) ==="
