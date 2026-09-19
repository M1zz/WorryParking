#!/bin/zsh
# Builds the app, captures every screenshot scene in Korean and English on a
# 6.9" simulator, and composes App Store images into AppStore/Screenshots/.
#
# Usage: AppStore/capture_screenshots.sh ["iPhone 18 Pro Max"]
set -euo pipefail

ROOT=${0:A:h:h}
DEVICE_NAME=${1:-"iPhone 18 Pro Max"}
BUNDLE_ID=com.devkoan.worryparking
WORK=$ROOT/AppStore/build
SCENES=(lot park ticket gate log)

DEVICE=$(xcrun simctl list devices available | grep -F "$DEVICE_NAME (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
[[ -n $DEVICE ]] || { echo "Simulator '$DEVICE_NAME' not found"; exit 1; }
xcrun simctl boot $DEVICE 2>/dev/null || true
xcrun simctl bootstatus $DEVICE -b >/dev/null

xcodebuild -project $ROOT/WorryParking.xcodeproj -scheme WorryParking -configuration Debug \
  -destination "id=$DEVICE" -derivedDataPath $WORK/dd build -quiet
xcrun simctl install $DEVICE $WORK/dd/Build/Products/Debug-iphonesimulator/WorryParking.app

xcrun simctl status_bar $DEVICE override --time "9:41" --dataNetwork wifi --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState discharging --batteryLevel 100 --operatorName ""

for lang in ko en; do
  locale=$([[ $lang == ko ]] && echo ko_KR || echo en_US)
  mkdir -p $WORK/raw/$lang
  for scene in $SCENES; do
    xcrun simctl terminate $DEVICE $BUNDLE_ID 2>/dev/null || true
    xcrun simctl launch $DEVICE $BUNDLE_ID -screenshotScene $scene \
      -AppleLanguages "($lang)" -AppleLocale $locale >/dev/null
    sleep 4
    xcrun simctl io $DEVICE screenshot $WORK/raw/$lang/$scene.png >/dev/null 2>&1
    echo "captured $lang/$scene"
  done
done
xcrun simctl terminate $DEVICE $BUNDLE_ID 2>/dev/null || true
xcrun simctl status_bar $DEVICE clear

python3 $ROOT/AppStore/compose_screenshots.py $WORK/raw $ROOT/AppStore/Screenshots
