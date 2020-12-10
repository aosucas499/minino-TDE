#!/bin/bash

# =============================================================================
# Script para ejecutar en la iso y añadir mejoras.
# =============================================================================

# -----------------------------------------------------------------------------
# Definición de las funciones utilizadas en el script
# -----------------------------------------------------------------------------
FIREFOX=https://download-installer.cdn.mozilla.net/pub/firefox/releases/83.0/linux-i686/es-ES/firefox-83.0.tar.bz2
LANZADOR=https://raw.githubusercontent.com/aosucas499/actualiza-firefox/master/firefox-latest.desktop
NEWLANZADOR=firefox-latest.desktop
ROJO="\033[1;31m"
NORMAL="\033[0m"
AZUL="\033[1;34m"

# Elimina el teclado virtual matchbox
# ---

function delete-matchbox {
    sudo apt-get purge --remove matchbox-keyboard -y
    sudo rm /usr/local/share/applications/minino/match-keyboard.desktop
	sudo rm /home/$USER/Escritorio/minino-match-keyboard.desktop
	echo -e "${ROJO}matchbox keyboard desinstalado${NORMAL}"
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
	echo -e "${ROJO}Fix-ntp time instalado${NORMAL}"
}

# Instala GIT en el sistema
# ---

function instalarGit {

    # Añadir paquete "git" para descargar directamente al sistema desde Github.
    sudo apt-get install git -y
	echo -e "${ROJO}Git instalado${NORMAL}"
}

# Instala el tecladro virtual Florece en el sistema
# ---

function instalarFlorence {

    # Instala Florence y sus dependencias al sistema
    sudo apt-get install florence at-spi2-core florence -y
	echo -e "${ROJO}Teclado virtual Florence instalado${NORMAL}"
}


# Corrige la opción de menú duplicidad para ImageMagick
# ---

function corregirImageMagick {

    # Menú gráficos duplicados en ImageMagik-corregido
    sudo rm /usr/share/applications/display-im6.q16.desktop
	echo -e "${ROJO}corregido duplicidad menú gráficos${NORMAL}"
}

# Convierte customize script en app del sistema
# ---

function customize-app {
    sudo cp ./customize/customize-minino.sh /usr/bin/customize-minino
    sudo chmod +x /usr/bin/customize-minino
    sudo cp ./customize/customize-minino.desktop /usr/share/applications
    sudo cp ./customize/customize-minino.desktop /home/$USER/Escritorio
	echo -e "${ROJO}Aplicación customize-minino instalada${NORMAL}"
}

function firefox83-system {

	# Eliminamos del sistema la version noroot para el usuario
    sudo rm -r /home/$USER/firefox
	sudo rm /home/$USER/Escritorio/Firefox-83
	sudo rm /home/$USER/.local/share/applications/firefox-noroot.desktop
	sudo rm -r /home/$USER/Descargas/actualiza-firefox-guadalinex-master
	sudo rm /home/$USER/Descargas/actualiza-firefox-guadalinex-master.zip
	echo -e "${ROJO}Borrado firefox83 de la carpeta usuario${NORMAL}"

  	# Instala firefox 83 en el sistema
	echo -e "${AZUL}Descargando Firefox para arquitecturas de 32 bits${NORMAL}"
	wget $FIREFOX -q --show-progress
    echo -e "${AZUL}Firefox se está descomprimiendo en un directorio del sistema...${NORMAL}"
	sudo tar -xjf firefox*.tar.bz2 -C /usr/lib
	sudo mv /usr/lib/firefox /usr/lib/firefox-latest
	echo -e "${AZUL}Creando accesos directos...${NORMAL}"
	wget $LANZADOR -q
	sudo cp $NEWLANZADOR /usr/share/applications/
	cp $NEWLANZADOR ~/Escritorio
	echo -e "${ROJO}BORRANDO archivos firefox residuales...${NORMAL}"
	rm $NEWLANZADOR
	rm firefox*.tar.bz2
	#Borra el actualizador automático ya que puede que en un futuro las actualizaciones no sean compatibles con el sistema
	sudo rm /usr/lib/firefox-latest/updat* 
	#Librería necesaria para versiones nuevas de firefox, instalada previamente, pero por si las moscas	
	sudo apt-get install libatomic1 -y 
	echo -e "${ROJO}Firefox instaldo en el sistema${NORMAL}"

    
}

# -----------------------------------------------------------------------------
# Cuerpo del script
# -----------------------------------------------------------------------------

# Aseguramos tener el sistema actualizado
# ---

sudo apt update

# Realizamos las opciones por defecto de nuestro script
# ---

delete-matchbox
ntp-fix
instalarGit
instalarFlorence
corregirImageMagick
customize-app
firefox83-system
