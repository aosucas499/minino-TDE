#!/bin/bash

# =============================================================================
# Script para ejecutar en la iso y dar opción a añadir mejoras.
# =============================================================================

# -----------------------------------------------------------------------------
# Configuración del script
# -----------------------------------------------------------------------------

# Constante que impide que se ejecuten las opciones elegidas

readonly DEBUG='n'

# -----------------------------------------------------------------------------
# Definición de las funciones utilizadas en el script
# -----------------------------------------------------------------------------

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
	
    version=$(wget --quiet -O- -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/aosucas499/minino-TDE/releases | grep '"tag_name":' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
    
    # NOTA  a pesar de la polémica main/master, a día de hoy Github 
    #       redirecciona sin problemas usemos la que usemos 

    [ -z $version ] && echo "main" || echo $version
}

#==============================================================================
# Obtiene de Github la versión más reciente de customize-minino-sh
#==============================================================================

descargarCustomizeMinino(){
    versionActual=$(getLatestRelease)
    wget -q "https://raw.githubusercontent.com/aosucas499/minino-TDE/$versionActual/customize/customize-minino.sh" -O /tmp/new.sh
}

#==============================================================================
# Actualizamos el script actualmente en ejecución y lo volvemos a invocar 
# tras ser actualizado para que se ejecute la nueva versión del mismo
#==============================================================================

selfUpdate(){

	echo "Procedemos a actualizar customize-minino.sh..."

    # Si no hemos descargado previamente el fichero (o alguien lo ha borrado)
    # nos hacemos con una copia actualizada de customize-minino.sh

    [[ -f /tmp/new.sh ]] || descargarCustomizeMinino

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

	descargarCustomizeMinino

	# Calculamos los hash de este script y del descargado
	#---

	hashActual=$(md5sum  "$0" | cut -d" " -f1)
	hashNuevo=$(md5sum  /tmp/new.sh | cut -d" " -f1)

	# Comprobamos si el script está (o no) actualizado
	#---

   [ $hashActual = $hashNuevo ] && echo "True" || echo "False"
}

# -----------------------------------------------------------------------------
# Cuerpo del script...
# -----------------------------------------------------------------------------

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
opciones=("${opciones[@]}" `navegacionPrivadaCheck` navegacionPrivada "Navegación web en modo incógnito por defecto")
opciones=("${opciones[@]}" `accesoSSHCheck` accesoSSH "Permitir conexión por SSH")
opciones=("${opciones[@]}" `instalarSigalaCheck` instalarSigala "Instalar HGR-Sigala")
opciones=("${opciones[@]}" `soundProblemCheck` soundProblem "Corregir audio NB500/N100SP")

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
        --width=500 \
        --height=250 \
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
