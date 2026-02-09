#!/bin/bash
set -e

# This script builds the DevTools extension and copies it to the
# extension/devtools/build directory for publishing.

# Navigate to the extension source directory
cd devtools_extension

echo "Running pub get..."
flutter pub get

# Build and copy using the official tool
echo "Building and copying extension using devtools_extensions tool..."
# This tool puts everything in ../extension/devtools/build/
flutter pub run devtools_extensions build_and_copy --source=. --dest=../extension/devtools

# Fix index.html in the build directory
echo "Fixing index.html for relative paths..."
# 1. Remove base href or set to ./ to allow relative loading
sed -i '' 's/<base href="\/">/<base href=".\/">/g' ../extension/devtools/build/index.html
# 2. Remove manifest link to avoid PWA triggers in DevTools
sed -i '' 's/<link rel="manifest" href="manifest.json">//g' ../extension/devtools/build/index.html

# Also copy index.html and essential assets to the root of extension/devtools
# some DevTools versions look here instead of /build/
echo "Syncing assets to devtools root for compatibility..."
cp ../extension/devtools/build/index.html ../extension/devtools/
cp ../extension/devtools/build/flutter_bootstrap.js ../extension/devtools/
cp ../extension/devtools/build/flutter.js ../extension/devtools/ || true
cp ../extension/devtools/build/main.dart.js ../extension/devtools/

# Validate the extension
echo "Validating extension..."
flutter pub run devtools_extensions validate --package=..

echo "Done!"
