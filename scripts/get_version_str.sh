#!/bin/sh
cd "$(dirname "$0")"/..
_BASE=$(grep -oE 'Version:[[:space:]]*[0-9.]*' rpm/harbour-ytplayer.spec | awk '{ print $2 }')
_REV=$(grep -oE 'Release:[[:space:]]*[0-9.]*' rpm/harbour-ytplayer.spec | awk '{ print $2 }')
_FILE=scripts/version-str

if [ -f .git/HEAD ] ; then
    _REV=$(cat .git/$(cat .git/HEAD | awk '{ print $2 }') 2>&1 | cut -c1-7)
    echo "$_BASE-$_REV" > $_FILE
elif [ ! -f $_FILE ]; then
    echo "$_BASE-$_REV" > $_FILE
fi
