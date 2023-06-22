#!/bin/bash

# =============================================================================
# Script para ejecutar en la iso y dar opción a añadir mejoras
# =============================================================================

# -----------------------------------------------------------------------------
# Configuración del script
# -----------------------------------------------------------------------------

# Constante que impide que se ejecuten las opciones elegidas

readonly DEBUG='n'

# NOTA cambiar de aosucas499/minino-TDE a jasvazquez/minino-TDE para poder hacer
# pruebas sin que el cambio de "release" afecte a los usuarios que ya tenga
# autoupdate en Minino

REPO_GITHUB=aosucas499/minino-testing

#Actualizamos si quiere el usuario el sistema con update-minino por si es necesario algún paquete para customize-minino 
update-minino

# -----------------------------------------------------------------------------
# Definición de las funciones utilizadas en el script
# -----------------------------------------------------------------------------

#==============================================================================
# Gestión del control del brillo en sistemas con gráfica intel
#==============================================================================

# Instala la aplicación cga-brillo.
# ---

function cga-brillo {

	# Instala la aplicación cga-brillo
	#    
    	sudo apt-get update -y
	
	wget "https://github.com/$REPO_GITHUB/raw/main/cga-brillo/cga-indicator-brightness_0.1-8_all.deb" -O /tmp/cga-indicator-brightness_0.1-8_all.deb
	
	wget "https://github.com/$REPO_GITHUB/raw/main/cga-brillo/indicator-applet-complete_0.5.0-0ubuntu1_i386.deb" -O /tmp/indicator-applet-complete_0.5.0-0ubuntu1_i386.deb
	
	wget "https://github.com/$REPO_GITHUB/raw/main/cga-brillo/libnotify-bin_0.7.5-1_i386.deb" -O /tmp/libnotify-bin_0.7.5-1_i386.deb
	
	wget "https://github.com/$REPO_GITHUB/raw/main/cga-brillo/notify-osd-icons_0.7_all.deb" -O /tmp/notify-osd-icons_0.7_all.deb
	
	wget "https://github.com/$REPO_GITHUB/raw/main/cga-brillo/notify-osd_0.9.34-0ubuntu2_i386.deb" -O /tmp/notify-osd_0.9.34-0ubuntu2_i386.deb
	
	sudo dpkg -i /tmp/indicator-applet-complete_0.5.0-0ubuntu1_i386.deb
	sudo dpkg -i /tmp/libnotify-bin_0.7.5-1_i386.deb
	sudo dpkg -i /tmp/notify-osd_0.9.34-0ubuntu2_i386.deb
	sudo dpkg -i /tmp/notify-osd-icons_0.7_all.deb
	sudo dpkg -i /tmp/cga-indicator-brightness_0.1-8_all.deb
        sudo apt-get install -f -y
	sudo rm /tmp/*.deb
}

# Desactiva el apagado automático del equipo
# ---

function cga-brilloUndo {

	sudo apt-get purge --remove cga-indicator-brightness -y
}

# Comprueba si está activa la aplicación cga-brillo
# ---

function cga-brilloCheck {

	# Comprobaciones a realizar 
	# ---

	# Paquete a comprobar
	app=cga-indicator-brightness;

	# Paquete instalado
    ins=$(dpkg --get-selections | grep $app | grep [^de]install | wc -l); 

	# Situación actual
	# ---

	[ $ins -eq 1 ] && echo "True" || echo "False";
}

#==============================================================================
# Gestión de la instalación del control de presencia de Séneca
#==============================================================================

# Hace firefox-latest autoejecutable en cada inicio, trás 40 segundos en modo kiosco con la página del control de Séneca.
# Posteriormente invoca la función anterior que hace que el equipo entre en el sistema sin pedir usuario.
# ---

function controlPresencia {
	
	# Si existe el perfil principal, continuamos con el script, en caso contrario 
	# abrimos y cerramos firefox, ya que necesitamos que se abra para la creación de la carpeta del perfil de usuario
	# en este caso informamos al usuario de que vuelva a ejecutar la instalación y cierre firefox
	# No veo la manera de hacerlo sin la intervención del usuario.
	#---
	if [ ! -d /home/$USER/.mozilla/firefox/*1 ]; then
			zenity --error --text "Es la primera vez que se ejecuta firefox, ciérrelo cuando se abra y vuelva a ejecutar esta instalación"
			/usr/lib/firefox-latest/firefox -setDefaultBrowser --no-default-browser-check
			exit
		else	
			echo "Existe perfil principal de firefox"
		fi
	
	# Borramos del archivo de configuración de firefox la pantalla de bienvenida que se ejecuta la primera vez
	# Se hace añadiendo esta línea al archivo de configuración
	#---
	sed -i '$ i\user_pref("trailhead.firstrun.didSeeAboutWelcome", true);' ~/.mozilla/firefox/*.default-release-1/prefs.js
	
    	# Establecemos como página principal la web del control de presencia de Séneca
	#--- 
	# No necesario ya, pues se la pasa la web en cada inicio al comando --kiosk de firefox

    	#sed -i '$ i\user_pref("browser.startup.homepage", "https://seneca.juntadeandalucia.es/controldepresencia/");' ~/.mozilla/firefox/*.default-release-1/prefs.js
	
	# Descargamos y copiamos el ejecutable de firefox en modo kiosk que se ejecutará en cada inicio  
	# con un retardo para que le dé tiempo al script ntp de corregir la hora
	#---
	wget "https://raw.githubusercontent.com/$REPO_GITHUB/main/tools/Firefox-latest-sleep30"
    	sudo mv Firefox-latest-sleep30 /etc/xdg/autostart/Firefox-latest-sleep30.desktop

	## Informa al usuario de varios aspectos a tener en cuenta
	#---
	zenity --info --text="El control de presencia de Séneca se encuentra instalado en el sistema. Reinicie el sistema para que los cambios tengan efecto."
	zenity --info --text="Recuerde que el navegador tardará unos 40 segundos en iniciarse en cada inicio."
zenity --info --text="Quizás le interese instalar el 'Inicio de sesión automático', para que no se necesite introducir usuario y contraseña en cada inicio."
	
}

# Desactiva el control de presencia de Séneca en cada inicio
# ---

function controlPresenciaUndo {

    sudo rm /etc/xdg/autostart/Firefox-latest-sleep30.desktop
    
}

#Comprueba si está activo el control de presencia de Séneca
# ---

function controlPresenciaCheck {

	# Comprobaciones a realizar 
	#---

    # Existe el ejecutable de firefox en modo kiosk que se ejecutará en cada inicio
    [ -f /etc/xdg/autostart/Firefox-latest-sleep30.desktop ] && echo "True" || echo "False";
}

#==============================================================================
# Gestión del autologin en el sistema
#==============================================================================

# Activa el autologin para el usuario "usuario"
# ---

function activarAutoLogin {

sudo cat << EOF >> /etc/lightdm/lightdm.conf 

[Seat:*]
pam-service=lightdm
pam-autologin-service=lightdm-autologin
autologin-user=usuario
autologin-user-timeout=0
session-wrapper=/etc/X11/Xsession
greeter-session=lightdm-greeter

EOF

}

# Desactiva el acceso automático al sistema
# ---

function activarAutoLoginUndo {
    sudo sed -e '/\[Seat\:\*\]/,+7d' < /etc/lightdm/lightdm.conf > /tmp/lightdm.conf
    sudo mv /tmp/lightdm.conf /etc/lightdm/lightdm.conf
}

# Comprueba si está activo el acceso automático al sistema
# ---

function activarAutoLoginCheck {
    grep -q pam-autologin-service=lightdm-autologin /etc/lightdm/lightdm.conf > /dev/null 2>&1
	[ $? = 0 ] && echo "True" || echo "False"
}

# Ejecuta la función correspondiente a cada una de las opciones del script
# ---

function ejecutarAccionOpcional {
    ($1)
}

#==============================================================================
# Gestión del autoapagado del sistema
#==============================================================================

# Instala la aplicación qshutdown y modifica el archivo de configuración teniendo en cuenta
# lo que conteste el usuario con el uso de zenit.
# ---

function qshutdown {

	# Pide al usuario la hora a la que desea que se apague el equipo
	# 

		shutdowntime=$(zenity --entry \
                --title="Introduzca la hora para el apagado automático diario del equipo" \
                --width=500 \
                --ok-label="Aceptar" \
                --cancel-label="Lo vamos a dejar" \
                --text="Use el formato siguiente o no funcionará: 14:00")
		ans=$?
		if [ $ans -eq 0 ]
			then
			echo "La hora introducida es: ${shutdowntime}"
		else
    			echo "Otro día si eso..."
    			exit
		fi
	
	# Instala la aplicación qshutdown
	#    
    	sudo apt-get update -y
	wget https://launchpad.net/~hakaishi/+archive/ubuntu/qshutdown/+files/qshutdown_1.7.3.0-0ubuntu1_i386.deb -O /tmp/qshutdown_1.7.3.0-0ubuntu1_i386.deb
	sudo dpkg -i /tmp/qshutdown_1.7.3.0-0ubuntu1_i386.deb
        sudo apt-get install -f
			
	# Crea la carpeta del programa y modifica la configuración 
	# con la hora dada por el usuario
	#
	mkdir ~/.qshutdown/
	wget "https://raw.githubusercontent.com/$REPO_GITHUB/main/tools/qshutdown.conf" -O /home/$USER/.qshutdown/qshutdown.conf
	sed -i -e "s/14:01/$shutdowntime/g" ~/.qshutdown/qshutdown.conf
	sudo cp /usr/share/applications/qshutdown.desktop /etc/xdg/autostart/	
}

# Desactiva el apagado automático del equipo
# ---

function qshutdownUndo {

	sudo rm /etc/xdg/autostart/qshutdown.desktop
	sudo rm -r /home/$USER/.qshutdown
	sudo apt-get purge --remove qshutdown -y
	
}

# Comprueba si está activa la aplicación de apagado automático
# ---

function qshutdownCheck {

	# Comprobaciones a realizar 
	# ---

	# Paquete a comprobar
	app=qshutdown;

	# Paquete instalado
    ins=$(dpkg --get-selections | grep $app | grep [^de]install | wc -l); 

	# Situación actual
	# ---

	[ $ins -eq 1 ] && echo "True" || echo "False";
}

#==============================================================================
# Gestión del acceso por SSH
#==============================================================================

# Instala SSHD para permitir la conexión remota por SSH a Minino-TDE
# ---

function accesoSSH {
     sudo apt install openssh-server -y
}

# Desactiva el acceso por SSH
# ---

function accesoSSHUndo {
     sudo apt remove openssh-server -y
}

# Comprueba si está activo el acceso por SSH
# ---

function accesoSSHCheck {

	# Comprobaciones a realizar 
	# ---

	# Paquete a comprobar
	app=openssh-server;

	# Paquete instalado
    ins=$(dpkg --get-selections | grep $app | grep [^de]install | wc -l); 

	# Situación actual
	# ---

	[ $ins -eq 1 ] && echo "True" || echo "False";
}

#==============================================================================
# Gestión del problema de sonido en los Toshiba NB500 y Samsung N100SP
#==============================================================================

# Aplica parche de sonido al chip NM10/ICH7
# ---

function soundProblem {

    # Evitamos el mute del sonido inicial
    # --- 

    # Quitamos el mute
	amixer -c 0 set 'Headphone' unmute > /dev/null 2>&1

	# Aseguramos un volumen aceptable
	amixer -c 0 set 'Headphone' 60%  > /dev/null 2>&1
	amixer -c 0 set 'Master' 60%  > /dev/null 2>&1

    # Evitamos que pulseAudio elija el Speaker al quitar los auriculares
    # --- 

    sudo mv /usr/share/pulseaudio/alsa-mixer/paths/analog-output-speaker.conf /usr/share/pulseaudio/alsa-mixer/paths/analog-output-speaker.conf_tde > /dev/null 2>&1
    sudo mv /usr/share/pulseaudio/alsa-mixer/paths/analog-output-speaker-always.conf /usr/share/pulseaudio/alsa-mixer/paths/analog-output-speaker-always.conf_tde > /dev/null 2>&1

	# Matamos la instancia actual de pulseAudio para que se aplique el cambio

	su - "$SUDO_USER" -c "pulseaudio -k"

}

# Deshace el parche de sonido
# ---

function soundProblemUndo {

	# Dejamos la configuración como estaba originalmente
	# ---

    sudo mv /usr/share/pulseaudio/alsa-mixer/paths/analog-output-speaker.conf_tde /usr/share/pulseaudio/alsa-mixer/paths/analog-output-speaker.conf > /dev/null 2>&1
    sudo mv /usr/share/pulseaudio/alsa-mixer/paths/analog-output-speaker-always.conf_tde /usr/share/pulseaudio/alsa-mixer/paths/analog-output-speaker-always.conf > /dev/null 2>&1

	# Matamos la instancia actual de pulseAudio para que se aplique el cambio

	su - "$SUDO_USER" -c "pulseaudio -k"
}

# Comprueba si está activo el parche de sonido
# ---

function soundProblemCheck {

	# Comprobaciones a realizar 
	#---

    # Existe uno de los ficheros que hemos renombrado (backup del original)
    [ -f /usr/share/pulseaudio/alsa-mixer/paths/analog-output-speaker.conf_tde ] && echo "True" || echo "False";
}

#==============================================================================
# Gestión la instalación de HGR-Sigala
#==============================================================================

# Instala HGR-Sigala en Minino
# ---

# Instala por defecto HGR-Sigala del CGA en Minino-TDE
# ---

function instalarSigala {

	# Instalamos dependencias
	# ---

	sudo apt install -y ssh python-avahi python-qt4 python-qt4-dbus python-netifaces python-sleekxmpp python-webdav x11vnc xtightvncviewer xvnc4viewer vlc libc-ares2 rlwrap avahi-daemon setcd python-dnspython libnss-myhostname curl

	#Instalamos repositorios debian stretch e instalamos curl
	# No es necesario por ahora, podemos usar el de debian jessie, pero dejamos el método por si se necesita descargar algo de debian stretch

	#wget https://raw.githubusercontent.com/aosucas499/sources/main/minino-tde-stretch.list
	#sudo mv /etc/apt/sources.list /etc/apt/minino-tde-jessie.list
	#sudo mv minino-tde-stretch.list /etc/apt/sources.list
	#sudo apt-get update
	#sudo apt-get install -y curl

	# Instalamos repositorios guadalinex-next
	#
	
	wget https://raw.githubusercontent.com/aosucas499/sources/main/guadalinex-next.list
	sudo mv /etc/apt/sources.list /etc/apt/minino-tde-jessie.list
	sudo mv guadalinex-next.list /etc/apt/sources.list
	wget http://centros.edu.guadalinex.org/Edu/fenix/pool/main/g/guadalinexedu-keyring/guadalinexedu-keyring_0.2-1_all.deb
	sudo dpkg -i guadalinexedu-keyring_0.2-1_all.deb
	rm guadalinexedu-keyring_0.2-1_all.deb
	sudo apt-get update

	# Instalamos paquetes necesarios sigala desde guadalinex next
	
	sudo apt-get install -y ejabberd 
	sudo apt-get install -y python-sleekxmpp
	sudo apt-get install -y cga-hga

	# Instalamos repositorios debian jessie y dejamos minino en su punto inicial
	#
	
	sudo mv /etc/apt/minino-tde-jessie.list /etc/apt/sources.list
	sudo apt-get update
	
	# Añadimos permisos sudo a la aplicación para que funcione bien con docker y versiones antiguas de guadalinex
	#
	
	sudo sed -i "s/Exec=/Exec=sudo /g" "/usr/share/applications/cga-hgr-client.desktop"
	sudo sed -i "s/Exec=/Exec=sudo /g" "/usr/share/applications/cga-hgr-server.desktop"
	sudo sed -i "s/&&/\&\& sudo /g" /etc/xdg/autostart/hgr-autostart.desktop

	
	# Añadimos permisos sudo a cualquier usuario del sistema, aunque no tenga derechos de administrador
	#
	
	cd /home/$USER
	sudo cp /etc/sudoers.d/ejabberd-cgaconfig .
	sudo rm /etc/sudoers.d/ejabberd-cgaconfig
	sudo chown $USER:$USER ejabberd-cgaconfig 
	sudo chmod 765 ejabberd-cgaconfig
	sudo echo "ALL     ALL=NOPASSWD:/usr/bin/cga-hgr-client" >> ejabberd-cgaconfig
	sudo echo "ALL     ALL=NOPASSWD:/usr/bin/cga-hgr-server" >> ejabberd-cgaconfig
	sudo chown root:root ejabberd-cgaconfig
	sudo chmod 0440 ejabberd-cgaconfig
	sudo mv ejabberd-cgaconfig /etc/sudoers.d/
	
    # Creamos parche a aplicar
    # ---

    # Nos aseguramos que no exista el fichero (en caso contrario añadiría 
    # contenido y daría error al no ser un parche válido)

    rm -f /tmp/sigala-install.patch
    
    # Creamos el parche aquí para evitar el fichero tools/sigala-install.patch 
    # para que funcionen las actualizaciones automáticas de customize-minino 
    # (hasta que no hagamos un "git pull" no podemos depender de ficheros adicionales)

    cat << EOF >> /tmp/sigala-install.patch

--- /tmp/davclient.py	2021-02-19 19:46:49.711549295 +0100
+++ /tmp/davclient-new.py	2021-02-19 19:49:41.812319843 +0100
@@ -81,6 +81,9 @@
         else:
             raise Exception, 'Unsupported scheme'
         
+        if '\r' in path:
+            path=path.replace('\r','')
+            
         self._connection.request(method, path, body, headers)
             
         self.response = self._connection.getresponse()

EOF

	# Aplicamos parche que corrige el encoding al compartir ficheros
	# ---

	sudo patch /usr/lib/python2.7/dist-packages/hga/controlcompartir/cliente/davclient.py /tmp/sigala-install.patch
	
}

# Deshace la instalación de HGR-Sigala
# ---

function instalarSigalaUndo {

    # Se eliminan la mayoría de paquetes respetando aquellos (como curl o vnc) susceptibles de haber sido 
    # instalados por el usuario para otros usos

    sudo apt remove -y \
            python-avahi python-qt4 python-qt4-dbus python-netifaces \
            python-sleekxmpp python-webdav ejabberd libc-ares2 rlwrap \
            avahi-daemon setcd python-dnspython libnss-myhostname dex \
            ejabberd-cgaconfig nodejs etherpad-lite cga-hga python-sleekxmpp

}

# Comprueba si está instalado Sigala
# ---

# IDEA  esta comprobación se hace en varios sitios, sería interesante 
#       abstraer la funcionalidad a una función que pudiésemos reutilizar
#       simplemente proporcionándole como parámetro el paquete a comprobar

function instalarSigalaCheck {

	# Comprobaciones a realizar 
	# ---

	# Paquete a comprobar
	app=cga-hga;

	# Paquete instalado
    ins=$(dpkg --get-selections | grep $app | grep [^de]install | wc -l); 

	# Situación actual
	# ---

	[ $ins -eq 1 ] && echo "True" || echo "False";
}

#==============================================================================
# Gestión del modo privado en los navegadores del sistema
#==============================================================================

# Desactiva el modo incógnito en los navegadores del sistema
# ---

function navegacionPrivadaUndo {

    # Modo incógnito en los Firefox del sistema
    # ---

    # En el Firefox-latest de usuario/usuario
	 sudo sed -i -e 's/firefox\-latest\/firefox --private-window/firefox\-latest\/firefox/g' /home/$USER/Escritorio/firefox-latest.desktop

	# En el Firefox-latest del sistema
	 sudo sed -i -e 's/firefox\-latest\/firefox --private-window/firefox\-latest\/firefox/g' /usr/share/applications/firefox-latest.desktop

    # En el firefox-esr del sistema (para todos los usuarios)
     sudo sed -i -e 's/firefox-esr --private-window %u/firefox-esr %u/g' /usr/share/applications/firefox-esr.desktop

    # Modo incógnito en Chromium
    # ---

     sudo sed -i -e 's/chromium --incognito %U/chromium %U/g' /usr/share/applications/chromium.desktop

}

# Activa el modo incógnito tanto en Firefox como en Chromium
# ---

function navegacionPrivada {
    
    # Modo incógnito en los Firefox del sistema
    # ---

    # En el Firefox-latest de usuario/usuario
	sudo sed -i -e 's/firefox\-latest\/firefox/firefox\-latest\/firefox --private-window/g' /home/$USER/Escritorio/firefox-latest.desktop

	# En el Firefox-latest del sistema
	sudo sed -i -e 's/firefox\-latest\/firefox/firefox\-latest\/firefox --private-window/g' /usr/share/applications/firefox-latest.desktop

    # En el firefox-esr del sistema (para todos los usuarios)
    sudo sed -i -e 's/firefox-esr %u/firefox-esr --private-window %u/g' /usr/share/applications/firefox-esr.desktop

    # Modo incógnito en Chromium
    # ---

    sudo sed -i -e 's/chromium %U/chromium --incognito %U/g' /usr/share/applications/chromium.desktop

}

# Comprueba si está activo el modo incógnito en los navegadores del sistema
# ---

function navegacionPrivadaCheck {
    # Nos limitaremos a comprobar que se cambió en el firefox-latest que hemos metido en el sistema
    grep -q "\-\-private\-window" /usr/share/applications/firefox-latest.desktop > /dev/null 2>&1
	[ $? = 0 ] && echo "True" || echo "False"
}

# Invocamos ("callback") las funciones asociadas a las opciones 
# seleccionadas por el usuario
# ---

function procesarAccionesSeleccionadas {

    # Dividimos (el separador es "|" ) las opciones seleccionadas por el usuario
    # ---

    IFS="|" read -a vals <<< $1

    # Solicitamos (una a una) que se procesen dichas opciones

    for i in "${vals[@]}"
    do
        aux=$(ejecutarAccionOpcional $i"Check")
        if [[ $aux == "False" ]]; then
            echo "Ejecutamos "$i"()"
            [[ $DEBUG != 'y' ]] && ejecutarAccionOpcional $i || echo "No se ejecuta "$i"() por estar en modo DEBUG"
        fi
    done

}

# Invocamos ("callback") las funciones "undo" asociadas a las opciones 
# NO seleccionadas por el usuario (las descartadas)
# ---

function procesarAccionesDescartadas {

    # Dividimos (el separador es "|" ) las opciones seleccionadas por el usuario
    # ---

    IFS="|" read -a vals <<< $1

    # Solicitamos (una a una) que se procesen dichas opciones

    for i in "${vals[@]}"
    do
        aux=$(ejecutarAccionOpcional $i"Check")
        if [[ $aux == "True" ]]; then
            echo "Ejecutamos "$i"Undo()"
            [[ $DEBUG != 'y' ]] && ejecutarAccionOpcional $i"Undo" || echo "No se ejecuta "$i"Undo() por estar en modo DEBUG"
        fi
    done

}

# Concatena el contenido de un array usando el delimitador proporcionado
# ---

function join { 
    local IFS="$1"; 
    shift; 
    echo "$*"; 
}

# Listamos opciones no elegidas
# ---

function getOpcionesDescartadas {

    # Preparamos las variables a usar
    # ---

    elegidos=$2
    opciones=$1

    rsdo=()

    # Procesamos los lotes de opciones
    # ---

    # Mientras queden lotes "de 3" elementos en el array

    while [ ${#opciones[@]} -ge 3 ]
    do
        
        # Obtenemos la nueva fila de valores

        row=( ${opciones[@]:0:3} )

        # Comprobamos si la opción no ha sido elegida

        valor=${row[@]:1:1}

        # Si no ha sido elegida, la añadimos a la lista

        if [[ "$elegidos" != *"$valor"* ]]; then
            rsdo=( "${rsdo[@]}" $valor )
        fi

        # Eliminamos la fila procesada

        opciones=( "${opciones[@]:3}" )

    done

    # Devolvemos como resultado la lista de funciones no seleccionadas
    # ---

    aux=$(join \| ${rsdo[@]})
    echo $aux

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

descargarCustomizeMinino(){
    
    versionActual=$(getLatestRelease)
    wget -q "https://raw.githubusercontent.com/$REPO_GITHUB/$versionActual/customize/customize-minino.sh" -O /tmp/new2.sh
}


#==============================================================================
# Actualizamos el script actualmente en ejecución y lo volvemos a invocar 
# tras ser actualizado para que se ejecute la nueva versión del mismo
#==============================================================================

selfUpdate(){

	echo "Procedemos a actualizar customize-minino.sh..."

    # Si no hemos descargado previamente el fichero (o alguien lo ha borrado)
    # nos hacemos con una copia actualizada de customize-minino.sh

    [[ -f /tmp/new2.sh ]] || descargarCustomizeMinino

    # Sustituimos el script actual por la nueva versión

    sudo cp /tmp/new2.sh "$0"
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

	descargarCustomizeMinino

	# Calculamos los hash de este script y del descargado
	#---

	hashActual=$(md5sum  "$0" | cut -d" " -f1)
	hashNuevo=$(md5sum  /tmp/new2.sh | cut -d" " -f1)

	# Comprobamos si el script está (o no) actualizado
	#---

   [ $hashActual = $hashNuevo ] && echo "True" || echo "False"
}

# -----------------------------------------------------------------------------
# Comprueba si hay conexión a Internet
# -----------------------------------------------------------------------------

function isConnectionAvailable {
    echo -e "GET http://google.com HTTP/1.0\n\n" | nc google.com 80 > /dev/null 2>&1 && echo "True" || echo "False"
}

# -----------------------------------------------------------------------------
# Cuerpo del script...
# -----------------------------------------------------------------------------

# Evitamos colisiones con otros scripts
# ---

rm -f /tmp/new2.sh

# Comprobamos si hay internet
# ---

aux=$(isConnectionAvailable)

if [[ $aux == "False" ]]; then
	zenity \
        --warning \
        --title "Sin conexión a Internet" \
        --text "Necesitamos conexión a Internet para poder utilizar la mayoría de opciones de 'customize-minino'\nPor favor revisa tu conexión y vuelve a lanzar el script cuando vuelva a estar disponible.\nGracias"
        
    exit 1;
fi 

# Comprobamos si existe una versión más "moderna" de customize-minino.sh
# ---

aux=$(isUpdated)

if [[ $aux == "False" ]]; then
	zenity --question  --text "Existe una nueva versión de CUSTOMIZE-MININO.\n¿Desea que me actualice para disfrutar de las nuevas opciones que ofrece?"
    if [[ $? = 0 ]]; then
        selfUpdate;
    fi
fi 

# Permitimos seleccionar opciones personalizadas
# ---

# Preparamos la lista de opciones a mostrar

opciones=("${opciones[@]}" `activarAutoLoginCheck` activarAutoLogin "Inicio de sesión automático")
opciones=("${opciones[@]}" `controlPresenciaCheck` controlPresencia "Control Presencia Séneca")
opciones=("${opciones[@]}" `qshutdownCheck` qshutdown "Apagado automático")
opciones=("${opciones[@]}" `navegacionPrivadaCheck` navegacionPrivada "Navegación web en modo incógnito por defecto")
opciones=("${opciones[@]}" `accesoSSHCheck` accesoSSH "Permitir conexión por SSH")
opciones=("${opciones[@]}" `instalarSigalaCheck` instalarSigala "Instalar HGR-Sigala")
opciones=("${opciones[@]}" `soundProblemCheck` soundProblem "Corregir audio NB500/N100SP")
opciones=("${opciones[@]}" `cga-brilloCheck` cga-brillo "Control de brillo en portátiles")

# Mostramos las opciones personalizables

opc=$( \
    zenity \
        --list \
        --title="Elija las personalizaciones que desea aplicar" \
        --checklist \
        --column="Aplicar" \
        --column="funcionAEjecutar" \
        --column="Descripción" \
        --hide-column=2 \
        --width=550 \
        --height=300 \
   "${opciones[@]}" \
)

# Comprobamos que no se pulse el botón Cancelar

if [[ "$?" != 0 ]]; then
    echo "Sin problemas, ya personalizaremos Minino otro día ;)"
    exit 0
fi

# Calculamos las opciones que ha desmarcado el usuario

descartado=$(getOpcionesDescartadas $opciones[@] $opc)

# Procesamos las opciones elegidas por el usuario
# ---

sudo apt update

procesarAccionesSeleccionadas $opc
procesarAccionesDescartadas $descartado
