# Wired Server Source Code

This repository hosts Wired Server source code. You will find an Xcode project named "WiredServer.xcworkspace" that contains a Wired Server target ready to deploy a 10.13+ compatible application (x64/ARM).

## Prerequisites

- Mac OS X 10.13+
- Xcode 13+

## How to compile Wired Server

1. Clone Github Repo :

		git clone https://github.com/profdrluigi/WiredServer.git

		
3. Open `WiredServer.xcworkspace`

4. Select scheme `Wired Server` and be sure to use "Release" Build Configuration

5. Launch Build, Wired Server.app should launch automatically when finished

## How to create U2B for the "wired" Binary

To creating a Universal Binary (the 'wired' Server Binary itself, not the Wired Server Application) you need to compile the XCode Project on a M- and Intel Mac/Hackintosh.

On a M Mac:

- Build 
- Go into

		"Wired Server.app/Contents/Resources/Wired" 

and copy the file
		
		"wired"
to Desktop and rename it to

		"wired_arm"
	
On an Intel Mac:

- Build 
- Go into

		"Wired Server.app/Contents/Resources/Wired" 

and copy the file
		
		"wired"
to Desktop and rename it to

		"wired_x86"

### Making U2B of the 2 Binaries

Now open the Terminal and type

		lipo -create ~/Desktop/wired_arm ~/Desktop/wired_x86 -output ~/Desktop/wired

Now copy the new created "wired" Binary to:

		"Wired Server.app/Contents/Resources/Wired" 

and overwrite the old one.

Done. Now you have a fully U2B Server.

## Troubleshooting

Be sure that "wired" target is listed in Taget Dependencies Build Phases of Wired Server target. If not, add it in order to compile wired binary for Mac.

If you got the error that the Application can not be opened because it's damaged you must put it out of the Quarantain. Type in Terminal:

  		xattr -rc "/Applications/Wired Server.app"

 (or another Path where you have the App) and you should be good to go.


## License

This code is distributed under BSD license, and it is free for personal or commercial use.
		
- Copyright (c) 2003-2009 Axel Andersson, All rights reserved.
- Copyright (c) 2011-2019 Rafaël Warnault, All rights reserved.
		
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
		
Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
		
THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

