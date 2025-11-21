#!/bin/bash

ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    TARGET="arm64-apple-macos13.0"
elif [ "$ARCH" = "x86_64" ]; then
    TARGET="x86_64-apple-macos13.0"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

mkdir -p build/WMac.app/Contents/MacOS
mkdir -p build/WMac.app/Contents/Resources

swiftc -o build/WMac.app/Contents/MacOS/WMac \
    Sources/WMacApp.swift \
    Sources/Models/*.swift \
    Sources/Utils/*.swift \
    Sources/Views/*.swift \
    -framework SwiftUI \
    -framework AppKit \
    -target $TARGET

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

cp Info.plist build/WMac.app/Contents/Info.plist
