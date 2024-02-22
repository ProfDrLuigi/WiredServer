source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!
platform :osx, '10.13'

target 'Wired Server' do
    #pod 'OpenSSL-Universal', '~> 1.1.180'
    pod 'Sparkle', '~> 2.5.2'
end

target 'WiredNetworking' do
    project 'WiredFrameworks/WiredFrameworks.xcodeproj'
    workspace 'WiredFrameworks/WiredFrameworks.xcworkspace'
    pod 'OpenSSL-Universal', '~> 1.1.180'
end

target 'libwired-osx' do
    project 'WiredFrameworks/WiredFrameworks.xcodeproj'
    workspace 'WiredFrameworks/WiredFrameworks.xcworkspace'
    pod 'OpenSSL-Universal', '~> 1.1.180'
end
