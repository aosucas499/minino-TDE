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

# Comprueba si está instalado en el sistema el paquete solicitado
# ---

function isPackageInstalled {

	# Comprobaciones a realizar 
	# ---

	# Paquete a comprobar
	app=$1;

	# Paquete instalado
    ins=$(dpkg --get-selections | grep $app | grep [^de]install | wc -l); 

	# Situación actual
	# ---

	[ $ins -eq 1 ] && echo "True" || echo "False";
}

# Elimina el teclado virtual matchbox
# ---

function delete-matchbox {

	# Salimos si ya está aplicado el cambio
	# ---

	aux=$(isPackageInstalled matchbox-keyboard)

	if [[ $aux == "False" ]]; then
		echo "Matchbox ya estaba eliminado"
		return
	fi
	
	# Aplicamos el cambio
	# ---

    sudo apt-get purge --remove matchbox-keyboard -y
    sudo rm /usr/local/share/applications/minino/match-keyboard.desktop
	sudo rm /home/$USER/Escritorio/minino-match-keyboard.desktop
	echo -e "${ROJO}matchbox keyboard desinstalado${NORMAL}"
}

# Establece la hora al inicio
# ---

function ntp-fix {

	# Salimos si ya está aplicado el cambio
	# ---

	if [[ -f /usr/bin/fix-ntp ]]; then
		echo "Ya está corregida la hora por NTP"
		return
	fi
	
	# Aplicamos el cambio
	# ---

    sudo timedatectl set-timezone Europe/Madrid
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

	# Salimos si ya está aplicado el cambio
	# ---

	aux=$(isPackageInstalled florence)

	if [[ $aux == "False" ]]; then
		echo "Florence ya estaba instalado"
		return
	fi
	
	# Aplicamos el cambio
	# ---

    # Instala Florence y sus dependencias al sistema
    sudo apt-get install florence at-spi2-core florence -y
	echo -e "${ROJO}Teclado virtual Florence instalado${NORMAL}"
}

# Obtiene el SHA1 del último commit
# ---

function getLatestCommit() {
	echo $(wget --quiet -O- https://api.github.com/repos/aosucas499/minino-TDE/commits | grep '"sha":' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
}

# Evita que se instale en el pendrive por error
# ---

function corregirInstalacionDesatendida {

	# Obtenemos la última versión del fichero a descargar

	commit=$(getLatestCommit)

	# Descargamos la versión original de minino-installer-b 
	# (en lugar de tratar de averiguar qué versión hay en el equipo, partimos siempre de la original)

	sudo wget -q https://raw.githubusercontent.com/aosucas499/minino-TDE/$commit/tools/minino-installer-b -O /usr/local/bin/minino-installer-b
	
	# Descargamos el fichero con el parche a aplicar

	wget -q https://raw.githubusercontent.com/aosucas499/minino-TDE/$commit/tools/minino-install.patch -O /tmp/minino-install.patch

	# Aplicamos el parche que modifica el fichero de instalación desantendida

    sudo patch /usr/local/bin/minino-installer-b /tmp/minino-install.patch

	# Eliminamos el fichero del parche
	
	rm -f /tmp/minino-install.patch
}

# Corrige la opción de menú duplicidad para ImageMagick
# ---

function corregirImageMagick {


	# Salimos si ya está aplicado el cambio
	# ---

	if [[ ! -f /usr/share/applications/display-im6.q16.desktop ]]; then
		echo "Ya estaba corregido el problema con ImageMagick"
		return
	fi
	
	# Aplicamos el cambio
	# ---

    # Menú gráficos duplicados en ImageMagik-corregido

    sudo rm /usr/share/applications/display-im6.q16.desktop
	echo -e "${ROJO}corregido duplicidad menú gráficos${NORMAL}"
}

# Muestra asteriscos al introducir passwords en la terminal
# ---

function showAsterisks {

	# Comprobamos si muestra asteriscos ya
	# ---

    ins=$(sudo cat /etc/sudoers | grep pwfeedback | wc -l); 

	if [[ $ins -eq 1 ]]; then
		echo "El sistema ya muestra asteriscos al introducir contraseñas";
		return
	fi

	# Activamos el uso de asteriscos al introducir contraseñas
	# ---

	sudo sed -i -e 's/env_reset/env_reset,pwfeedback/g' /etc/sudoers
}

# Convierte customize script en app del sistema
# ---

function customize-app {

	# Salimos si ya está aplicado el cambio
	# ---

	if [[ -f /usr/bin/customize-minino ]]; then
		echo "Customize-minino ya es una app del sistema"
		return
	fi

	# Aplicamos el cambio
	# ---

    sudo cp ./customize/customize-minino.sh /usr/bin/customize-minino
    sudo chmod +x /usr/bin/customize-minino
    sudo cp ./customize/customize-minino.desktop /usr/share/applications
    sudo cp ./customize/customize-minino.desktop /home/$USER/Escritorio
	echo -e "${ROJO}Aplicación customize-minino instalada${NORMAL}"
}

function firefox83-system {

	# Comprobamos si el cambio ya ha sido aplicado previamente
	# ---

	if [[ -d /usr/lib/firefox-latest ]]; then
		echo "Ya tenemos firefox83 en el sistema"
		return
	fi

	# Eliminamos del sistema la version noroot para el usuario
	
	sudo rm -rf	/home/$USER/firefox
	sudo rm -f 	/home/$USER/Escritorio/Firefox-83
	sudo rm -f 	/home/$USER/.local/share/applications/firefox-noroot.desktop
	sudo rm -rf /home/$USER/Descargas/actualiza-firefox-guadalinex-master
	sudo rm -f 	/home/$USER/Descargas/actualiza-firefox-guadalinex-master.zip

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
	echo -e "${ROJO}Firefox instalado en el sistema${NORMAL}"
    
}

function prepareIso {
	echo -e "${ROJO}Preparando la ISO${NORMAL}"
	#Borramos archivos innecesarios 
	sudo rm ~/.local/share/applications/appimagekit-balena-etcher-electron.desktop
	sudo rm -r /home/usuario/Descargas/*
	sudo rm -r /home/Systemback

	#Instalamos refracta que desinstala systemback
	wget https://sourceforge.net/projects/refracta/files/tools/older_versions/refractasnapshot-base_9.2.2_all.deb
	wget https://sourceforge.net/projects/refracta/files/tools/older_versions/refractasnapshot-gui_9.2.2_all.deb
	sudo dpkg -i refractasnapshot-base*
	sudo dpkg -i refractasnapshot-gui*
	sudo apt-get install -f -y
	sudo rm refracta*.deb

	#modificamos opciones y texto del grub
	sudo cp ./tools/splash.png /usr/lib/refractasnapshot/iso/isolinux/splash.png
	sudo cp ./tools/splash.png /usr/lib/refractasnapshot/iso/isolinux-refracta/splash.png
	sudo sed -i "s/GALPon/#TDE/g" "/usr/lib/refractasnapshot/iso/isolinux/isolinux.conf"
	sudo sed -i "s/Queiles/#TDE/g" "/usr/lib/refractasnapshot/iso/isolinux/menu_ca.cfg"
	sudo sed -i "s/Queiles/#TDE/g" "/usr/lib/refractasnapshot/iso/isolinux/menu_ca.conf"
	sudo sed -i "s/Queiles/#TDE/g" "/usr/lib/refractasnapshot/iso/isolinux/menu_en.cfg"
	sudo sed -i "s/Queiles/#TDE/g" "/usr/lib/refractasnapshot/iso/isolinux/menu_en.conf"
	sudo sed -i "s/Queiles/#TDE/g" "/usr/lib/refractasnapshot/iso/isolinux/menu_es.cfg"
	sudo sed -i "s/Queiles/#TDE/g" "/usr/lib/refractasnapshot/iso/isolinux/menu_es.conf"
	sudo sed -i "s/Queiles/#TDE/g" "/usr/lib/refractasnapshot/iso/isolinux/menu_eu.cfg"
	sudo sed -i "s/Queiles/#TDE/g" "/usr/lib/refractasnapshot/iso/isolinux/menu_eu.conf"
	sudo sed -i "s/Queiles/#TDE/g" "/usr/lib/refractasnapshot/iso/isolinux/menu_gl.cfg"
	sudo sed -i "s/Queiles/#TDE/g" "/usr/lib/refractasnapshot/iso/isolinux/menu_gl.conf"

	#modificaciones del instalador
	sudo sed -i '25 s/minino/usuario/g' /usr/local/bin/minino-installer-selector
	sudo sed -i '62 s/minino/usuario/g' /usr/local/bin/minino-installer-selector
	sudo sed -i '98 s/minino/usuario/g' /usr/local/bin/minino-installer-selector
	sudo sed -i '133 s/minino/usuario/g' /usr/local/bin/minino-installer-selector
	sudo sed -i '170 s/minino/usuario/g' /usr/local/bin/minino-installer-selector
	sudo sed -i -e '311,312 s/#//g' /usr/local/sbin/makelive
	sudo sed -i '28 s/yes/no/g' /etc/refractainstaller.conf
	sudo sed -i '15,17 s/#//g' /usr/lib/refractainstaller/post-install/cleanup-install.sh
	sudo sed -i '15,17 s/refractainstaller/minino-installer/g' /usr/lib/refractainstaller/post-install/cleanup-install.sh
	sudo sed -i '15,17 s/Desktop/Escritorio/g' /usr/lib/refractainstaller/post-install/cleanup-install.sh
	#sudo sed -i '$a - /home/$USER/Escritorio/minino-installer.desktop' /usr/lib/refractainstaller/installer_exclude.list
	
	sudo apt-get update -y

	#borrar repo git
	cd /home/$USER/ && sudo rm -r minino*

	echo -e "${AZUL}comandos para generar ISO${NORMAL}"
	echo "prev-mklive"
	echo "sudo makelive"
}


# -----------------------------------------------------------------------------
# Cuerpo del script
# -----------------------------------------------------------------------------

# Aseguramos tener el sistema actualizado
# ---

#sudo apt update

# Realizamos las opciones por defecto de nuestro script
# ---

firefox83-system

exit 0

delete-matchbox
ntp-fix
instalarGit
instalarFlorence
corregirImageMagick
corregirInstalacionDesatendida
showAsterisks
customize-app

exit 0

prepareIso
