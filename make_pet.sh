#!/bin/sh
# Check if we can
if [ "$(df -T `pwd`/make_pet.sh | awk '{print $2}' | tail -n1 | cut -c 1-3)" != "ext" ]; then
 yaf-splash -bg orange -timeout 5 -text "You need an ext[2-4] filesystem. Exitig"
 exit 0
fi

if [ "$(which dir2pet)" = "" ]; then
 yaf-splash -bg orange -timeout 5 -text "You need should be running puppylinux. Exitig"
 exit 0
fi

DATE=$(date  +%d%m)
VER=$(grep VERSION= usr/local/petget/pkg_chooser.sh | cut -f 2 -d '=')
NAME=ppm_auto-${VER}_${DATE}
rm -rf $NAME
mkdir -p $NAME
cp -aR usr $NAME/
cp -a pet.specs $NAME/
sync
urxvt -e dir2pet $NAME/
[ $? -ne 0 ] && rm -rf $NAME
sync
rm -f ../$NAME.pet
mv $NAME.pet ../
rm -rf $NAME
rm -f nohup.out

