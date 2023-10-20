#!/bin/bash -x
#
#
#  A little script to check out the versions in turn.  Useful for
#  e.g. giving a presentation.

rm pubspec.lock
git checkout main
for v in v0 v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 v13 v14 v15 \
	v16 v17 v18 v19
do
	rm pubspec.lock
	git checkout $v
	echo "***********************  $v  *********************"
	read foo
done
