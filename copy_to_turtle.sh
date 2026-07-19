#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 <id>"
    exit 1
fi

TARGET=$1

if [ ! -e "../${TARGET}" ] || [ "$TARGET" -eq "$(basename $PWD)" ]; then
    echo "Target $TARGET is not valid"
    exit 1
fi

echo "Copying to target $TARGET"

rm -rf "../$TARGET/cc-libs"
cp -r cc-libs "../$TARGET/"

rm -rf "../$TARGET/cc"
mkdir -p "../$TARGET/cc"
cp -r cc-apps/* "../$TARGET/cc/"
