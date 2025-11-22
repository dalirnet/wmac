#!/bin/bash

CONFIG=${1:-debug}

if [ "$CONFIG" != "debug" ] && [ "$CONFIG" != "release" ]; then
    echo "Usage: $0 [debug|release]"
    exit 1
fi

echo "Building $CONFIG..."

mkdir -p build/WMac.app/Contents/{MacOS,Resources}

build_arch() {
    swiftc ${2} -o ${1} \
        Sources/WMacApp.swift Sources/Models/*.swift Sources/Utils/*.swift Sources/Views/*.swift \
        -framework SwiftUI -framework AppKit -target ${3}-apple-macos13.0
}

if [ "$CONFIG" = "release" ]; then
    build_arch build/WMac_arm64 "-O" "arm64"
    build_arch build/WMac_x86_64 "-O" "x86_64"
    lipo -create -output build/WMac.app/Contents/MacOS/WMac build/WMac_{arm64,x86_64}
    rm build/WMac_{arm64,x86_64}
else
    build_arch build/WMac.app/Contents/MacOS/WMac "-g" $(uname -m)
fi

cp Resources/Info.plist build/WMac.app/Contents/
cp Resources/AppIcon.icns build/WMac.app/Contents/Resources/
cp Resources/ssh_command.exp build/WMac.app/Contents/Resources/
chmod +x build/WMac.app/Contents/Resources/ssh_command.exp

echo "✓ build/WMac.app"
