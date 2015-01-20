#!/bin/sh
# addapted from installpreview.sh

#set -x ; mkdir -p /root/LOGs; NAME=$(basename "$0"); exec 1>> /root/LOGs/"$NAME".log 2>&1
#[ -f /tmp/install_pets_quietly ] && exit 0

export TEXTDOMAIN=petget___installed_size_preview.sh
export OUTPUT_CHARSET=UTF-8

[ "$TREE1" = "" ] && exit 0

. /etc/DISTRO_SPECS #has DISTRO_BINARY_COMPAT, DISTRO_COMPAT_VERSION
. /root/.packages/DISTRO_PKGS_SPECS

DB_FILE=Packages-`cat /tmp/petget/current-repo-triad`
tPATTERN='^'"$TREE1"'|'
EXAMDEPSFLAG='yes'
ttPTN='^'"$TREE1"'|.*ALREADY INSTALLED'
if [ "`grep "$ttPTN" /tmp/petget/filterpkgs.results.post`" != "" ];then
 EXAMDEPSFLAG='no'
fi

rm -f /tmp/petget_missing_dbentries-* 2>/dev/null

DB_ENTRY="`grep "$tPATTERN" /root/.packages/$DB_FILE | head -n 1`"
DB_dependencies="`echo -n "$DB_ENTRY" | cut -f 9 -d '|'`"
DB_size="`echo -n "$DB_ENTRY" | cut -f 6 -d '|'`"

SIZEFREEM=`cat /tmp/pup_event_sizefreem | head -n 1` 
SIZEFREEK=`expr $SIZEFREEM \* 1024`

if [ "$DB_dependencies" != "" ]; then
 echo "${TREE1}" > /tmp/petget_installpreview_pkgname
 /usr/local/petget/findmissingpkgs.sh "$DB_dependencies"
fi

MISSINGDEPS_PATTERNS="$(cat /tmp/petget_missingpkgs_patterns)"
if [ "$MISSINGDEPS_PATTERNS" = "" ]; then
 SIZEMK="`echo -n "$DB_size" | rev | cut -c 1`"
 SIZEVAL=`echo -n "$DB_size" | rev | cut -c 2-9 | rev`
 case "$SIZEMK" in
  K) echo cool /dev/null ;;
  M) SIZEVAL=$( expr $SIZEVAL \* 1024 ) ;;
  *) SIZEVAL=$( expr $SIZEVAL \/ 1024 ) ;;
 esac
 echo $SIZEVAL >> /tmp/overall_pkg_size
 exit 0
fi

/usr/local/petget/dependencies.sh
[ $? -ne 0 ] && exec /usr/local/petget/installed_size_preview.sh # check that!

FNDMISSINGDBENTRYFILE="`ls -1 /tmp/petget_missing_dbentries-* 2>/dev/null`"
 
 #130511 popup warning if a dep in devx but devx not loaded...
 if ! which gcc; then
  NEEDGCC="$(cat /tmp/petget_missing_dbentries-* | grep -E '\|gcc\||\|gcc_dev_DEV\|' | cut -f 1 -d '|')"
  if [ "$NEEDGCC" ];then
   rm -f /tmp/petget_installed_patterns_system #see pkg_chooser.sh
   #create a separate process for the popup, with delay...
   DEVXNAME="devx_${DISTRO_FILE_PREFIX}_${DISTRO_VERSION}.sfs"
   echo "#!/bin/sh
sleep 3
pupdialog --background pink --colors --ok-label \"$(gettext 'OK')\" --backtitle \"$(gettext 'WARNING: devx not installed')\" --msgbox \"$(gettext 'Package:')  \Zb${TREE1}\ZB
$(gettext "This package has dependencies that are in the 'devx' SFS file, which is Puppy's C/C++/Vala/Genie/BaCon mega-package, a complete compiling environment.")

$(gettext 'The devx file is named:') \Zb${DEVXNAME}\ZB

$(gettext "Please cancel installation, close the Puppy Package Manager, then click the \Zbinstall\ZB icon on the desktop and install the devx SFS file first.")\" 0 0" > /tmp/petget_devx_popup.sh #'geany
   chmod 755 /tmp/petget_devx_popup.sh
   /tmp/petget_devx_popup.sh &
  fi
 fi
 
 #compose pkgs into checkboxes...
 MAIN_REPO="`echo "$DB_FILE" | cut -f 2-9 -d '-'`"
 MAINPKG_NAME="`echo "$DB_ENTRY" | cut -f 1 -d '|'`"
 MAINPKG_SIZE="`echo "$DB_ENTRY" | cut -f 6 -d '|'`"
 INSTALLEDSIZEK=0
 [ "$MAINPKG_SIZE" != "" ] && INSTALLEDSIZEK=`echo "$MAINPKG_SIZE" | rev | cut -c 2-10 | rev`
 
 echo -n "" > /tmp/petget_moreframes
 echo -n "" > /tmp/petget_tabs
 echo "0" > /tmp/petget_frame_cnt
 DEP_CNT=0
 ONEREPO=""
 for ONEDEPSLIST in `ls -1 /tmp/petget_missing_dbentries-*`
 do
  ONEREPO_PREV="$ONEREPO"
  ONEREPO="`echo "$ONEDEPSLIST" | grep -o 'Packages.*' | sed -e 's%Packages\\-%%'`"
  cat $ONEDEPSLIST |
  while read ONELIST
  do
   DEP_NAME="`echo "$ONELIST" | cut -f 1 -d '|'`"
   DEP_SIZE="`echo "$ONELIST" | cut -f 6 -d '|'`"
   DEP_DESCR="`echo "$ONELIST" | cut -f 10 -d '|'`"
   ADDSIZEK=0
   [ "$DEP_SIZE" != "" ] && ADDSIZEK=`echo "$DEP_SIZE" | rev | cut -c 2-10 | rev`
   INSTALLEDSIZEK=`expr $INSTALLEDSIZEK + $ADDSIZEK`
   echo "$INSTALLEDSIZEK" > /tmp/petget_installedsizek
  done
  INSTALLEDSIZEK=`cat /tmp/petget_installedsizek`
  echo "$INSTALLEDSIZEK" >> /tmp/overall_pkg_size
 done
