#! /bin/bash

function controlPresencia {
    sed -i '$ i\user_pref("browser.startup.homepage", "https://seneca.juntadeandalucia.es/controldepresencia/");' ~/.mozilla/firefox/*.default-release-1/prefs.js
	wget https://raw.githubusercontent.com/aosucas499/minino-TDE/main/tools/Firefox-latest-sleep30
    sudo cp Firefox-latest-sleep30 /etc/xdg/autostart/Firefox-latest-sleep30.desktop
    
}

controlPresencia
