#!/bin/bash

sudo cp ./ntp/fix-ntp /usr/bin
sudo chmod +x /usr/bin/fix-ntp
sudo chown root:root ./ntp/zz-fix-ntp
sudo chmod 0440 ./ntp/zz-fix-ntp
sudo cp ./ntp/zz-fix-ntp /etc/sudoers.d/ 
sudo cp ./ntp/fix-ntp.desktop /etc/xdg/autostart/
