#!/bin/bash

# Script para ejecutar en la iso y añadir mejoras.

#Menú gráficos duplicado en ImageMagik-corregido
sudo rm /usr/share/applications/display-im6.q16.desktop

# Añadir paquete "git" para descargar directamente al sistema desde Github.
sudo apt update && sudo apt-get install git -y

# Instalar programa GIMP 
sudo apt-get install gimp -y

# Autologin para usuario "usuario"

cat << EOF >> /etc/lightdm/lightdm.conf 

[Seat:*]
pam-service=lightdm
pam-autologin-service=lightdm-autologin
autologin-user=usuario
autologin-user-timeout=0
session-wrapper=/etc/X11/Xsession
greeter-session=lightdm-greeter

EOF

