#!/bin/bash -x
flutter build web --web-renderer canvaskit
if [ $? != 0 ] ; then
    exit 1
fi
rm -rf docs/run
mv build/web docs/run
