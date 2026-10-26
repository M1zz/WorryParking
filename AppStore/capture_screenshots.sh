#!/bin/zsh
# Builds the app, captures every screenshot scene in every language below on a
# 6.9" simulator, and composes 6.5" (1242x2688) App Store images into AppStore/Screenshots/.
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

# <AppleLanguages code>:<AppleLocale>. The code is also the folder name used by compose_screenshots.py.
LANGS=(ko:ko_KR en:en_US en-GB:en_GB zh-Hans:zh_CN zh-Hant:zh_TW ja:ja_JP ru:ru_RU es:es_ES de:de_DE fr:fr_FR it:it_IT
       pt-BR:pt_BR th:th_TH vi:vi_VN cs:cs_CZ da:da_DK el:el_GR fi:fi_FI id:id_ID nb:nb_NO nl:nl_NL pl:pl_PL sv:sv_SE tr:tr_TR)

for entry in $LANGS; do
  lang=${entry%%:*}
  locale=${entry##*:}
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
