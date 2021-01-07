#!/bin/bash

#Borramos archivos innecesarios 
sudo rm ~/.local/share/applications/appimagekit-balena-etcher-electron.desktop
sudo rm -r /home/usuario/Descargas/*
sudo rm -r /home/Systemback

#Instalamos refracta que desinstala systemback
wget https://sourceforge.net/projects/refracta/files/tools/refractasnapshot-base_10.2.10_all.deb
sudo dpkg -i refractasnapshot*
sudo apt-get install -f -y

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
sudo sed -i -e '15,17 s/#//g' /usr/lib/refractainstaller/post-install/cleanup-install.sh
sudo sed -i '15,17 s/refractainstaller/minino-installer/g' /usr/lib/refractainstaller/post-install/cleanup-install.sh
sudo apt-get update -y

#borrar repo git
cd ~ && sudo rm -r minino*

echo "comandos para generar ISO"
echo "prev-mklive"
echo "sudo makelive"
