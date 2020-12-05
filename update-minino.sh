#!/bin/bash

# Script para ejecutar en la iso y añadir mejoras.

#Menú gráficos duplicado en ImageMagik-corregido
sudo rm /usr/share/applications/display-im6.q16.desktop

# Añadir paquete "git" para descargar directamente al sistema desde Github.
sudo apt update && sudo apt-get install git -y

# Instalar programa GIMP 
sudo apt-get install gimp -y
