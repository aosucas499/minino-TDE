#! /bin/bash

firefoxConfigFile=/home/$USER/.mozilla/firefox/*1/prefs.js

if [ -d "$firefoxConfigFile" ]; then
	echo "existe $firefoxConfigFile"
else	
	echo "no existe $firefoxConfigFile"
fi
