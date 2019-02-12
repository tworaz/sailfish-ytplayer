#!/bin/sh

_SCRIPT=$(readlink -f $0)
_DIR=$(dirname $_SCRIPT)/..

_BASE=$(grep -oE 'Version:[[:space:]]*[0-9.]*' $_DIR/rpm/harbour-ytplayer.spec | awk '{ print $2 }')
_REV=$(grep -oE 'Revision:[[:space:]]*[0-9.]*' $_DIR/rpm/harbour-ytplayer.spec | awk '{ print $2 }')

echo "$_BASE-$_REV"
