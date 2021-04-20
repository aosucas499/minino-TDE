#! /bin/bash

function controlPresencia {
	# Si existe el perfil principal, continuamos con el script, en caso contrario 
	# abrimos y cerramos firefox, ya que necesitamos que se abra para la creación de la carpeta del perfil de usuario
	# en este caso informamos al usuario de que vuelva a ejecutar la instalación y cierre firefox
	
	if [! -d "/home/$USER/.mozilla/firefox/*1"]; then
			zenity --error --text "Es la primera vez que se ejecuta firefox, ciérrelo cuando se abra y vuelva a ejecutar esta instalación"
			/usr/lib/firefox-latest/firefox -setDefaultBrowser --no-default-browser-check
			exit
		else	
			echo "Existe perfil principal de firefox"
		fi
	
	# Borramos del archivo de configuración de firefox la pantalla de bienvenida que se ejecuta la primera vez
	# Se hace añadiendo esta línea al archivo de configuración
	sed -i '$ i\user_pref("browser.startup.homepage", "https://seneca.juntadeandalucia.es/controldepresencia/");' ~/.mozilla/firefox/*.default-release-1/prefs.js
	
    	# Establecemos como página principal la web del control de presencia de Séneca 
    	sed -i '$ i\user_pref("trailhead.firstrun.didSeeAboutWelcome", true);' ~/.mozilla/firefox/*.default-release-1/prefs.js
	
	# Descargamos y copiamos el ejecutable de firefox en modo kiosk que se ejecutará en cada inicio  
	# con un retardo para que le dé tiempo al script ntp de corregir la hora
	wget https://raw.githubusercontent.com/aosucas499/minino-TDE/main/tools/Firefox-latest-sleep30
    	sudo cp Firefox-latest-sleep30 /etc/xdg/autostart/Firefox-latest-sleep30.desktop
    
}

controlPresencia
