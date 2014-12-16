#!/bin/bash

#set -x ; mkdir -p /root/LOGs; NAME=$(basename "$0"); exec 1>> /root/LOGs/"$NAME".log 2>&1

# clode older window. Must be a better way...
OLD_DIALOG=$(ps | grep REMOVE_PETS_DIALOG | grep program | cut -f 1-2 -d ' ')
kill -9 $OLD_DIALOG

export TEXTDOMAIN=petget__removewindow.sh
export OUTPUT_CHARSET=UTF-8

[ "`whoami`" != "root" ] && exec sudo -A ${0} ${@} #110505

# Check input
if [ "$TREE2" != "" ]; then
 if [ "$(grep $TREE2 /tmp/pkgs_to_remove)" = "" ]; then
  echo "$TREE2" >> /tmp/pkgs_to_remove
 fi
else
 exit 0
fi

report_window () {
 [ ! -f /tmp/remove_pets_quietly ] && exit 0
 /usr/local/petget/finduserinstalledpkgs.sh 
 sync
 rm -f /tmp/pgks_really_removed 2>/dev/null
 rm -f /tmp/pgks_failed_to_remove 2>/dev/null
 for LINE in $(cat /tmp/pkgs_to_remove_done) 
 do 
  REALLY=$(grep $LINE /tmp/petget/installedpkgs.results) 
  if [ "$REALLY" = "" ]; then
   echo $LINE >> /tmp/pgks_really_removed
  else
   echo $LINE >> /tmp/pgks_failed_to_remove
  fi
 done
 
 REMOVED_PGKS=$(cat /tmp/pgks_really_removed | tr '\n' ' ')
 FAILED_TO_REMOVE=$(cat /tmp/pgks_failed_to_remove | tr '\n' ' ')
 
 cat << EOF > /tmp/overall_remove_deport
Removed Packages
$REMOVED_PGKS

Failed to Remone Packages
$FAILED_TO_REMOVE
EOF
 
 [ "$REMOVED_PGKS" = "" ] && REMOVED_PGKS="Bummer :("
 [ "$FAILED_TO_REMOVE" = "" ] && FAILED_TO_REMOVE="Just kidding :)"

# Info window/dialogue (display and option to save "missing" info)

 FAILED=""
 if [ "$FAILED_TO_INSTALL" != "" ];then
  FAILED="<vbox>
  <text><label>$(gettext 'However the following packages failed to be romoved:')</label></text>
   <vbox scrollable=\"true\" height=\"100\">
    <text><label>${FAILED_TO_INSTALL}</label></text>
   </vbox>
  </vbox>"
 fi
   
 DETAILSBUTTON="<button><label>$(gettext 'View details')</label>
  <action>defaulttextviewer /tmp/overall_remove_deport & </action>
  </button>"
 
 export REPORT_DIALOG="<window title=\"$(gettext 'Puppy Package Manager')\" icon-name=\"gtk-about\">
  <vbox>
   <text><label>$(gettext 'The following packages have been removed:')</label></text>
   <vbox scrollable=\"true\" height=\"150\">
    <text><label>${REMOVED_PGKS}</label></text>
   </vbox>
   ${FAILED}   
   
   <hbox>
    ${DETAILSBUTTON}
    <button ok></button>
   </hbox>
  </vbox>
 </window>
 " 
 RETPARAMS="`gtkdialog4 --center --program=REPORT_DIALOG`"

 rm -f /tmp/pgks_really_removed
 rm -f /tmp/pgks_failed_to_remove
 rm -f /tmp/pkgs_to_remove_done
 rm -f /tmp/overall_remove_deport
 }
export -f report_window

remove_package () {
 [ "$(cat /tmp/pkgs_to_remove)" = "" ] && exit 0
 # Have to kill uninstall window somehow. This does not work
 #CLOSE_WINDOW=$(ps | grep INSTALLED_DIALOG | grep program | cut -f 1 -d ' ')
 #kill -9 $CLOSE_WINDOW
 cp /tmp/pkgs_to_remove /tmp/pkgs_left_to_remove
 cat /tmp/pkgs_to_remove
 for LINE in $(cat /tmp/pkgs_to_remove)
 do 
  TREE2=$LINE
  if [ -f /tmp/remove_pets_quietly ]; then 
   urxvt -title 'Removing... Do NOT Close' \
    -fn -misc-fixed-medium-r-semicondensed--13-120-75-75-c-60-*-* -bg black \
    -fg grey -geometry 80x5+50+50 -e /usr/local/petget/removepreview.sh
   /usr/local/petget/finduserinstalledpkgs.sh
   sed -i "/$TREE2/d" /tmp/pkgs_left_to_remove
  else
   /usr/local/petget/removepreview.sh
   /usr/local/petget/finduserinstalledpkgs.sh
   sed -i "/$TREE2/d" /tmp/pkgs_left_to_remove
  fi
  sync
 done
 rm -f /tmp/{pkgs_to_remove,pkgs_left_to_remove}
 report_window 
}
export -f remove_package

classic_remove () {
 rm -f /tmp/remove_pets_quietly 2>/dev/null
 remove_package
}
export -f classic_remove

auto_remove () {
 rm -f /tmp/remove_pets_quietly 2>/dev/null
 touch /tmp/remove_pets_quietly
 cp -a /tmp/pkgs_to_remove /tmp/pkgs_to_remove_done
 remove_package
}
export -f auto_remove

delete_out_entry () {
 sed -i "/$TREE2/d" /tmp/pkgs_to_remove
}
export -f delete_out_entry

export REMOVE_PETS_DIALOG='<window title="'$(gettext 'Remove Puppy Packages')'" icon-name="gtk-about" default_height="250" default_width="300">
 <vbox>
  <text><label>'$(gettext 'The following packages will be removed.')'</label></text>
  <text><label>'$(gettext 'Remove from the list by selecting.')'</label></text>  
  <tree column-resizeable="false">
    <label>'$(gettext 'Packages to remove')'</label>
    <variable>TREE2</variable>
    <input>cat /tmp/pkgs_to_remove</input>
    <action>delete_out_entry</action>
    <action>refresh:TREE2</action>
    <action signal="button-release-event">delete_out_entry</action>
    <action signal="button-release-event">refresh:TREE2</action>
  </tree>
  <text space-fill="true"><label>'$(gettext 'You can uninstall all the  package(s) at once (quicker), or use the "classic" interactive dialogs (slower). Select:')'</label></text>
  <text xalign="0" space-fill="false" use-markup="true">
   <label>"'$(gettext '<b>Auto mode</b>, to Uninstall All Packages at once')'"</label></text>
  <text xalign="0" space-fill="true" use-markup="true" wrap="false">
   <label>"'$(gettext '<b>Classic mode</b>, to Uninstall One-by-One')'"</label></text>
  <hbox>
  <button>
   <label>'$(gettext 'Classic mode')'</label>
   <action>classic_remove &</action>
   <action type="exit">echo exiting</action>
  </button>
  <button>
   <label>'$(gettext 'Auto mode')'</label>
   <action>auto_remove &</action>
   <action type="exit">echo exiting</action>
  </button> 
  <button>
   <label>'$(gettext 'Cancel')'</label>
   <action>rm /tmp/pkgs_to_remove</action>
   <action type="exit">echo exiting</action> 
  </button>
  </hbox>
  </vbox>
</window>' 
gtkdialog --program=REMOVE_PETS_DIALOG
