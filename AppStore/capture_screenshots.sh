#!/bin/zsh
# Builds the app, captures every screenshot scene in every language below on a
# 6.9" simulator, and composes 6.5" (1242x2688) App Store images.
#   raw captures   → docs/screenshots/raw/<lang>/<scene>.png   (not uploaded)
#   store images   → docs/screenshots/marketing/<lang>/01-<scene>.png (DeployBar uploads these)
#
# Usage: AppStore/capture_screenshots.sh ["iPhone 18 Pro Max" | <simulator UDID>] [lang ...]
#   With languages after the device, only those are (re)captured.
set -euo pipefail

ROOT=${0:A:h:h}
DEVICE_ARG=${1:-"iPhone 18 Pro Max"}
shift $(( $# > 0 ? 1 : 0 ))
BUNDLE_ID=com.devkoan.worryparking
WORK=$ROOT/AppStore/build
RAW=$ROOT/docs/screenshots/raw
OUT=$ROOT/docs/screenshots/marketing
SCENES=(lot park ticket gate log)

# Every simulator call gets a time limit so a stuck simulator can't hang the run.
limit() { perl -e '$SIG{ALRM}=sub{print STDERR "timeout: @ARGV\n"; exit 124}; alarm shift; system(@ARGV)==0 or exit(($?>>8)||1)' "$@"; }

# True when the capture is missing or a single flat colour (app not drawn yet).
blank() { [[ ! -s $1 ]] || python3 -c 'import sys; from PIL import Image, ImageStat
im = Image.open(sys.argv[1]).convert("L"); c = im.crop((0, 300, im.width, im.height - 200))
sys.exit(0 if ImageStat.Stat(c).stddev[0] < 12 else 1)' "$1"; }

if [[ $DEVICE_ARG =~ '^[0-9A-F-]{36}$' ]]; then
  DEVICE=$DEVICE_ARG
else
  DEVICE=$(xcrun simctl list devices available | grep -F "$DEVICE_ARG (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
fi
[[ -n $DEVICE ]] || { echo "Simulator '$DEVICE_ARG' not found"; exit 1; }
xcrun simctl boot $DEVICE 2>/dev/null || true
limit 600 xcrun simctl bootstatus $DEVICE -b >/dev/null

nice -n 19 xcodebuild -project $ROOT/WorryParking.xcodeproj -scheme WorryParking -configuration Debug \
  -destination "id=$DEVICE" -derivedDataPath $WORK/dd build -quiet
limit 300 xcrun simctl install $DEVICE $WORK/dd/Build/Products/Debug-iphonesimulator/WorryParking.app

limit 240 xcrun simctl status_bar $DEVICE override --time "9:41" --dataNetwork wifi --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState discharging --batteryLevel 100 --operatorName ""

# <AppleLanguages code>:<AppleLocale>. The code is also the folder name used by compose_screenshots.py.
LANGS=(ko:ko_KR en:en_US en-GB:en_GB zh-Hans:zh_CN zh-Hant:zh_TW ja:ja_JP ru:ru_RU es:es_ES de:de_DE fr:fr_FR it:it_IT
       pt-BR:pt_BR th:th_TH vi:vi_VN cs:cs_CZ da:da_DK el:el_GR fi:fi_FI id:id_ID nb:nb_NO nl:nl_NL pl:pl_PL sv:sv_SE tr:tr_TR)

for entry in $LANGS; do
  lang=${entry%%:*}
  locale=${entry##*:}
  if (( $# > 0 )) && (( ! ${@[(Ie)$lang]} )); then continue; fi
  mkdir -p $RAW/$lang
  for scene in $SCENES; do
    # KEEP_GOOD=1: only redo captures that are missing or blank.
    if [[ -n ${KEEP_GOOD:-} ]] && ! blank $RAW/$lang/$scene.png; then continue; fi
    limit 30 xcrun simctl terminate $DEVICE $BUNDLE_ID 2>/dev/null || true
    limit 240 xcrun simctl launch $DEVICE $BUNDLE_ID -screenshotScene $scene \
      -AppleLanguages "($lang)" -AppleLocale $locale >/dev/null || { echo "launch failed $lang/$scene"; continue; }
    # Under load the app may not have drawn yet: retry blank frames with a longer wait.
    for wait in 6 12 20; do
      sleep $wait
      limit 240 xcrun simctl io $DEVICE screenshot $RAW/$lang/$scene.png >/dev/null 2>&1 || true
      blank $RAW/$lang/$scene.png || break
      echo "blank $lang/$scene, retrying"
    done
    echo "captured $lang/$scene"
  done
done
limit 30 xcrun simctl terminate $DEVICE $BUNDLE_ID 2>/dev/null || true
limit 240 xcrun simctl status_bar $DEVICE clear

nice -n 19 python3 $ROOT/AppStore/compose_screenshots.py $RAW $OUT "$@"
