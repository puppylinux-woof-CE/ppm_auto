#!/bin/bash

#[ -f /tmp/install_pets_quietly ] && set -x ; mkdir -p /tmp/PPM_LOGs ; NAME=$(basename "$0"); exec 1>> /tmp/PPM_LOGs/"$NAME".log 2>&1

export TEXTDOMAIN=petget__reportwindow.sh
export OUTPUT_CHARSET=UTF-8

# Check if we are needed
[ ! -f /tmp/install_pets_quietly ] && exit 0

# Info source files
/usr/local/petget/finduserinstalledpkgs.sh #make sure...
sync
rm -f /tmp/pgks_really_installed 2>/dev/null
rm -f /tmp/pgks_failed_to_install 2>/dev/null
for LINE in $(cat /tmp/pkgs_to_install_done  | cut -f 1 -d '|') 
do
 if [  -f /tmp/download_pets_quietly -o  -f /tmp/download_only_pet_quietly ];then
  DOWN_PATH=$HOME
  # [ -f "$DOWN_PATH"/"$xLINE" ] && REALLY=$LINE || REALLY= ""
  REALLY=$(ls "$DOWN_PATH"/"$LINE"*)
 else
  REALLY=$(grep $LINE /tmp/petget/installedpkgs.results)
 fi 
 if [ "$REALLY" != "" ]; then
  echo $LINE >> /tmp/pgks_really_installed
 else
  echo $LINE >> /tmp/pgks_failed_to_install
 fi
done

INSTALLED_PGKS=$(cat /tmp/pgks_really_installed | tr '\n' ' ')
FAILED_TO_INSTALL=$(cat /tmp/pgks_failed_to_install | tr '\n' ' ')
#MISSING_PKGS=$(cat /tmp/overall_petget_missingpkgs_patterns.txt |sort|uniq )
MISSING_LIBS=$(cat /tmp/overall_missing_libs.txt | tr ' ' '\n' | sort | uniq )
NOT_IN_PATH_LIBS=$(cat /tmp/overall_missing_libs_hidden.txt | tr ' ' '\n' | sort | uniq )
cat << EOF > /tmp/overall_install_deport
Installed or Downloaded Packages
$INSTALLED_PGKS

Failed to Install or Download Packages
$FAILED_TO_INSTALL

Missing Libraries
$MISSING_LIBS

Existing Libraries but not in Path
$NOT_IN_PATH_LIBS
EOF

[ "$INSTALLED_PGKS" = "" ] && INSTALLED_PGKS="Bummer :("
[ "$FAILED_TO_INSTALL" = "" ] && FAILED_TO_INSTALL="Just kidding :)"

# Info window/dialogue (display and option to save "missing" info)
MISSINGMSG1="<text use-markup=\"true\"><label>\"<b>$(gettext 'No missing shared libraries')</b>\"</label></text>"
if [ "$MISSING_LIBS" != "" ];then
 MISSINGMSG1="<text><label>$(gettext 'These libraries are missing:')</label></text><text use-markup=\"true\"><label>\"<b>${MISSING_LIBS}</b>\"</label></text>"
fi
if [ "$NOT_IN_PATH_LIBS" != "" ];then #100830
 MISSINGMSG1="${MISSINGMSG1} <text><label>$(gettext 'These needed libraries exist but are not in the library search path (it is assumed that a startup script in the package makes these libraries loadable by the application):')</label></text><text use-markup=\"true\"><label>\"<b>${NOT_IN_PATH_LIBS}</b>\"</label></text>"
fi

FAILED=""
if [ "$FAILED_TO_INSTALL" != "" ];then
 FAILED="<vbox>
  <text><label>$(gettext 'However the following packages failed to install/download:')</label></text>
   <vbox scrollable=\"true\" height=\"100\">
    <text><label>${FAILED_TO_INSTALL}</label></text>
   </vbox>
  </vbox>"
fi
   
DETAILSBUTTON="<button><label>$(gettext 'View details')</label>
  <action>defaulttextviewer /tmp/overall_install_deport & </action>
  </button>"
 
 
export REPORT_DIALOG="<window title=\"$(gettext 'Puppy Package Manager')\" icon-name=\"gtk-about\">
  <vbox>
   <text><label>$(gettext 'The following packages have been succesfully installed or downloaded:')</label></text>
   <vbox scrollable=\"true\" height=\"150\">
    <text><label>${INSTALLED_PGKS}</label></text>
   </vbox>
   ${FAILED}   
   <vbox scrollable=\"true\" height=\"100\">
    ${MISSINGMSG1}
   </vbox>

   <hbox>
    ${DETAILSBUTTON}
    <button ok></button>
   </hbox>
  </vbox>
 </window>
" 
RETPARAMS="`gtkdialog4 --center --program=REPORT_DIALOG`"



# Clean up
rm -f /tmp/pkgs_to_install_done
rm -f /tmp/download_pets_quietly 
rm -f /tmp/download_only_pet_quietly
rm -f /tmp/pgks_really_installed
rm -f /tmp/pgks_failed_to_install
rm -f /tmp/overall_petget_missingpkgs_patterns.txt
rm -f /tmp/overall_missing_libs.txt
rm -f /tmp/overall_install_deport
