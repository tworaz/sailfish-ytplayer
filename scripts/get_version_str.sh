#!/bin/sh

_SCRIPT=$(readlink -f $0)
_DIR=$(dirname $_SCRIPT)/..

_BASE=$(grep -oE 'Version:[[:space:]]*[0-9.]*' $_DIR/rpm/harbour-ytplayer.spec | awk '{ print $2 }')

if [ -d $_DIR/.git ]; then
	_REV=$(git rev-parse --short HEAD)
	echo "$_BASE-$_REV"
else
	echo $_BASE
fi
