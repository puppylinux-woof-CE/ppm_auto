#!/bin/bash

export TEXTDOMAIN=petget__installwindow.sh
export OUTPUT_CHARSET=UTF-8

[ "`whoami`" != "root" ] && exec sudo -A ${0} ${@} #110505

if [ -f /root/.packages/download_path ]; then
 . /root/.packages/download_path
fi

clean_up () {
 if [ "$(ls /tmp/*_pet{,s}_quietly /tmp/install_classic 2>/dev/null |wc -l)" -eq 1 ]; then
  for MODE in $(ls /tmp/*_pet{,s}_quietly /tmp/install_classic)
  do
   mv $MODE $MODE.bak
  done
 fi
 mv /tmp/install_quietly /tmp/install_quietly.bak
 echo -n > /tmp/pkgs_to_install
 rm -f /tmp/{install,remove}{,_pets}_quietly 2>/dev/null
 rm -f /tmp/install_classic 2>/dev/null
 rm -f /tmp/download_pets_quietly 2>/dev/null
 rm -f /tmp/download_only_pet_quietly 2>/dev/null
 rm -f /tmp/pkgs_left_to_install 2>/dev/null
 rm -f /tmp/pkgs_to_install_done 2>/dev/null
 rm -f /tmp/overall_pkg_size* 2>/dev/null
 rm -f /tmp/overall_dependencies 2>/dev/null
 rm -f /tmp/mode_changed 2>/dev/null
 rm -f /tmp/force*_install 2>/dev/null
 rm -f /tmp/pkgs_to_install_done 2>/dev/null
 rm -f /tmp/pgks_really_installed 2>/dev/null
 rm -f /tmp/pgks_failed_to_install 2>/dev/null
 rm -f /tmp/overall_petget_missingpkgs_patterns.txt 2>/dev/null
 rm -f /tmp/overall_missing_libs.txt 2>/dev/null
 rm -f /tmp/overall_install_deport 2>/dev/null
 rm -f /tmp/pkgs_to_install_bar 2>/dev/null
 rm -rf /tmp/PPM_LOGs/ 2>/dev/null
 mv $MODE.bak $MODE
 mv /tmp/install_quietly.bak /tmp/install_quietly
}
export -f clean_up

check_total_size () {
 rm -f /tmp/petget_deps_visualtreelog 2>/dev/null
 rm -f /tmp/petget_frame_cnt 2>/dev/null
 rm -f /tmp/petget_missingpkgs_patterns{2,_acc,_acc0,_acc-prev,x0,_and_versioning_level1} 2>/dev/null
 rm -f /tmp/petget_moreframes 2>/dev/null
 rm -f /tmp/petget_tabs 2>/dev/null
 rm -f /tmp/pkgs_to_install_bar 2>/dev/null
 #required size
 NEEDEDK_PLUS=$( expr $(awk '{ sum += $1 } END { print sum }' /tmp/overall_pkg_size)) 
 [ -f /tmp/overall_pkg_size_RMV ] && \
  NEEDEDK_MINUS=$( expr $(awk '{ sum += $1 } END { print sum }' /tmp/overall_pkg_size_RMV)) \
  || NEEDEDK_MINUS=0
 [ ! "$NEEDEDK_MINUS" ] && NEEDEDK_MINUS=0
 NEEDEDK=$( expr $( expr $NEEDEDK_PLUS + $NEEDEDK_MINUS ) / 768 ) # 1.5x
 ACTION_MSG=$(gettext 'This is not enough space to download and install the packages (including dependencies) you have selected.')
 if [ -f /tmp/download_pets_quietly -o -f /tmp/download_only_pet_quietly ]; then
  NEEDEDK=$( expr $NEEDEDK / 3 ) # 0.5x
  ACTION_MSG=$(gettext 'This is not enough space to download the packages (including dependencies) you have selected.')
 fi
 if [ "$(cat /var/local/petget/nd_category)" = "true" ]; then
  NEEDEDKDOWN=$( expr $NEEDEDK / 3 )
 else
  NEEDEDKDOWN="$NEEDEDK" # so will not trigger warning
 fi
 #---
 [ ! -f /tmp/pup_event_sizefreem ] && echo "Free space estimation error. Exiting" \
	> /tmp/petget/install_status && \
	/usr/lib/gtkdialog/box_ok "$(gettext 'Pup_event_error')" error "$(gettext 'This is a rare pup_even error that fails to report the available free space. Just click on the free memory applet at the tray and try again. It should be OK after that.')" \
	&& clean_up && exit 1
 AVAILABLE=$(cat /tmp/pup_event_sizefreem | head -n 1 )
 if [ "$DL_PATH" != "/root" ]; then
  if [ -f /tmp/download_pets_quietly -o -f /tmp/download_only_pet_quietly \
   -o "$(cat /var/local/petget/nd_category)" = "true" ]; then
   SAVEAVAILABLE=$(df -m "$DL_PATH"| awk 'END {print $4}')
  else
   SAVEAVAILABLE="$AVAILABLE" # so will not trigger warning
  fi
 else
  SAVEAVAILABLE="$AVAILABLE" # so will not trigger warning
 fi
 if [ -f /tmp/download_pets_quietly -o -f /tmp/download_only_pet_quietly ]; then
  [ "$SAVEAVAILABLE" != "$AVAILABLE" ] && AVAILABLE="$SAVEAVAILABLE"
 fi
 PACKAGES=$(cat /tmp/pkgs_to_install | cut -f 1 -d '|')
 DEPENDENCIES=$(cat /tmp/overall_dependencies 2>/dev/null | sort | uniq)
 [ "$AVAILABLE" = "0" -o  "$AVAILABLE" = "" ] && echo "No space left on device. Exiting" \
	> /tmp/petget/install_status && clean_up && exit 0
 #statusbar in main gui
 PERCENT=$((${NEEDEDK}*100/${AVAILABLE}))
 [ $PERCENT -gt 99 ] && PERCENT=99
 if [ -s /tmp/overall_pkg_size ] && [ $PERCENT = 0 ]; then PERCENT=1; fi
 echo "$PERCENT" > /tmp/petget/install_status_percent
 if [ "$(cat /tmp/pkgs_to_install /tmp/overall_dependencies 2>/dev/null)" = "" ]; then
  echo "" > /tmp/petget/install_status
 else
  cat /tmp/pkgs_to_install | cut -f1 -d '|' > /tmp/pkgs_to_install_bar
  echo "$(gettext 'Packages (with deps)'): $(cat /tmp/pkgs_to_install_bar /tmp/overall_dependencies 2>/dev/null |sort | uniq | wc -l)    -   $(gettext 'Required space'): ${NEEDEDK}MB   -   $(gettext 'Available'): ${AVAILABLE}MB" > /tmp/petget/install_status
 fi
 #Check if enough space on system
 if [ "$NEEDEDK" -ge "$AVAILABLE" -o "$NEEDEDKDOWN" -ge "$SAVEAVAILABLE" ]; then
  export PPM_error='
  <window title="PPM - '$(gettext 'Space needed')'" icon-name="gtk-no">
  <vbox space-expand="true" space-fill="true">
    <frame '$(gettext 'Error')'>
      <hbox homogeneous="true">
        '"`/usr/lib/gtkdialog/xml_pixmap dialog-error.svg popup`"'
      </hbox>
      <hbox border-width="10" homogeneous="true">
        <vbox space-expand="true" space-fill="true">
          <text xalign="0" use-markup="true"><label>"'$(gettext 'Available space on your Puppy system is')' '${AVAILABLE}' MB. <b>'${ACTION_MSG}'</b> '$(gettext 'Please resize your savefile or delete some files.')'"</label></text>
          <vbox scrollable="true" shadow-type="0" height="150" width="350" space-expand="true" space-fill="true">
            <text xalign="0"><label>"'$PACKAGES'"</label></text>
            <text xalign="0"><label>"'$DEPENDENCIES'"</label></text>
          </vbox>
        </vbox>
       </hbox>
    </frame>
    <hbox space-expand="false" space-fill="false">
      <button>
        '"`/usr/lib/gtkdialog/xml_button-icon ok`"'
        <label>" '$(gettext 'Ok')' "</label>
      </button>
    </hbox>
  </vbox>
  </window>'
  gtkdialog --center -p PPM_error
  killall yaf-splash
  if [ ! -f /tmp/install_classic ]; then
   echo "" > /tmp/petget/install_status
   echo 0 > /tmp/petget/install_status_percent
   if [ "$(ls /tmp/*_pet{,s}_quietly /tmp/install_classic |wc -l)" -eq 1 ]; then
	for MODE in $(ls /tmp/*_pet{,s}_quietly /tmp/install_classic)
	do
	 mv $MODE $MODE.bak
	done
   fi
   clean_up
   mv $MODE.bak $MODE
  else
   . /usr/lib/gtkdialog/box_yesno "$(gettext 'Last warning')" "$NEEDEDK $(gettext 'of the ') $AVAILABLE $(gettext ' available MB will be used to install the package(s) you selected.')" "<b>$(gettext 'It is NOT sufficent. Please exit now.')</b>"  "$(gettext 'However, if you are sure about the spep-by-step process, take a risk.')" "$(gettext 'Do you want to cancel installation?')"
   if [ "$EXIT" = "yes" ]; then
    echo 0 > /tmp/petget/install_status_percent
    echo "" > /tmp/petget/install_status
    if [ "$(ls /tmp/*_pet{,s}_quietly /tmp/install_classic |wc -l)" -eq 1 ]; then
	 for MODE in $(ls /tmp/*_pet{,s}_quietly /tmp/install_classic)
	 do
	  mv $MODE $MODE.bak
	 done
    fi
    clean_up
    mv $MODE.bak $MODE
   else
    echo "good luck"
   fi
  fi
 fi
}
export -f check_total_size

status_bar_func () {
 while $1 ; do
  TOTALPKGS=$( expr 1 \+ $(cat /tmp/pkgs_to_install_bar /tmp/overall_dependencies 2>/dev/null |sort | uniq | wc -l))
  DONEPGKS=$(cat /tmp/overall_package_status_log 2>/dev/null | wc -l)
  PERCENT=$( expr $DONEPGKS \* 100 \/ $TOTALPKGS )
  [ $PERCENT = 100 ] && PERCENT=99
  echo $PERCENT > /tmp/petget/install_status_percent
  sleep 0.3
  [ "$(ps | grep reportwindow.sh | grep -v grep)" != "" ] && break
 done
}
export -f status_bar_func
 
install_package () {
 [ "$(cat /tmp/pkgs_to_install)" = "" ] && exit 0
 cat /tmp/pkgs_to_install | tr ' ' '\n' > /tmp/pkgs_left_to_install
 rm -f /tmp/overall_package_status_log
 echo 0 > /tmp/petget/install_status_percent
 echo "$(gettext "Calculating total required space...")" > /tmp/petget/install_status
 [ ! -f /root/.packages/skip_space_check ] && check_total_size
 status_bar_func &
 while read LINE; do
   REPO=$(echo $LINE | cut -f 2 -d '|')
   echo "$REPO" > /tmp/petget/current-repo-triad
   TREE1=$(echo $LINE | cut -f 1 -d '|')
   if [  "$(grep $TREE1 /root/.packages/user-installed-packages 2>/dev/null)" = "" -a -f /tmp/install_quietly ]; then
    if [ "$(cat /var/local/petget/nt_category 2>/dev/null)" = "true" ]; then
     /usr/local/petget/installpreview.sh
    else
	 rxvt -title "$VTTITLE... Do NOT close" \
	  -fn -misc-fixed-medium-r-semicondensed--13-120-75-75-c-60-*-* -bg black \
      -fg grey -geometry 80x5+50+50 -e /usr/local/petget/installpreview.sh
    fi
   else
    [  "$(grep $TREE1 /root/.packages/user-installed-packages 2>/dev/null)" = "" ] \
     && /usr/local/petget/installpreview.sh
   fi
   /usr/local/petget/finduserinstalledpkgs.sh
   sed -i "/$TREE1/d" /tmp/pkgs_left_to_install
 done < /tmp/pkgs_to_install
 /usr/local/petget/reportwindow.sh
 sync
 clean_up
 echo 100 > /tmp/petget/install_status_percent
}
export -f install_package

recalculate_sizes () {
	if [ "$(grep changed /tmp/mode_changed 2>/dev/null)" != "" ]; then
		rm -f /tmp/overall_*
		for LINE in $(cat /tmp/pkgs_to_install)
		do
			/usr/local/petget/installed_size_preview.sh $LINE ADD
		done
	else
		echo "cool!"
	fi
	rm -f /tmp/mode_changed
}
export -f recalculate_sizes

wait_func () {
	/usr/lib/gtkdialog/box_splash -close never -text "$(gettext 'Please wait, calculating total required space for the installation...')" &
	X1PID=$!
	recalculate_sizes
	while true ; do
		sleep 0.2
		[ "$(ps -eo pid,command | grep installed_size_preview | grep -v grep)" = "" ] && break
	done
	kill -9 $X1PID
}
export -f wait_func

case "$1" in
	check_total_size)
		touch /tmp/install_quietly #avoid splashes
		check_total_size
		;;
	"$(gettext 'Auto install')")
		wait_func
		rm -f /tmp/install_pets_quietly
		rm -f /tmp/install_classic 2>/dev/null
		rm -f /tmp/download_pets_quietly 2>/dev/null
		rm -f /tmp/download_only_pet_quietly 2>/dev/null
		touch /tmp/install_quietly
		touch /tmp/install_pets_quietly
		cp -a /tmp/pkgs_to_install /tmp/pkgs_to_install_done
		VTTITLE=Installing
		export VTTITLE
		install_package
		unset VTTITLE
		;;
	"$(gettext 'Download packages (no install)')")
		wait_func
		rm -f /tmp/install_pets_quietly
		rm -f /tmp/install_classic 2>/dev/null
		rm -f /tmp/download_pets_quietly 2>/dev/null
		rm -f /tmp/download_only_pet_quietly 2>/dev/null
		touch /tmp/install_quietly
		touch /tmp/download_only_pet_quietly 
		cp -a /tmp/pkgs_to_install /tmp/pkgs_to_install_done
		VTTITLE=Downloading
		export VTTITLE
		install_package
		unset VTTITLE
		;;
	"$(gettext 'Download all (packages and dependencies)')")
		wait_func
		rm -f /tmp/install_pets_quietly
		rm -f /tmp/install_classic 2>/dev/null
		rm -f /tmp/download_pets_quietly 2>/dev/null
		rm -f /tmp/download_only_pet_quietly 2>/dev/null
		touch /tmp/install_quietly
		touch /tmp/download_pets_quietly 
		cp -a /tmp/pkgs_to_install /tmp/pkgs_to_install_done
		VTTITLE=Downloading
		export VTTITLE
		install_package
		unset VTTITLE
		;;
	"$(gettext 'Step by step installation (classic mode)')")
		wait_func
		rm -f /tmp/install{,_pets}_quietly
		rm -f /tmp/download_pets_quietly 2>/dev/null
		rm -f /tmp/download_only_pet_quietly 2>/dev/null
		touch /tmp/install_classic
		install_package
		;;
esac
