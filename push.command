#!/bin/bash

#if [ ! -d ~/Documents/Xcode/WiredServer/"Wired Server.app" ]; then
#	echo "App nicht in den Ordner kopiert. Abbruch."
#	exit 1
#fi

cd ~/Documents/Xcode/WiredServer

rm -r /Users/luigi/Library/Caches/Sparkle_generate_appcast/*
rm app/appcast.xml
cp wiredserver.html app/

ditto -c -k --sequesterRsrc --keepParent /Applications/"Wired Server.app" app/wiredserver.zip

/Applications/Sparkle/bin/generate_appcast app/




