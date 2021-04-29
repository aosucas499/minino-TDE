#==============================================================================
# Gestión del autoapagado del sistema
#==============================================================================

# Instala la aplicación qshutdown y modifica el archivo de configuración teniendo en cuenta
# lo que conteste el usuario con el uso de zenit.
# ---

function qshutdownInstall {

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
	wget https://raw.githubusercontent.com/aosucas499/minino-TDE/main/tools/qshutdown.conf -O /home/$USER/.qshutdown/qshutdown.conf
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

qshutdownInstall
