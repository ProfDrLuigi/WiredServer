source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!
platform :osx, '10.13'

#target 'Wired Server' do
#    pod 'Sparkle'
#end

target 'WiredNetworking' do
    project 'WiredFrameworks/WiredFrameworks.xcodeproj'
    workspace 'WiredFrameworks/WiredFrameworks.xcworkspace'
    pod 'OpenSSL-Universal'
end

target 'libwired-osx' do
    project 'WiredFrameworks/WiredFrameworks.xcodeproj'
    workspace 'WiredFrameworks/WiredFrameworks.xcworkspace'
    pod 'OpenSSL-Universal'
end
