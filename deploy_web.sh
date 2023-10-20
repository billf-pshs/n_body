#!/bin/bash -x
flutter build web
if [ $? != 0 ] ; then
    exit 1
fi
rm -rf docs/run
mv build/web docs/run
