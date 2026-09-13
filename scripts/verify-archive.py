#!/usr/bin/env python3
"""Read-only checks of a release archive or distribution-signed IPA."""
import argparse
import json
import plistlib
import re
import subprocess
import tempfile
import zipfile
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
source = parser.add_mutually_exclusive_group()
source.add_argument("--archive", type=Path)
source.add_argument("--ipa", type=Path)
parser.add_argument("--unsigned", action="store_true", help="Inspect an unsigned archive before distribution export")
parser.add_argument("--support-url", required=True)
args = parser.parse_args()

if args.ipa:
    if args.unsigned:
        parser.error("An App Store IPA must be distribution signed")
    extracted = tempfile.TemporaryDirectory(prefix="praylist-ipa-verification-", dir=ROOT / "build")
    with zipfile.ZipFile(args.ipa) as archive:
        archive.extractall(extracted.name)
    app = Path(extracted.name) / "Payload/Praylist.app"
else:
    args.archive = args.archive or ROOT / "build/Praylist.xcarchive"
    app = args.archive / "Products/Applications/Praylist.app"

def require(condition, message):
    if not condition:
        raise SystemExit("FAIL: " + message)

with (app / "Info.plist").open("rb") as file:
    info = plistlib.load(file)
require(info["CFBundleIdentifier"] == "com.visionexperiencedeveloper.praylist", "Unexpected bundle ID")
require(info["CFBundleShortVersionString"] == "1.0.0" and info["CFBundleVersion"] == "2", "Expected version 1.0.0, build 2")
require(info.get("DTPlatformName") == "iphoneos", "Expected a device archive, not a Simulator app")
require(info.get("PraylistSupportURL") == args.support_url, "Support URL is missing or does not match the verified public URL")
url = urlparse(args.support_url)
require(url.scheme == "https" and url.hostname and "$" not in args.support_url and "{{" not in args.support_url, "Support URL must be a concrete HTTPS URL")
require(set(info.get("CFBundleLocalizations", [])) == {"en", "ko"}, "Both English and Korean must be declared")
require(info.get("CFBundleDevelopmentRegion") == "en", "The fallback language must be English")

tables = {}
for language in ("en", "ko"):
    path = app / f"{language}.lproj/Localizable.strings"
    require(path.is_file(), f"Missing {language} localization bundle")
    # plutil accepts both text .strings and the compiled binary representation.
    tables[language] = json.loads(subprocess.check_output(["plutil", "-convert", "json", "-o", "-", str(path)]))
require(set(tables["en"]) == set(tables["ko"]), "English/Korean localization keys differ")
for language, table in tables.items():
    require(not any(re.search(r"소망|\bwishes?\b|Pray(?!list)", text) for text in table.values()), f"Unapproved terminology in {language} visible strings")

binary = (app / info["CFBundleExecutable"]).read_bytes()
for fixture in (b"--screenshots", b"--uitesting", b"--verify-reminder-delivery", b"--reset-language", b"ui-test.json", b"PreviewData"):
    require(fixture not in binary, "Debug fixture found in the release executable: " + fixture.decode())
require(not list(app.glob("*.debug.dylib")), "Debug-only dynamic library included")
icon = info.get("CFBundleIcons", {}).get("CFBundlePrimaryIcon", {})
require(icon.get("CFBundleIconName") == "AppIcon", "AppIcon is not configured as the primary icon")
require((app / "Assets.car").is_file() and list(app.glob("AppIcon*.png")), "Compiled app icon assets are missing")
for image in app.glob("AppIcon*.png"):
    details = subprocess.check_output(["sips", "-g", "hasAlpha", str(image)], text=True)
    require("hasAlpha: no" in details, f"App icon must be opaque: {image.name}")

with (app / "PrivacyInfo.xcprivacy").open("rb") as file:
    privacy = plistlib.load(file)
reasons = {entry["NSPrivacyAccessedAPIType"]: entry["NSPrivacyAccessedAPITypeReasons"] for entry in privacy["NSPrivacyAccessedAPITypes"]}
require("CA92.1" in reasons.get("NSPrivacyAccessedAPICategoryUserDefaults", []), "Language preference API reason is missing")
require(privacy.get("NSPrivacyTracking") is False and not privacy.get("NSPrivacyCollectedDataTypes"), "Privacy manifest declarations changed")
if not args.unsigned:
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
    signature = subprocess.run(["codesign", "-dv", "--verbose=4", str(app)], capture_output=True, text=True, check=True)
    require("TeamIdentifier=JS293ULS3A" in signature.stderr, "App signed by an unexpected team")
    profile = app / "embedded.mobileprovision"
    require(profile.is_file(), "Signed device app is missing its provisioning profile")
    if args.ipa:
        provisioning = plistlib.loads(subprocess.check_output(["security", "cms", "-D", "-i", str(profile)]))
        entitlements = provisioning["Entitlements"]
        require("JS293ULS3A" in provisioning["TeamIdentifier"], "Distribution profile belongs to a different team")
        require(entitlements.get("application-identifier") == "JS293ULS3A.com.visionexperiencedeveloper.praylist", "Distribution profile has the wrong App ID")
        require(entitlements.get("get-task-allow") is False, "Distribution profile allows debugging")
        require("ProvisionedDevices" not in provisioning and not provisioning.get("ProvisionsAllDevices"), "Expected an App Store profile without registered devices")
        signed = plistlib.loads(subprocess.check_output(["codesign", "-d", "--entitlements", "-", "--xml", str(app)], stderr=subprocess.PIPE))
        require(signed.get("application-identifier") == "JS293ULS3A.com.visionexperiencedeveloper.praylist", "Signed entitlements have the wrong App ID")
        require(signed.get("get-task-allow") is False, "Signed app allows debugging")
print(json.dumps({"status": "PASS", "artifact": str(args.ipa or args.archive), "signing": "unsigned archive" if args.unsigned else "verified signature", "bundleId": info["CFBundleIdentifier"], "version": info["CFBundleShortVersionString"], "build": info["CFBundleVersion"], "languages": ["en", "ko"], "localizationKeys": len(tables["en"]), "supportURL": args.support_url, "team": None if args.unsigned else "JS293ULS3A", "icon": "opaque compiled AppIcon", "debugFixtures": "absent"}, indent=2))
