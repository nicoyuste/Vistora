#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

command -v xcodegen >/dev/null || { echo "XcodeGen is required." >&2; exit 1; }
command -v xcodebuild >/dev/null || { echo "Xcode is required." >&2; exit 1; }

if [[ ! -f App/Resources/UnsplashConfig.plist ]]; then
  (umask 077; cp App/UnsplashConfig.example.plist App/Resources/UnsplashConfig.plist)
fi

xcodegen generate

resolved_path="Vistora.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if [[ -f Package.resolved ]]; then
  mkdir -p "$(dirname "$resolved_path")"
  cp Package.resolved "$resolved_path"
fi

xcodebuild -resolvePackageDependencies \
  -project Vistora.xcodeproj \
  -scheme Vistora \
  -derivedDataPath "$PWD/DerivedData" \
  -clonedSourcePackagesDirPath "$PWD/DerivedData/SourcePackages"

if [[ -f "$resolved_path" ]]; then
  cp "$resolved_path" Package.resolved
fi
