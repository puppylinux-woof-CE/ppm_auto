#!/bin/sh
[ ! -f /usr/share/pixmaps/puppy/building_block.svg ] &&\
Xdialog --yesno "You need to install libstardust from\n http://www.murga-linux.com/puppy/viewtopic.php?p=815876#815876 \nfor the new PPM to run properly.\nDo you want to download this pet now?" 0 0 
[ $? -eq 0 ] &&\
defaultbrowser http://www.murga-linux.com/puppy/viewtopic.php?p=815876#815876 &
