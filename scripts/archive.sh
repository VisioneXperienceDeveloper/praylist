#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
mode="${1:---unsigned}"
if [[ "$mode" != "--signed" && "$mode" != "--unsigned" && "$mode" != "--distribution" ]]; then
  print -u2 'Usage: ./scripts/archive.sh [--unsigned|--signed|--distribution]'
  exit 2
fi
if [[ "$mode" == "--signed" || "$mode" == "--distribution" ]]; then
  : "${PRAYLIST_TEAM_ID:?Set PRAYLIST_TEAM_ID to the confirmed Apple Developer team}"
  : "${PRAYLIST_BUNDLE_ID:?Set PRAYLIST_BUNDLE_ID to the registered bundle identifier}"
  : "${PRAYLIST_SUPPORT_URL:?Set the live HTTPS support URL}"
fi
if [[ "$mode" == "--signed" ]]; then
  xcodebuild -project Praylist.xcodeproj -scheme Praylist -configuration Release \
    -allowProvisioningUpdates \
    -derivedDataPath build/ArchiveDerivedData \
    -destination 'generic/platform=iOS' -archivePath build/Praylist.xcarchive \
    DEVELOPMENT_TEAM="$PRAYLIST_TEAM_ID" PRODUCT_BUNDLE_IDENTIFIER="$PRAYLIST_BUNDLE_ID" \
    CODE_SIGN_STYLE=Automatic CURRENT_PROJECT_VERSION=2 \
    PRAYLIST_SUPPORT_URL="$PRAYLIST_SUPPORT_URL" archive
else
  xcodebuild -project Praylist.xcodeproj -scheme Praylist -configuration Release \
    -derivedDataPath build/ArchiveDerivedData \
    -destination 'generic/platform=iOS' -archivePath build/Praylist-unsigned.xcarchive \
    CURRENT_PROJECT_VERSION=2 CODE_SIGNING_ALLOWED=NO \
    PRAYLIST_SUPPORT_URL="${PRAYLIST_SUPPORT_URL:-}" archive
fi
if [[ "$mode" == "--distribution" ]]; then
  # Archive without development provisioning; Xcode signs the IPA for the App Store.
  # This export does not upload the build or register any test devices.
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :destination' release/ExportOptions.plist)" == "export" ]]
  xcodebuild -exportArchive -archivePath build/Praylist-unsigned.xcarchive \
    -exportOptionsPlist release/ExportOptions.plist -exportPath build/AppStoreExport \
    -allowProvisioningUpdates
fi
