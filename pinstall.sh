#!/bin/sh
if [ ! -f /usr/share/pixmaps/puppy/building_block.svg ]; then
	Xdialog --yesno "You need to install libstardust pet\nfor the new PPM to run properly.\n\nPlease uninstall this pet.\nInstall the libstardust pet\n and then install the ppm_auto pet again.\n\nDo you want to download the libstardust now?" 0 0 
	[ $? -eq 0 ]
	defaultbrowser http://www.murga-linux.com/puppy/viewtopic.php?p=815876#815876 &
else
	rm -f /usr/local/peteget/ui_Ziggy
	echo Ziggy > /var/local/petget/ui_choice
fi
