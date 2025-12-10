#!/bin/bash

# Limpiar snaps antiguos
snap list --all | awk '/disabled/{print $1, $2, $3}' | while read snap name revision; do
    sudo snap remove "$name" --revision="$revision"
done

# Limpiar logs grandes
sudo journalctl --vacuum-size=100M
sudo truncate -s 0 /var/log/syslog
sudo truncate -s 0 /var/log/kern.log

# Limpiar caché de apt y paquetes no usados
sudo apt-get clean
sudo apt-get autoremove -y

# Limpiar archivos temporales
sudo rm -rf /tmp/*
