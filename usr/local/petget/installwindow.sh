#!/bin/bash

#[ -f /tmp/install_pets_quietly ] && set -x ; mkdir -p /tmp/PPM_LOGs ; NAME=$(basename "$0"); exec 1>> /tmp/PPM_LOGs/"$NAME".log 2>&1


#############
# Do not allow a second instance, or simultabeous removal
#[ -f /tmp/remove_pets_quietly -o -f /tmp/install_pets_quietly ] && exit 0
#############

# close older window. Must be a better way...
OLD_DIALOG=$(ps | grep INSTALL_PETS_DIALOG | grep program | cut -f 1-2 -d ' ')
kill -9 $OLD_DIALOG

export TEXTDOMAIN=petget__installwindow.sh
export OUTPUT_CHARSET=UTF-8

[ "`whoami`" != "root" ] && exec sudo -A ${0} ${@} #110505

clean_up () {
 rm -f /tmp/pkgs_to_install
 rm -f /tmp/{install,remove}_pets_quietly
 rm -f /tmp/download_pets_quietly
 rm -f /tmp/download_only_pet_quietly
 rm -f /tmp/pkgs_left_to_install
 rm -f /tmp/pkgs_to_install_done
 rm -f /tmp/.auto_flag
 rm -f /tmp/overall_pkg_size
 rm -rf /tmp/PPM_LOGs/
}
export -f clean_up

check_total_size () {
# cat /tmp/pkgs_to_install
# echo $(cat /tmp/pkgs_to_install)
 while read LINE; do
# for LINE in $(cat /tmp/pkgs_to_install)
# do 
  REPO=$(echo $LINE | cut -f 4 -d '|') 
  echo "$REPO" > /tmp/petget/current-repo-triad
  TREE1=$(echo $LINE | cut -f 1 -d '|')
  /usr/local/petget/installed_size_preview.sh
 done < /tmp/pkgs_to_install
 #---
 rm -f /tmp/petget_deps_visualtreelog
 rm -f /tmp/petget_frame_cnt
 rm -f /tmp/petget_missingpkgs_patterns{2,_acc,_acc0,_acc-prev,x0,_and_versioning_level1}
 rm -f /tmp/petget_moreframes 
 rm -f /tmp/petget_tabs
 #---
 NEEDEDK=$( expr $(awk '{ sum += $1 } END { print sum }' /tmp/overall_pkg_size) / 1024 )
 AVAILABLE=$(cat /tmp/pup_event_sizefreem | head -n 1 )
 PACKAGES=$(cat /tmp/pkgs_to_install | cut -f 1 -d '|')
 #statusbar in main gui
 PERCENT=$((${NEEDEDK}*100/${AVAILABLE}))
 [ $PERCENT -gt 99 ] && PERCENT=99 
 if [ -s /tmp/overall_pkg_size ] && [ $PERCENT = 0 ]; then PERCENT=1; fi
 echo "$PERCENT" > /tmp/petget/install_status_percent
 echo "$(gettext 'Packages (with libs)'): $(($(grep -c "|" /tmp/petget_missingpkgs_patterns)+$(grep -c "[0-9]" /tmp/overall_pkg_size)))    -   $(gettext 'Required space'): ${NEEDEDK}Mb   -   $(gettext 'Available'): ${AVAILABLE}Mb" > /tmp/petget/install_status
 #---
 rm -f /tmp/overall_pkg_size
 if [ "$NEEDEDK" -ge "$AVAILABLE" ]; then
  /usr/lib/gtkdialog/box_ok "$(gettext 'Space needed')" error "$(gettext 'The ') $AVAILABLE $(gettext ' MB of available space is not sufficient to download the')" "$PACKAGES" "$(gettext 'package(s) you selected. Please resize your savefile or delete some files.')" &
#  clean_up
  exit 0
 fi
}
export -f check_total_size

install_package () {
 [ "$(cat /tmp/pkgs_to_install)" = "" ] && exit 0
 # Check input
 if [ "$TREE1" != "" ]; then
  if [ "$(grep $TREE1 /tmp/pkgs_to_install)" = "" ]; then
   echo "$TREE1"\|"$(cat /tmp/petget/current-repo-triad)" >> /tmp/pkgs_to_install
  fi
 else
  exit 1
 fi
 #---
 if [ -f /tmp/install_pets_quietly ]; then
  yaf-splash -close never -bg orange -text "$(gettext 'Please wait, calculating total required space for the installation...')" &
  X1PID=$!
  check_total_size
  cat /tmp/pkgs_to_install | tr ' ' '\n' > /tmp/pkgs_left_to_install
  kill -9 $X1PID
#  cat /tmp/pkgs_to_install
#  echo $(cat /tmp/pkgs_to_install)
  COUNT=0
  while read LINE; do
#  for LINE in $(cat /tmp/pkgs_to_install)
#  do
   REPO=$(echo $LINE | cut -f 2 -d '|')
   echo "$REPO" > /tmp/petget/current-repo-triad
   TREE1=$(echo $LINE | cut -f 1 -d '|')
   rxvt -title "$VTTITLE... Do NOT close" \
   -fn -misc-fixed-medium-r-semicondensed--13-120-75-75-c-60-*-* -bg black \
   -fg grey -geometry 80x5+50+50 -e /usr/local/petget/installpreview.sh
   #for progressbar in main gui
   COUNT=$(($COUNT+1))
   PERCENT=$(($COUNT*100/$(grep -c "^" /tmp/pkgs_to_install)))
   [ $PERCENT = 100 ] && PERCENT=99
   echo $PERCENT > /tmp/petget/install_status_percent
   #---
   /usr/local/petget/finduserinstalledpkgs.sh
   sed -i "/$TREE1/d" /tmp/pkgs_left_to_install
  done < /tmp/pkgs_to_install
 else
  /usr/local/petget/installpreview.sh
  /usr/local/petget/finduserinstalledpkgs.sh
  sed -i "/$TREE1/d" /tmp/pkgs_left_to_install
 fi
 sync
 /usr/local/petget/reportwindow.sh
 clean_up
 echo 100 > /tmp/petget/install_status_percent
}
export -f install_package

install_all () {
 rm -f /tmp/install_pets_quietly
 rm -f /tmp/download_pets_quietly 2>/dev/null
 rm -f /tmp/download_only_pet_quietly 2>/dev/null
 rm -f /tmp/.auto_flag 2>/dev/null
 touch /tmp/install_pets_quietly
 cp -a /tmp/pkgs_to_install /tmp/pkgs_to_install_done
 VTTITLE=Installing
 export VTTITLE
 install_package
 unset VTTITLE
}	
export -f install_all

download_only () {
 rm -f /tmp/install_pets_quietly
 rm -f /tmp/download_pets_quietly 2>/dev/null
 rm -f /tmp/download_only_pet_quietly 2>/dev/null
 rm -f /tmp/.auto_flag 2>/dev/null
 touch /tmp/install_pets_quietly
 touch /tmp/download_only_pet_quietly 
 cp -a /tmp/pkgs_to_install /tmp/pkgs_to_install_done
 VTTITLE=Downloading
 export VTTITLE
 install_package
 unset VTTITLE
}	
export -f download_only

download_all () {
 rm -f /tmp/install_pets_quietly
 rm -f /tmp/download_pets_quietly 2>/dev/null
 rm -f /tmp/download_only_pet_quietly 2>/dev/null
 rm -f /tmp/.auto_flag 2>/dev/null
 touch /tmp/install_pets_quietly
 touch /tmp/download_pets_quietly 
 cp -a /tmp/pkgs_to_install /tmp/pkgs_to_install_done
 VTTITLE=Downloading
 export VTTITLE
 install_package
 unset VTTITLE	
}	
export -f download_all

clasic_mode () {
 rm -f /tmp/install_pets_quietly
 rm -f /tmp/download_pets_quietly 2>/dev/null
 rm -f /tmp/download_only_pet_quietly 2>/dev/null
 rm -f /tmp/.auto_flag 2>/dev/null
 install_package
}
export -f clasic_mode

delete_in_entry () {
 sed -i "/$TREE2/d" /tmp/pkgs_to_install
}
export -f delete_in_entry

case "$1" in
	check_total_size)
		echo 0 > /tmp/petget/install_status_percent
		echo "$(gettext "Calculating required space...")" > /tmp/petget/install_status
		touch /tmp/install_pets_quietly #avoid splashes
		check_total_size
		rm /tmp/install_pets_quietly
		;;
	"$(gettext 'Auto install')") install_all;;
	"$(gettext 'Download packages (no install)')") download_only;;
	"$(gettext 'Download all (packages and dependencies)')") download_all;;
	"$(gettext 'Step by step installation (classic mode)')") clasic_mode;;
	*)
		export INSTALL_PETS_DIALOG='<window title="'$(gettext 'Install Puppy Packages')'" icon-name="gtk-about" default_height="400" default_width="400">
		 <vbox>
		  <text><label>'$(gettext 'Packages to be installed are listed below.')'</label></text>
		  <text><label>'$(gettext 'Remove a package from the list by selecting it. ')'</label></text>  
		  <tree column-resizeable="false">
			<label>'$(gettext 'Packages to install')'</label>
			<variable>TREE2</variable>    
			<input>cat /tmp/pkgs_to_install</input>
			<action>delete_in_entry</action>
			<action>refresh:TREE2</action>
			<action signal="button-release-event">delete_in_entry</action>
			<action signal="button-release-event">refresh:TREE2</action>
		  </tree>
		  
		  <text space-fill="true"><label>'$(gettext 'PPM now Supports Unattended Multiple Package Installation or Download (faster).')'</label></text> 
		  <text space-fill="true"><label>'$(gettext 'The  'classic' PPM mode is also availabe (slower)')'</label></text>
		  
		  <text xalign="0" space-fill="false" use-markup="true">
		   <label>"'$(gettext '<b>Install:</b>Auto-Install Packages and Dependencies')'"</label></text>
		  <text xalign="0" space-fill="false" use-markup="true">
		   <label>"'$(gettext '<b>Download Pkgs:</b>Auto-Download Packages. No Dependencies')'"</label></text>
		  <text xalign="0" space-fill="false" use-markup="true">
		   <label>"'$(gettext '<b>Download All:</b>Auto-Download Packages and Dependencies')'"</label></text>
		  <text xalign="0" space-fill="false" use-markup="true">
		   <label>"'$(gettext '<b>Classic Mode:</b>Works step-by-step on User Prompts')'"</label></text>
		  
		  <hbox space-fill="true">
		  <button>
		   <label>'$(gettext 'Classic mode')'</label>
		   <action>clasic_mode &</action>
		   <action type="exit">echo exiting</action>
		  </button> 
		  <button>
		   <label>'$(gettext 'Download All')'</label>
		   <action>download_all &</action>
		   <action type="exit">echo exiting</action>
		  </button>
		  <button>
		   <label>'$(gettext 'Download Pkgs')'</label>
		   <action>download_only &</action>
		   <action type="exit">echo exiting</action>
		  </button>
		  <button>
		   <label>'$(gettext 'Install')'</label>
		   <action>install_all &</action>
		   <action type="exit">echo exiting</action>
		  </button> 
		  <button>
		   <label>'$(gettext 'Cancel')'</label>
		   <action>clean_up</action>
		   <action type="exit">echo exiting</action> 
		  </button>
		  </hbox>
		  </vbox>
		</window>' 
		gtkdialog --program=INSTALL_PETS_DIALOG
		;;
esac
