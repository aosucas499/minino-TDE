#!/bin/bash

# =============================================================================
# Script para ejecutar en la iso y añadir mejoras.
# =============================================================================

# -----------------------------------------------------------------------------
# Definición de las funciones utilizadas en el script
# -----------------------------------------------------------------------------

# Elimina el teclado virtual matchbox
# ---

function delete-matchbox {
    sudo apt-get purge --remove matchbox-keyboard -y
    sudo rm /usr/local/share/applications/minino/match-keyboard.desktop
	sudo rm /home/$USER/Escritorio/minino-match-keyboard.desktop
}

# Establece la hora al inicio
# ---

function ntp-fix {
    sudo dpkg-reconfigure tzdata
    sudo cp ./ntp/fix-ntp /usr/bin
    sudo chmod +x /usr/bin/fix-ntp
    sudo chown root:root ./ntp/zz-fix-ntp
    sudo chmod 0440 ./ntp/zz-fix-ntp
    sudo cp ./ntp/zz-fix-ntp /etc/sudoers.d/ 
    sudo cp ./ntp/fix-ntp.desktop /etc/xdg/autostart/
}

# Instala GIT en el sistema
# ---

function instalarGit {

    # Añadir paquete "git" para descargar directamente al sistema desde Github.
    sudo apt update && sudo apt-get install git -y
}

# Instala el tecladro virtual Florece en el sistema
# ---

function instalarFlorence {

    # Instala Florence y sus dependencias al sistema
    sudo apt-get install florence at-spi2-core florence -y
}


# Corrige la opción de menú duplicidad para ImageMagick
# ---

function corregirImageMagick {

    # Menú gráficos duplicados en ImageMagik-corregido
    sudo rm /usr/share/applications/display-im6.q16.desktop
}

# Convierte customize script en app del sistema
# ---

function customize-app {
    sudo cp ./customize/customize-minino.sh /usr/bin/customize-minino
    sudo chmod +x /usr/bin/customize-minino
    sudo cp ./customize/customize-minino.desktop /usr/share/applications
    sudo cp ./customize/customize-minino.desktop /home/$USER/Escritorio
    
}

# -----------------------------------------------------------------------------
# Cuerpo del script
# -----------------------------------------------------------------------------

# Realizamos las opciones por defecto de nuestro script
# ---

delete-matchbox
ntp-fix
instalarGit
instalarFlorence
corregirImageMagick
customize-app