#!/bin/bash
if [ "${EUID}" -ne 0 ]; then
		echo "You need to run this script as root"
		exit 1
fi

# xray service
aa="https://raw.githubusercontent.com/fisabiliyusri/mantapv2/main/data-xray.sh"
# 
#installing script
wget ${aa} && chmod +x data-xray.sh && ./data-xray.sh
clear

#
#echo "Installation Success! Rebooting..."
#sleep 3
#reboot
# clear installation files (soon)
# rm -r *.sh
