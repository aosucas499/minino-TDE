#!/bin/sh

F0="centros.edu.guadalinex.org/Edu"
NEW_HOSTNAME="guadalinexedu"

##############################################
# Detecta el portatil toshiba y añade la opción del modelo en cga-mod-conf
#CGA_MOD_CONF="/target/etc/modprobe.d/cga-mod-conf"
#CADENA="options snd-hda-intel model=toshiba"
#[ -z "$(/usr/bin/lspci -v | /bin/grep -i toshiba)" ] || echo $CADENA >> $CGA_MOD_CONF

##############################################
# Detecta si el equipo tiene una tarjeta de video nvidia y la configura
if [ ! -z "$(/usr/bin/lspci -v | /bin/grep -i vga | /bin/grep -i nvidia)" ]
then
	/bin/sh /bin/in-target /usr/bin/apt-get install -y -f nvidia-glx-173 nvidia-173
fi

##############################################
# Detecta si el equipo tiene una tarjeta de video Intel 82865G y la configura
#if [ ! -z "$(/usr/bin/lspci -v | /bin/grep -i vga | /bin/grep -i 82865G)" ]  
#then                                                                         
#        /bin/sh /bin/in-target /usr/bin/apt-get install -y -f xserver-xorg-video-intel-2.4
#fi

##############################################
# Detecta si el equipo tiene una tarjeta de red Atheros AR8152 v1.1 Fast Ethernet
if [ ! -z "$(/usr/bin/lspci -v | /bin/grep -i ethernet | /bin/grep -i AR8151)" ]  
then                                                                         
        #/bin/sh /bin/in-target /usr/bin/apt-get install -y -f linux-backports-modules-wireless-lucid-generic
        /bin/sh /bin/in-target /usr/bin/apt-get install -y -f cga-acer-ar8152-ethernet-module
fi

##############################################
# Detecta si el equipo tiene una tarjeta de red Atheros AR8151 Fast Ethernet
if [ ! -z "$(/usr/bin/lspci -v | /bin/grep -i ethernet | /bin/grep -i AR8152)" ]  
then                                                                         
        #/bin/sh /bin/in-target /usr/bin/apt-get install -y -f linux-backports-modules-wireless-lucid-generic
        /bin/sh /bin/in-target /usr/bin/apt-get install -y -f cga-acer-ar8152-ethernet-module
fi

##############################################
# Detecta si el equipo tiene una tarjeta de red Atheros AR8162 Fast Ethernet
# Toshiba NB510
if [ ! -z "$(/usr/bin/lspci -d 1969:1090)" ]  
then                                                                         
        /bin/sh /bin/in-target /usr/bin/apt-get install -y -f cga-compat-wireless-alx
fi

##############################################
# Detecta si el equipo tiene la tarjeta de sonido intel en toshiba NB200
if [ ! -z "$(/usr/bin/lspci -vvv -nn | /bin/grep -i '1179:ff6e')" ]  
then                                                                         
        /bin/sh /bin/in-target /usr/bin/apt-get install -y -f cga-toshiba-nb200-sound-config
fi

##############################################
# Instalacion del paquete cga-update-grub2
/bin/sh /bin/in-target /usr/bin/apt-get install -y -f cga-update-grub2


##############################################
# Ejecuta los scripts de cga-security para eliminar al usuario "usuario" del grupo admin
# y restablecer la contraseña del usuario "usuario"
/bin/sh /bin/in-target /usr/sbin/password_users.sh

# Actualiza el grub para que muestre el splash y los nombres correctos
#/bin/sh /bin/in-target /etc/init.d/guadalinexedu-artwork stop

##############################################
# Actualizar los updates alternatives para sun jdk
/bin/sh /bin/in-target /usr/sbin/update-java-alternatives -s java-6-sun 2>/dev/null

##############################################
# Limpia los paquetes que se descargan durante la instalacion
/bin/sh /bin/in-target /usr/bin/apt-get clean
/bin/sh /bin/in-target /usr/bin/apt-get --purge -f -y --force-yes autoremove

##############################################
# Desinstalando paquetes no necesarios
/bin/sh /bin/in-target /usr/bin/apt-get --purge remove -y -f transmission-common transmission-gtk ubuntuone-client ubuntuone-client-gnome python-ubuntuone-storageprotocol python-ubuntuone-client python-protobuf rhythmbox-ubuntuone-music-store remmina apport apport-symptoms python-apport 
/bin/sh /bin/in-target /usr/bin/apt-get --purge -f -y autoremove
/bin/sh /bin/in-target /usr/bin/apt-get install -y -f gnome-session-fallback
/bin/sh /bin/in-target /usr/bin/apt-get install -y -f cga-sourceslist-config



##############################################
# Creando deposito de claves inseguro para usuario de autologin
#if [ ! -z "$(/bin/sh /bin/in-target /usr/bin/dpkg -l | /bin/grep aula20)" ]
#then
#	/bin/sh /bin/in-target /bin/mkdir -p /target/home/usuario/.gnome2/keyrings/
#	echo "" > /target/home/usuario/.gnome2/keyrings/login.keyring
#	echo "[keyring]" >> /target/home/usuario/.gnome2/keyrings/login.keyring
#	echo "display-name=login" >> /target/home/usuario/.gnome2/keyrings/login.keyring
#	echo "ctime=0" >> /target/home/usuario/.gnome2/keyrings/login.keyring
#	echo "mtime=0" >> /target/home/usuario/.gnome2/keyrings/login.keyring
#	echo "lock-on-idle=false" >> /target/home/usuario/.gnome2/keyrings/login.keyring
#	echo "lock-after=false" >> /target/home/usuario/.gnome2/keyrings/login.keyring
#	/bin/sh /bin/in-target /bin/chown -R usuario:usuario /home/usuario/.gnome2/keyrings
#fi

/bin/sh /bin/in-target /usr/bin/glib-compile-schemas /usr/share/glib-2.0/schemas --targetdir=/usr/share/glib-2.0/schemas

##############################################
# Configura los sources de apt
echo "deb http://centros.edu.guadalinex.org/Edu/precise precise main" > /target/etc/apt/sources.list
echo "deb http://centros.edu.guadalinex.org/Edu/catcorner guadalinexedu main" >> /target/etc/apt/sources.list

##############################################
# Configura el hostname del sistema (solo para iso usb)
echo $NEW_HOSTNAME > /target/etc/hostname
sed  -i  -e '/127.0.1.1/d' -e '/127.0.0.1/a\127.0.1.1\	'$NEW_HOSTNAME /target/etc/hosts
