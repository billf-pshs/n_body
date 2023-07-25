#!/bin/bash
flutter build web
if [ $? != 0 ] ; then
    exit 1
fi
rm -rf docs
mv build/web docs
