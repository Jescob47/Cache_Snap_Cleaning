🧹 EC2 Maintenance Scripts — README

Este repositorio contiene dos scripts diseñados para realizar mantenimiento automático en servidores Ubuntu que corren en instancias EC2 de AWS. Estos scripts ayudan a liberar espacio en disco y garantizar que el servidor se mantenga estable con el paso del tiempo.


📌 Scripts incluidos
cache_cleaning.sh

Realiza tareas de mantenimiento general sin tocar lo que usan los programas en marcha:

Deja el journal de systemd en los últimos 100 MB.

Limpia la caché de apt (los .deb descargados) y quita los paquetes que ya nada necesita.

Borra de /tmp solo los archivos que nadie tocó en 7 días o más.

🐞 Corrección del 2026-11-25: la versión anterior (1) pasaba la versión en lugar del nombre al borrar snaps (`snap "3.3.5226.0" is not installed`), así que nunca borraba nada; eso lo hace `snap_cleanup.sh`, (2) vaciaba `/var/log/syslog` y `kern.log`, borrando el historial, y (3) hacía `rm -rf /tmp/*`, que borra archivos en uso. Las tres cosas se quitaron.

| EC2 | Script | Cron (usuario `ubuntu`) | Log |
|---|---|---|---|
| `web-app` | `/home/ubuntu/maintenance/cache_cleaning.sh` | `0 3 1 * *` | `/home/ubuntu/maintenance/cache_cleaning.log` |
| `NNC automations 1` | `/home/ubuntu/cache_cleaning.sh` | `0 0 1 * *`, envuelto en `cronwrap.sh` | `/home/ubuntu/cache_cleaning.log` |

Este script está pensado para uso manual o ejecución mensual. Algunas tareas pueden afectar rendimiento si se ejecutan demasiado seguido.

snap_cleanup.sh

Libera el espacio que ocupan las versiones viejas de los snaps:

Elimina las revisiones deshabilitadas (las versiones viejas) con el propio `snap remove`, que también borra sus archivos `.snap`.

Limpia la caché de Snapd (/var/lib/snapd/cache).

Esto es útil porque Ubuntu guarda hasta 2 versiones viejas de cada snap (`refresh.retain=2`), de 50 a 300 MB cada una.

⛔ Nunca borrar a mano los archivos de /var/lib/snapd/snaps/*.snap. Un snap montado sigue funcionando hasta el próximo reinicio y después ya no monta.

🐞 Corrección del 2026-11-25

La versión anterior tenía un paso 4 que buscaba los `.snap` "huérfanos" (no montados) y los borraba. Leía mal la salida de `mount` (obtenía `snapd_snaps` en vez de `core22_2163`), así que ningún snap contaba como montado y **cada mes borraba TODOS los `.snap`, incluido el del agente SSM en uso**. En web-app su log muestra que lo hizo el 1 de agosto, de septiembre, de octubre y de noviembre de 2026. Por eso quedaron "broken" todos los snaps de los dos EC2, y un reinicio después de una de esas limpiezas habría dejado el EC2 sin agente SSM. Ese paso se eliminó: sobraba, porque `snap remove` ya borra los archivos.

snap_repair_core22_snapd.sh

Reparación de una sola vez, ya ejecutada el 2026-11-25 en los dos EC2. Instala desde la tienda la versión actual de `core22` (la base del agente SSM) y de `snapd` (el sistema de snaps), que el script viejo había dejado rotos y congelados en versiones viejas, y después quita las revisiones viejas. Corre en segundo plano (`systemd-run`), así termina aunque el agente se reinicie, y deja su log en `/home/ubuntu/snap_repair_20261125.log`.

🖥️ Dónde corre hoy

| EC2 | Script | Cron (usuario `ubuntu`) | Log |
|---|---|---|---|
| `web-app` (i-04466dd5b6374946d) | `/home/ubuntu/maintenance/snap_cleanup.sh` | `0 4 1 * *` | `/home/ubuntu/maintenance/snap_cleanup.log` |
| `NNC automations 1` (i-0730df96c886f13a0) | `/home/ubuntu/snap_cleanup.sh` | `0 3 1 * *`, envuelto en `cronwrap.sh`, que manda una alerta si falla | `/home/ubuntu/snap_cleanup.log` |

Los dos EC2 corren exactamente el `snap_cleanup.sh` de este repo (sha256 `4c07d3ed99f397fd…`, verificado el 2026-11-25). Para cambiarlo, edítalo aquí y cópialo a esas dos rutas.

⚠️ Requisito

snapd debe estar instalado. Para verificar:

snap --version

🖥️ Configuración en una instancia EC2

Sigue estos pasos desde tu sesión SSH en el servidor.

1. Conectarte al servidor EC2
ssh -i /ruta/tu-llave.pem ubuntu@<PUBLIC_IP>

2. Clonar el repositorio de GitHub
git clone https://github.com/Jescob47/Cache_Snap_Cleaning.git

3. Dar permisos de ejecución
sudo chmod +x /home/ubuntu/Cache_Snap_Cleaning/cache_cleaning.sh /home/ubuntu/Cache_Snap_Cleaning/snap_cleanup.sh

4. Probar los scripts manualmente
sudo /home/ubuntu/Cache_Snap_Cleaning/snap_cleanup.sh
sudo /home/ubuntu/Cache_Snap_Cleaning/cache_cleaning.sh

⏱️ Programar ejecución automática (cron)

Editar crontab:

sudo crontab -e


Agregar:

# Limpieza de snaps — día 1 de cada mes a las 3:00 AM
0 3 1 * * /home/ubuntu/Cache_Snap_Cleaning/snap_cleanup.sh >> /home/ubuntu/Cache_Snap_Cleaning/snap_cleanup.log 2>&1

# Limpieza general — día 1 de cada mes a las 4:00 AM
0 4 1 * * /home/ubuntu/Cache_Snap_Cleaning/cache_cleaning.sh >>/home/ubuntu/Cache_Snap_Cleaning/cache_cleaning.log 2>&1


Esto:

Automatiza ambas limpiezas.

Distribuye carga.

Guarda logs persistentes.

📊 Verificar espacio liberado

Ver uso general:

df -h


Ver qué directorios ocupan más:

sudo du -h --max-depth=1 / 2>/dev/null
