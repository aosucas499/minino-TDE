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
	wget https://raw.githubusercontent.com/aosucas499/minino-TDE/main/tools/Firefox-latest-sleep30
    	sudo mv Firefox-latest-sleep30 /etc/xdg/autostart/Firefox-latest-sleep30.desktop

	## Informa al usuario de varios aspectos a tener en cuenta
	#---
	zenity --info --text="El control de presencia de Séneca se encuentra instalado en el sistema. Reinicie el sistema para que los cambios tengan efecto."
	zenity --info --text="Recuerde que el navegador tardará unos 40 segundo en iniciarse en cada inicio."
	
	## Activa el autologin para el usuario "usuario"
	# ---
	activarAutoLogin 
}

# Desactiva el control de presencia de Séneca en cada inicio
# ---

function controlPresenciaUndo {
    activarAutoLoginUndo
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

