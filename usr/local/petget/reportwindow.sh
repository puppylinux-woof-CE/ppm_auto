#!/bin/bash

#[ -f /tmp/install_quietly ] && set -x ; mkdir -p /tmp/PPM_LOGs ; NAME=$(basename "$0"); exec 1>> /tmp/PPM_LOGs/"$NAME".log 2>&1

export TEXTDOMAIN=petget__reportwindow.sh
export OUTPUT_CHARSET=UTF-8

# Check if we are needed
[ ! -f /tmp/install_quietly ] && exit 0

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
  [ "$(grep $LINE /tmp/pgks_failed_to_install_forced 2>/dev/null | sort | uniq )" != "" ] && REALLY=''
 fi 
 if [ "$REALLY" != "" ]; then
  echo $LINE >> /tmp/pgks_really_installed
 else
  echo $LINE >> /tmp/pgks_failed_to_install
 fi
done
rm -f /tmp/pgks_failed_to_install_forced

[ -f /tmp/pgks_really_installed ] && INSTALLED_PGKS="$(</tmp/pgks_really_installed)" \
 || INSTALLED_PGKS=''
[ -f /tmp/pgks_failed_to_install ] && FAILED_TO_INSTALL="$(</tmp/pgks_failed_to_install)" \
 || FAILED_TO_INSTALL=''
#MISSING_PKGS=$(cat /tmp/overall_petget_missingpkgs_patterns.txt |sort|uniq )
MISSING_LIBS=$(cat /tmp/overall_missing_libs.txt 2>/dev/null | tr ' ' '\n' | sort | uniq )
NOT_IN_PATH_LIBS=$(cat /tmp/overall_missing_libs_hidden.txt 2>/dev/null | tr ' ' '\n' | sort | uniq )
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

[ "$INSTALLED_PGKS" = "" ] && INSTALLED_PGKS="$(gettext 'Bummer :(')"
[ "$FAILED_TO_INSTALL" = "" ] && FAILED_TO_INSTALL="$(gettext 'No errors')"

# Info window/dialogue (display and option to save "missing" info)
MISSINGMSG1="<i><b>$(gettext 'No missing shared libraries')</b></i>"
if [ "$MISSING_LIBS" ];then
 MISSINGMSG1="<i><b>$(gettext 'These libraries are missing:')
${MISSING_LIBS}</b></i>"
fi
if [ "$NOT_IN_PATH_LIBS" ];then #100830
 MISSINGMSG1="<i><b>${MISSINGMSG1}</b></i>
 
$(gettext 'These needed libraries exist but are not in the library search path (it is assumed that a startup script in the package makes these libraries loadable by the application):')
<i><b>${NOT_IN_PATH_LIBS}</b></i>"
fi

export REPORT_DIALOG='
<window title="'$(gettext 'Puppy Package Manager')'" icon-name="gtk-about" default_height="550">
<vbox>
  '"`/usr/lib/gtkdialog/xml_info fixed package_add.svg 60 " " "$(gettext "Package install/download report")"`"'
  <hbox space-expand="true" space-fill="true">
    <hbox scrollable="true" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
      <hbox space-expand="false" space-fill="false">
        <eventbox name="bg_report" space-expand="true" space-fill="true">
          <vbox margin="5" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
            '"`/usr/lib/gtkdialog/xml_pixmap dialog-complete.svg 32`"'
            <text angle="90" wrap="false" yalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<big><b><span color='"'#15BC15'"'>'$(gettext 'Success')'</span></b></big> "</label></text>
          </vbox>
        </eventbox>
      </hbox>
      <vbox scrollable="true" shadow-type="0" hscrollbar-policy="2" vscrollbar-policy="1" space-expand="true" space-fill="true">
        <text ypad="5" xpad="5" yalign="0" xalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<i><b>'${INSTALLED_PGKS}' </b></i>"</label></text>
      </vbox>
    </hbox>
  </hbox>

  <hbox space-expand="true" space-fill="true">
    <hbox scrollable="true" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
      <hbox space-expand="false" space-fill="false">
        <eventbox name="bg_report" space-expand="true" space-fill="true">
          <vbox margin="5" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
            '"`/usr/lib/gtkdialog/xml_pixmap dialog-error.svg 32`"'
            <text angle="90" wrap="false" yalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<big><b><span color='"'#DB1B1B'"'>'$(gettext 'Failed')'</span></b></big> "</label></text>
          </vbox>
        </eventbox>
      </hbox>
      <vbox scrollable="true" shadow-type="0" hscrollbar-policy="2" vscrollbar-policy="1" space-expand="true" space-fill="true">
        <text ypad="5" xpad="5" yalign="0" xalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<i><b>'${FAILED_TO_INSTALL}' </b></i>"</label></text>
      </vbox>
    </hbox>
  </hbox>

  <hbox space-expand="true" space-fill="true">
    <hbox scrollable="true" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
      <hbox space-expand="false" space-fill="false">
        <eventbox name="bg_report" space-expand="true" space-fill="true">
          <vbox margin="5" hscrollbar-policy="2" vscrollbar-policy="2" space-expand="true" space-fill="true">
            '"`/usr/lib/gtkdialog/xml_pixmap building_block.svg 32`"'
            <text angle="90" wrap="false" yalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"<big><b><span color='"'#bbb'"'>Libs</span></b></big> "</label></text>
          </vbox>
        </eventbox>
      </hbox>
      <vbox scrollable="true" shadow-type="0" hscrollbar-policy="1" vscrollbar-policy="1" space-expand="true" space-fill="true">
        <text ypad="5" xpad="5" yalign="0" xalign="0" use-markup="true" space-expand="true" space-fill="true"><label>"'${MISSINGMSG1}'"</label></text>
      </vbox>
    </hbox>
  </hbox>

  <hbox space-expand="false" space-fill="false">
    <button>
      <label>'$(gettext 'View details')'</label>
      '"`/usr/lib/gtkdialog/xml_button-icon document_viewer`"'
      <action>defaulttextviewer /tmp/overall_install_deport &</action>
     </button>
     <button ok></button>
     '"`/usr/lib/gtkdialog/xml_scalegrip`"'
  </hbox>
</vbox>
</window>'
RETPARAMS="`gtkdialog --center -p REPORT_DIALOG`"

# Clean up
rm -f /tmp/pkgs_to_install_done 2>/dev/null
rm -f /tmp/pgks_really_installed 2>/dev/null
rm -f /tmp/pgks_failed_to_install 2>/dev/null
rm -f /tmp/overall_petget_missingpkgs_patterns.txt 2>/dev/null
rm -f /tmp/overall_missing_libs.txt 2>/dev/null
rm -f /tmp/overall_install_deport 2>/dev/null
