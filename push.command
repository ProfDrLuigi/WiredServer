#!/bin/bash

#if [ ! -d ~/Documents/Xcode/WiredServer/"Wired Server.app" ]; then
#	echo "App nicht in den Ordner kopiert. Abbruch."
#	exit 1
#fi

rm -r /Users/luigi/Library/Caches/Sparkle_generate_appcast/*

    rm ~/Documents/Xcode/WiredServer/app/appcast.xml
    cp ~/Documents/Xcode/WiredServer/wiredserver.html ~/Documents/Xcode/WiredServer/app/
    #ditto -c -k --sequesterRsrc --keepParent ~/Documents/Xcode/WiredServer/"Wired Server.app" ~/Documents/Xcode/WiredServer/app/wiredserver.zip

    /Applications/Sparkle/bin/generate_appcast ~/Documents/Xcode/WiredServer/app/
    #sed -ib "s/Luigi\/wiredServer/Luigi\/WiredServer/g" ~/Documents/Xcode/WiredServer/app/appcast.xml
    #rm ~/Documents/Xcode/WiredServer/app/appcast.xmlb

#rm -r ~/Documents/Xcode/WiredServer/"Wired Server.app"

