#!/bin/sh
set -e
DATE=$(date  +%d%m)
VER=$(grep VERSION= usr/local/petget/pkg_chooser.sh | cut -f 2 -d '=')
NAME=ppm_auto-${VER}_${DATE}
rm -rf $NAME
mkdir -p $NAME
cp -aR usr $NAME/
cp -a pet.specs $NAME/
sync
urxvt -e dir2pet $NAME/
sync
rm -f ../$NAME.pet
mv $NAME.pet ../
rm -rf $NAME
rm -f nohup.out
set +e
