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

	sudo apt install -y ssh python-avahi python-qt4 python-qt4-dbus python-netifaces python-sleekxmpp python-webdav x11vnc xtightvncviewer xvnc4viewer vlc ejabberd curl libc-ares2 rlwrap avahi-daemon setcd python-dnspython libnss-myhostname

	# Descargamos los paquetes de Guadalinex que necesitamos
	# ---

	wget http://centros.edu.guadalinex.org/Edu/fenix/pool/main/d/dex/dex_0.7-2_all.deb -O /tmp/dex_0.7-2_all.deb
	wget http://centros.edu.guadalinex.org/Edu/fenix/pool/main/e/ejabberd-cgaconfig/ejabberd-cgaconfig_0.2-3_all.deb -O /tmp/ejabberd-cgaconfig_0.2-3_all.deb
	wget http://centros.edu.guadalinex.org/Edu/fenix/pool/main/e/etherpad-lite/etherpad-lite_1.5.7-5_all.deb -O /tmp/etherpad-lite_1.5.7-5_all.deb
	wget http://centros.edu.guadalinex.org/Edu/fenix/pool/main/n/nodejs/nodejs_0.10.37-1_i386.deb -O /tmp/nodejs_0.10.37-1_i386.deb
	wget http://centros.edu.guadalinex.org/Edu/fenix/pool/main/c/cga-hga/cga-hga_0.1-19_all.deb -O /tmp/cga-hga_0.1-19_all.deb
	wget http://centros.edu.guadalinex.org/Edu/fenix/pool/main/p/python-sleekxmpp/python-sleekxmpp_1.3.1-6cga1_all.deb -O /tmp/python-sleekxmpp_1.3.1-6cga1_all.deb

	# Instalamos los paquetes de Guadalinex
	# ---

	sudo dpkg -i /tmp/dex_0.7-2_all.deb 
	sudo dpkg -i /tmp/ejabberd-cgaconfig_0.2-3_all.deb 
	sudo dpkg -i /tmp/nodejs_0.10.37-1_i386.deb 
	sudo dpkg -i /tmp/etherpad-lite_1.5.7-5_all.deb
	sudo dpkg -i /tmp/cga-hga_0.1-19_all.deb
	sudo dpkg -i /tmp/python-sleekxmpp_1.3.1-6cga1_all.deb

	# Aplicamos parche corrige encoding al compartir ficheros
	# ---

    # TODO  pasar el patch como EOF y evitar el fichero tools/sigala-install.patch 
    #       para que funcionen las actualizaciones automáticas actualmente (hasta que
    #       no hagamos un "git pull" no podemos depender de ficheros adicionales)

	sudo patch /usr/lib/python2.7/dist-packages/hga/controlcompartir/cliente/davclient.py ./tools/sigala-install.patch
	
	# Borramos acceso directo (cambiamos el nombre) del menú de aplicaciones hasta que resolvamos el funcionamiento de cga-hga-server
	# ---
	
	sudo mv /usr/share/applications/cga-hgr-server.desktop /usr/share/applications/cga-hgr-server.desktop.save
}

# Deshace la instalación de HGR-Sigala
# ---

function instalarSigalaUndo {

    # Se eliminan la mayoría de paquetes respetando aquellos (como curl o vnc) susceptibles de haber sido 
    # instalados por el usuario para otros usos

    sudo apt remove -y 
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
# Obtiene de Github la versión más reciente de customize-minino-sh
#==============================================================================

descargarCustomizeMinino(){
    wget -q https://raw.githubusercontent.com/aosucas499/minino-TDE/main/customize/customize-minino.sh -O /tmp/new.sh
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
# Cuerpo del script
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
