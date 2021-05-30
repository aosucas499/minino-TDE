#!/bin/bash

# Borra el icono de la instalación en el escritorio
# en caso de que exista
	if [ -f "/home/$USER/Escritorio/minino-installer.desktop" ]; then
		rm -f /home/$USER/Escritorio/minino-installer.desktop
	else
	echo "Nada que borrar en el escritorio"
fi

#==============================================================================
# Comprueba si tiene permisos de sudo
#==============================================================================

hasSudoRights(){

	res=$(sudo -l | grep \(ALL | wc -l)

   [ $res -eq 1 ] && echo "True" || echo "False"
}

# -----------------------------------------------------------------------------
# Sólo permitimos que sea utilizado por usuarios con permisos de administración
# -----------------------------------------------------------------------------

[[ $(hasSudoRights) == "False" ]] && exit 0

# Entramos al proyecto
#
	#git clone https://github.com/aosucas499/minino-tde
	cd /home/$USER/minino-tde

# Copiamos customize-minino de la última release y cambiamos a una versión 
# previa/etiqueta del proyecto o no hará update-minino nada al comprobar que está actualizado
#
	sudo cp ./customize/customize-minino.sh /usr/bin/customize-minino
	git checkout tags/1.3.4
	sudo cp update-minino.sh /usr/bin/update-minino
	
# Procedemos a actualizar el sistema
# Pedirá contraseña root y habrá que aceptar el mensaje 
# de actualizar a la nueva versión
#	
	sudo update-minino	
	
# Creamos y copiamos los ficheros de configuración de la barra inferior de tareas,
# los iconos del escritorio y el fondo de pantalla tal como están en la versión rolling.
# De esta manera se quedan para cualquier usuario default, pensando en un cambio futuro
# del instalador.
#
	# Copiamos el fondo de escritorio TDE al predeterminado del sistema	
		sudo cp /home/$USER/Imágenes/logo_TDE.png /usr/local/share/backgrounds/170863-2.jpg

	# Creamos el fichero de la barra de tareas como la versión rolling y lo copiamos
	# como predeterminado del sistema.
		cat << EOF >> /tmp/bottom
# lxpanel <profile> config file. Manually editing is not recommended.
# Use preference dialog in lxpanel to adjust config when you can.

Global {
  edge=bottom
  allign=left
  margin=0
  widthtype=percent
  width=100
  height=26
  transparent=1
  tintcolor=#a4a4a4
  alpha=178
  autohide=0
  heightwhenhidden=2
  setdocktype=1
  setpartialstrut=1
  usefontcolor=0
  fontsize=10
  fontcolor=#ffffff
  usefontsize=0
  background=0
  backgroundfile=/usr/share/lxpanel/images/background.png
  iconsize=24
}
Plugin {
  type=menu
  Config {
    image=/usr/local/share/icons/minino-icon.png
    system {
    }
    separator {
    }
    item {
      image=applications-system
      command=run
    }
    separator {
    }
    item {
      image=gnome-logout
      command=logout
    }
  }
}
Plugin {
  type=space
  Config {
    Size=3
  }
}
Plugin {
  type=launchbar
  Config {
    Button {
      id=menu://applications/System/lxterminal.desktop
    }
    Button {
      id=pcmanfm.desktop
    }
    Button {
      id=menu://applications/Internet/firefox-latest.desktop
    }
    Button {
      id=menu://applications/Graphics/minino-screenshot.desktop
    }
    Button {
      id=menu://applications/Universal Access/florence.desktop
    }
  }
}
Plugin {
  type=space
  Config {
    Size=4
  }
}
Plugin {
  type=wincmd
  Config {
    image=desktop
    Button1=iconify
    Button2=shade
    Toggle=1
  }
}
Plugin {
  type=space
  Config {
    Size=4
  }
}
Plugin {
  type=pager
  Config {
  }
}
Plugin {
  type=space
  Config {
    Size=4
  }
}
Plugin {
  type=taskbar
  expand=1
  Config {
    tooltips=1
    IconsOnly=0
    ShowAllDesks=0
    UseMouseWheel=1
    UseUrgencyHint=1
    FlatButton=0
    MaxTaskWidth=150
    spacing=1
    GroupedTasks=0
  }
}
Plugin {
  type=monitors
  Config {
    DisplayCPU=1
    DisplayRAM=1
    CPUColor=#0000FF
    RAMColor=#FF0000
  }
}
Plugin {
  type=batt
  Config {
    HideIfNoBattery=0
    AlarmCommand=minino-xmsglowbatt
    AlarmTime=5
    BackgroundColor=black
    BorderWidth=1
    ChargingColor1=#28f200
    ChargingColor2=#22cc00
    DischargingColor1=#ffee00
    DischargingColor2=#d9ca00
    Size=20
    ShowExtendedInformation=0
  }
}
Plugin {
  type=tray
  Config {
  }
}
Plugin {
  type=launchbar
  Config {
    Button {
      id=/usr/local/share/applications/minino/minino-keyboard.desktop
    }
  }
}
Plugin {
  type=volumealsa
  Config {
  }
}
Plugin {
  type=dclock
  Config {
    ClockFmt=%R
    TooltipFmt=%A %x
    BoldFont=1
    IconOnly=0
    CenterText=0
  }
}
Plugin {
  type=launchbar
  Config {
    Button {
      id=lxde-logout.desktop
    }
  }
}
EOF

		sudo cp /tmp/bottom /etc/skel/.config/lxpanel/LXDE/panels
		mv /tmp/bottom /home/$USER/.config/lxpanel/LXDE/panels

	# Creamos el fichero de los iconos del escritorio de la versión rolling y lo copiamos
	# como predeterminado del sistema.

		cat << EOF >> /tmp/desktop-items-1.conf
[*]
wallpaper_mode=center
wallpaper_common=1
wallpaper=/usr/local/share/backgrounds/170863-2.jpg
desktop_bg=#ffffff
desktop_fg=#0c0507
desktop_shadow=#ffffff
desktop_font=Arial 10
show_wm_menu=0
sort=mtime;ascending;
show_documents=1
show_trash=1
show_mounts=1

[firefox-latest.desktop]
x=24
y=181

[customize-minino.desktop]
x=14
y=466

[system-config-printer.desktop]
x=594
y=96

[firefox-esr.desktop]
x=18
y=279

[Chromium con flash]
x=12
y=368

[tuxpaint.desktop]
x=429
y=579

[tuxmath.desktop]
x=533
y=574

[gcompris.desktop]
x=641
y=577

[childsplay.desktop]
x=323
y=579

[libreoffice-impress.desktop]
x=483
y=96

[libreoffice-writer.desktop]
x=371
y=92

[Documentos]
x=20
y=92

[trash:///]
x=15
y=2
EOF
		
		sudo cp /tmp/desktop-items-1.conf /etc/skel/.config/pcmanfm/LXDE
		mv /tmp/desktop-items-1.conf /home/$USER/.config/pcmanfm/LXDE/desktop-items-0.conf

# Borramos la carpeta del proyecto
#
	sudo rm -r /home/$USER/minino-tde

# Reiniciamos el sistema
# 
	echo ""
	echo "Se va a reiniciar el sistema"
	echo ""
	echo "Si quiere evitarlo, pulse las teclas Control y c"
	echo ""
	sleep 9
	sudo reboot

