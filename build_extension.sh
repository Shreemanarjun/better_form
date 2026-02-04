#!/bin/bash
set -e

# This script builds the DevTools extension and copies it to the
# extension/devtools/build directory for publishing.

# Navigate to the extension source directory
cd devtools_extension

echo "Running pub get..."
flutter pub get

echo "Building web extension (wasm)..."
flutter build web --wasm

# Clean up and copy build output
echo "Copying build output to extension/devtools/build..."
rm -rf ../extension/devtools/build
cp -r build/web ../extension/devtools/build

# Validate the extension
echo "Validating extension..."
flutter pub run devtools_extensions validate --package=..

echo "Done!"
