#!/bin/bash

# =============================================================================
# Script para ejecutar en la iso y añadir mejoras.
# =============================================================================

# -----------------------------------------------------------------------------
# Definición de las constantes utilizadas en el script
# -----------------------------------------------------------------------------

# NOTA cambiar de aosucas499/minino-TDE a jasvazquez/minino-TDE para poder hacer
# pruebas sin que el cambio de "release" afecte a los usuarios que ya tenga
# autoupdate en Minino

REPO_GITHUB=aosucas499/minino-TDE

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
    ins=$(dpkg --get-selections | grep ^$app | grep [^de]install | wc -l); 

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
		echo -e "${AZUL}Matchbox ya había sido desinstalado previamente${NORMAL}"
		return
	fi
	
	# Aplicamos el cambio
	# ---

    sudo apt-get purge --remove matchbox-keyboard -y

    sudo rm -f /usr/local/share/applications/minino/match-keyboard.desktop
	sudo rm -f /home/$USER/Escritorio/minino-match-keyboard.desktop
	
	echo -e "${AZUL}Matchbox keyboard desinstalado correctamente${NORMAL}"
}

# Establece la hora al inicio
# ---

function ntp-fix {

	# Salimos si ya está aplicado el cambio
	# ---

	if [[ -f /usr/bin/fix-ntp ]]; then
		echo -e "${AZUL}Ya estaba corregida la hora por NTP${NORMAL}"
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

	echo -e "${AZUL}Fix-ntp time instalado${NORMAL}"
}

# Añade update-minino como app de inicio para comprobar 
# si existen nuevas versiones (rolling release)
# ---

function autostartUpdateMinino {

	# Salimos si ya está aplicado el cambio
	# ---

	# Para asegurar que se coloque update-minino como comando del sistema comprobamos 
	# tanto el .desktop como el script en /usr/bin

	if [[ -f /etc/xdg/autostart/updateMinino.desktop ]] && [[ -f /usr/bin/update-minino ]]; then
		echo -e "${AZUL}Update-minino ya se ejecutaba al iniciar sesión${NORMAL}"
		return
	fi
	
	# Aplicamos el cambio
	# ---

	# Creamos el fichero .desktop para el autostart
	# ---
	
	cat << EOF >> /tmp/updateMinino.desktop
[Desktop Entry]
Name=update-minino
Comment[es]=Script para actualizar el sistema
Exec=xterm -e sudo update-minino
Terminal=true
Type=Application
hidden=false

EOF

	sudo mv /tmp/updateMinino.desktop /etc/xdg/autostart

	# Añadimos update-minino.sh como comando del sistema
	# ---

    [[ -f /tmp/new.sh ]] || descargarUpdateMinino

	yes | sudo cp -f /tmp/new.sh /usr/bin/update-minino ; echo
	sudo chmod a+x /usr/bin/update-minino

	# Indicamos el final del proceso

	echo -e "${AZUL}Activado update-minino al iniciar sesión${NORMAL}"
}

# Instala GIT en el sistema
# ---

function instalarGit {

    # Añadir paquete "git" para descargar directamente al sistema desde Github.
    sudo apt-get install git -y
	echo -e "${AZUL}Git instalado${NORMAL}"
}

# Instala el tecladro virtual Florece en el sistema
# ---

function instalarFlorence {

	# Salimos si ya está aplicado el cambio
	# ---

	aux=$(isPackageInstalled florence)

	if [[ $aux == "True" ]]; then
		echo -e "${AZUL}Florence ya había sido instalado previamente${NORMAL}"
		return
	fi
	
	# Aplicamos el cambio
	# ---

    # Instala Florence y sus dependencias al sistema
    sudo apt-get install florence at-spi2-core florence -y
	echo -e "${AZUL}Instalado teclado virtual Florence correctamente${NORMAL}"
}

# Obtiene el SHA1 del último commit
# ---

function getLatestCommit() {
	echo $(wget --quiet -O- "https://api.github.com/repos/$REPO_GITHUB/commits" | grep '"sha":' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
}

#==============================================================================
# Obtiene el SHA1 de la última release del proyecto
#==============================================================================

function getLatestRelease() {
	
    version=$(wget --quiet -O- -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$REPO_GITHUB/releases" | grep '"tag_name":' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
    
    # NOTA  a pesar de la polémica main/master, a día de hoy Github 
    #       redirecciona sin problemas usemos la que usemos 

    [ -z $version ] && echo "main" || echo $version
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

	# Notificamos el final del proceso

	echo -e "${AZUL}Corregida la instalación desatendida${NORMAL}"
}

# Corrige la opción de menú duplicidad para ImageMagick
# ---

function corregirImageMagick {


	# Salimos si ya está aplicado el cambio
	# ---

	if [[ ! -f /usr/share/applications/display-im6.q16.desktop ]]; then
		echo -e "${AZUL}Ya había sido corregido el problema con ImageMagick previamente${NORMAL}"
		return
	fi
	
	# Aplicamos el cambio
	# ---

    # Menú gráficos duplicados en ImageMagik-corregido

    sudo rm /usr/share/applications/display-im6.q16.desktop
	echo -e "${AZUL}Corregida duplicidad de ImageMagick en el menú${NORMAL}"
}

# Muestra asteriscos al introducir passwords en la terminal
# ---

function showAsterisks {

	# Comprobamos si muestra asteriscos ya
	# ---

    ins=$(sudo cat /etc/sudoers | grep pwfeedback | wc -l); 

	if [[ $ins -eq 1 ]]; then
		echo -e "${AZUL}El sistema ya estaba configurado para mostrar asteriscos al introducir contraseñas${NORMAL}";
		return
	fi

	# Activamos el uso de asteriscos al introducir contraseñas
	# ---

	sudo sed -i -e 's/env_reset/env_reset,pwfeedback/g' /etc/sudoers
	echo -e "${AZUL}Sistema configurado para mostrar asteriscos al introducir contraseñas${NORMAL}"
}

# Convierte customize script en app del sistema
# ---

function customize-app {

	# Salimos si ya está aplicado el cambio
	# ---

	if [[ -f /usr/bin/customize-minino ]]; then
		echo -e "${AZUL}Customize-minino ya era una app del sistema${NORMAL}"
		return
	fi

	# Aplicamos el cambio
	# ---

    sudo cp ./customize/customize-minino.sh /usr/bin/customize-minino
    sudo chmod +x /usr/bin/customize-minino
    sudo cp ./customize/customize-minino.desktop /usr/share/applications
    sudo cp ./customize/customize-minino.desktop /home/$USER/Escritorio
	echo -e "${AZUL}Aplicación customize-minino instalada como app del sistema${NORMAL}"
}

function firefox83-system {

	# Comprobamos si el cambio ya ha sido aplicado previamente
	# ---

	if [[ -d /usr/lib/firefox-latest ]]; then
		echo -e "${AZUL}Ya teníamos firefox83 en el sistema${NORMAL}"
		return
	fi

	# Eliminamos del sistema la version noroot para el usuario
	
	sudo rm -rf	/home/$USER/firefox
	sudo rm -f 	/home/$USER/Escritorio/Firefox-83
	sudo rm -f 	/home/$USER/.local/share/applications/firefox-noroot.desktop
	sudo rm -rf /home/$USER/Descargas/actualiza-firefox-guadalinex-master
	sudo rm -f 	/home/$USER/Descargas/actualiza-firefox-guadalinex-master.zip

	echo -e "Borrado firefox83 de la carpeta usuario${NORMAL}"

  	# Instala firefox 83 en el sistema

	echo -e "Descargando Firefox para arquitecturas de 32 bits${NORMAL}"
	wget $FIREFOX -q --show-progress -O /tmp/firefox-latest.tar.bz2
	echo -e "Firefox se está descomprimiendo en un directorio del sistema...${NORMAL}"
	sudo tar -xjf /tmp/firefox-latest.tar.bz2 -C /usr/lib
	sudo mv /usr/lib/firefox /usr/lib/firefox-latest
	echo -e "Creando accesos directos...${NORMAL}"
	wget $LANZADOR -q -O /tmp/$NEWLANZADOR
	sudo cp /tmp/$NEWLANZADOR /usr/share/applications/
	cp /tmp/$NEWLANZADOR /home/$USER/Escritorio
	echo -e "BORRANDO archivos firefox residuales...${NORMAL}"
	rm /tmp/$NEWLANZADOR
	rm /tmp/firefox-latest.tar.bz2
	
	#Borra el actualizador automático ya que puede que en un futuro las actualizaciones no sean compatibles con el sistema
	
	sudo rm -f /usr/lib/firefox-latest/updat* 

	#Librería necesaria para versiones nuevas de firefox, instalada previamente, pero por si las moscas	
	
	sudo apt-get install libatomic1 -y 
	echo -e "${AZUL}Firefox 83 instalado correctamente en el sistema${NORMAL}"
    
}

# Añade update-minino al archivo sudoers
# ---

function sudoersUpdate {

	# Salimos si ya está aplicado el cambio
	# ---

	if [[ -f /etc/sudoers.d/zz-update-minino ]]; then
		echo -e "${AZUL}update-minino ya está añadido a sudoers${NORMAL}"
		return
	fi
	
	# Aplicamos el cambio
	# ---

    sudo chown root:root ./tools/zz-update-minino
    sudo chmod 0440 ./tools/zz-update-minino
    sudo cp ./tools/zz-update-minino /etc/sudoers.d/ 

	echo -e "${AZUL}update-minino añadido a sudoers${NORMAL}"
}

function prepareIso {
	
	echo -e "${AZUL}Preparando la ISO${NORMAL}"
	
	#Borramos archivos innecesarios 

	sudo rm -f 	~/.local/share/applications/appimagekit-balena-etcher-electron.desktop
	sudo rm -rf /home/usuario/Descargas/*
	sudo rm -rf	/home/Systemback

	#Instalamos refracta que desinstala systemback

	wget https://sourceforge.net/projects/refracta/files/tools/older_versions/refractasnapshot-base_9.2.2_all.deb
	wget https://sourceforge.net/projects/refracta/files/tools/older_versions/refractasnapshot-gui_9.2.2_all.deb

	sudo dpkg -i refractasnapshot-base*
	sudo dpkg -i refractasnapshot-gui*
	sudo apt-get install -f -y
	
	sudo rm -f refracta*.deb

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
	cd /home/$USER/ && sudo rm -rf minino*

	echo -e "${AZUL}comandos para generar ISO${NORMAL}"
	echo "prev-mklive"
	echo "sudo makelive"
}

# Clona el código del proyecto Minino-TDE
# ---

function descargarMininoTDE(){

git clone "https://github.com/$REPO_GITHUB.git" /tmp/minino
cd /tmp/minino

echo -e "${AZUL}Actualización de Minino-TDE descargada correctamente${NORMAL}"
}

#==============================================================================
# Obtiene el SHA1 de la última release del proyecto
#==============================================================================

function getLatestRelease() {
	
    version=$(wget --quiet -O- -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/$REPO_GITHUB/releases" | grep '"tag_name":' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
    
    # NOTA  a pesar de la polémica main/master, a día de hoy Github 
    #       redirecciona sin problemas usemos la que usemos 

    [ -z $version ] && echo "main" || echo $version
}

#==============================================================================
# Obtiene de Github la versión más reciente de customize-minino-sh
#==============================================================================

descargarUpdateMinino(){
    versionActual=$(getLatestRelease)
    wget -q "https://raw.githubusercontent.com/$REPO_GITHUB/$versionActual/update-minino.sh" -O /tmp/new.sh
}

#==============================================================================
# Actualizamos el script actualmente en ejecución y lo volvemos a invocar 
# tras ser actualizado para que se ejecute la nueva versión del mismo
#==============================================================================

selfUpdate(){

	echo "Procedemos a actualizar update-minino.sh..."

    # Si no hemos descargado previamente el fichero (o alguien lo ha borrado)
    # nos hacemos con una copia actualizada de update-minino.sh

    [[ -f /tmp/new.sh ]] || descargarUpdateMinino

    # Sustituimos el script actual por la nueva versión

    sudo cp /tmp/new.sh "$0"
    sudo chmod a+x "$0"

    # Lo ejecutamos

	exec "$0"
}

#==============================================================================
# Comprueba si el script no coincide con la versión actual en Github
#==============================================================================

isUpdated(){

	# Descargamos la última versión de customize-minino.sh
	#---

	descargarUpdateMinino

	# Obtenemos la ruta al update-minino cuyo hash debemos calcular
	#---

	# Damos más importancia al del sistema

	mininoPath=$(which update-minino)

	# Si no existe update-minino en el sistema, usamos la ruta al script actualmente en ejecución

	if [[ -z $mininoPath ]]; then
		mininoPath=$0
	fi
	
	# Calculamos los hash de este script y del descargado
	#---

	hashActual=$(md5sum  $mininoPath | cut -d" " -f1)
	hashNuevo=$(md5sum  /tmp/new.sh | cut -d" " -f1)

	# Comprobamos si el script está (o no) actualizado
	#---

   [ $hashActual = $hashNuevo ] && echo "True" || echo "False"
}

#==============================================================================
# Comprueba si tiene permisos de sudo
#==============================================================================

hasSudoRights(){

	res=$(sudo -l | grep \(ALL | wc -l)

   [ $res -eq 1 ] && echo "True" || echo "False"
}

# -----------------------------------------------------------------------------
# Comprueba si hay conexión a Internet
# -----------------------------------------------------------------------------

function isConnectionAvailable {
	sleep 3
    echo -e "GET http://google.com HTTP/1.0\n\n" | nc google.com 80 > /dev/null 2>&1 && echo "True" || echo "False"
}

# =============================================================================
# Cuerpo del script
# =============================================================================

# -----------------------------------------------------------------------------
# Sólo permitimos que sea utilizado por usuarios con permisos de administración
# -----------------------------------------------------------------------------

[[ $(hasSudoRights) == "False" ]] && exit 0

# Evitamos colisiones con otros scripts
# ---

rm -f /tmp/new.sh

# Comprobamos si hay internet
# ---

aux=$(isConnectionAvailable)

if [[ $aux == "False" ]]; then
	zenity \
        --warning \
        --title "Sin conexión a Internet" \
        --text "Necesitamos conexión a Internet para poder utilizar la mayoría de opciones de 'update-minino'\nPor favor revisa tu conexión y vuelve a lanzar el script cuando vuelva a estar disponible.\nGracias"
        
    exit 1;
fi 

# Comprobamos que no haya un "token" de estar actualizando el script
# ---

files=(/tmp/updateminino-*);

if [[ ! -e "${files[0]}" ]]; then

	# Comprobamos si existe una versión más "moderna" de customize-minino.sh
	# ---

	aux=$(isUpdated)

	if [[ $aux == "False" ]]; then

		zenity --question  --text "Existe una nueva versión de MININO-TDE.\n¿Desea que me actualice para disfrutar de la nueva versión?"

		if [[ $? = 0 ]]; then

			# Creamos token de actualización
			touch /tmp/updateminino-$(head -3 /dev/urandom | tr -cd '[:alnum:]' | cut -c -5)

			# Actualizamos el script
			selfUpdate;
			
		else
			echo -e "${AZUL}Sin problemas, ya habrá oportunidad de hacerlo.${NORMAL}"
		fi

	fi 

	# Elija lo que elija el usuario, debemos salir

	exit 0

fi

# Si llegamos aquí es porque había un "token" de estar actualizando
# Lo eliminamos para que no vuelva a ser usado y procedemos con la actualización

rm -f /tmp/updateminino-*

# Aseguramos tener el sistema actualizado
# ---

sudo apt update

# Descargamos nuestro código de github
# ---

instalarGit
descargarMininoTDE

# Realizamos las opciones por defecto de nuestro script
# ---

delete-matchbox
ntp-fix
instalarFlorence
corregirImageMagick
corregirInstalacionDesatendida
showAsterisks
customize-app
firefox83-system
sudoersUpdate

autostartUpdateMinino

# Limpiamos descargas temporales
# ---

sudo rm -rf /tmp/minino

echo ""
echo "----------------------------------------------------"
echo "Pulsa cualquier tecla para finalizar"
echo "----------------------------------------------------"

read -rsn1 ; echo

exit 0

# IDEA 	crear app específica en los menús de Minino para generar la ISO
#		para aquellos que puedan necesitarla
#

prepareIso
