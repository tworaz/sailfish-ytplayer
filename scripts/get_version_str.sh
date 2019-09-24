#!/bin/sh
_BASE=$(grep -oE 'Version:[[:space:]]*[0-9.]*' rpm/harbour-ytplayer.spec | awk '{ print $2 }')
_REV=$(grep -oE 'Release:[[:space:]]*[0-9.]*' rpm/harbour-ytplayer.spec | awk '{ print $2 }')

if [ -d .git ]; then
    _REV=$(git rev-parse --short HEAD)
fi

echo "$_BASE-$_REV"
