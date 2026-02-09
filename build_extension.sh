#!/bin/bash
set -e

# This script builds the DevTools extension and copies it to the
# extension/devtools/build directory for publishing.

# Navigate to the extension source directory
cd devtools_extension

echo "Running pub get..."
flutter pub get

echo "Building web extension (Standard JS, No PWA)..."
flutter build web --release --base-href / --pwa-strategy none

# Clean up and copy build output
echo "Copying build output to extension/devtools/build..."
rm -rf ../extension/devtools/build
cp -r build/web ../extension/devtools/build

# Fix index.html for DevTools environment
# 1. Remove base href to allow relative loading
# 2. Remove manifest link to avoid PWA triggers
echo "Fixing index.html for relative paths..."
sed -i '' 's/<base href="\/">//g' ../extension/devtools/build/index.html
sed -i '' 's/<link rel="manifest" href="manifest.json">//g' ../extension/devtools/build/index.html

# Validate the extension
echo "Validating extension..."
flutter pub run devtools_extensions validate --package=..

echo "Done!"
