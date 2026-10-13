#!/usr/bin/env python3
"""
Run ONCE after `flutter create` (see README). Idempotent.

Patches the generated native projects with what this app needs:
  * Android: INTERNET + legacy WRITE_EXTERNAL_STORAGE (API <= 29) permissions
  * iOS: photo-library usage strings (required by the `gal` plugin) and
         a 13.0 deployment target (minimum supported by `gal`)
"""
import pathlib
import re

root = pathlib.Path(__file__).resolve().parent.parent


def patch_android():
    f = root / "android/app/src/main/AndroidManifest.xml"
    if not f.exists():
        print("! AndroidManifest.xml not found - did you run flutter create?")
        return
    text = f.read_text(encoding="utf-8")
    additions = []
    if "android.permission.INTERNET" not in text:
        additions.append('    <uses-permission android:name="android.permission.INTERNET"/>')
    if "WRITE_EXTERNAL_STORAGE" not in text:
        additions.append(
            '    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" '
            'android:maxSdkVersion="29"/>'
        )
    if additions:
        idx = text.index("<application")
        text = text[:idx] + "\n".join(additions) + "\n    " + text[idx:]
        f.write_text(text, encoding="utf-8")
        print("✓ Android manifest patched")
    else:
        print("✓ Android manifest already patched")


def patch_ios():
    plist = root / "ios/Runner/Info.plist"
    if plist.exists():
        text = plist.read_text(encoding="utf-8")
        entries = {
            "NSPhotoLibraryAddUsageDescription":
                "Saves images you download into your photo library.",
            "NSPhotoLibraryUsageDescription":
                "Needed to save downloaded images into the app's photo album.",
        }
        changed = False
        for key, value in entries.items():
            if key not in text:
                idx = text.rindex("</dict>")
                text = text[:idx] + f"\t<key>{key}</key>\n\t<string>{value}</string>\n" + text[idx:]
                changed = True
        if changed:
            plist.write_text(text, encoding="utf-8")
            print("✓ iOS Info.plist patched")
        else:
            print("✓ iOS Info.plist already patched")

    pbx = root / "ios/Runner.xcodeproj/project.pbxproj"
    if pbx.exists():
        t = pbx.read_text(encoding="utf-8")
        t2 = re.sub(r"IPHONEOS_DEPLOYMENT_TARGET = 1[0-2]\.\d;", "IPHONEOS_DEPLOYMENT_TARGET = 13.0;", t)
        if t2 != t:
            pbx.write_text(t2, encoding="utf-8")
            print("✓ iOS deployment target -> 13.0")
    podfile = root / "ios/Podfile"
    if podfile.exists():
        t = podfile.read_text(encoding="utf-8")
        t2 = re.sub(r"^#?\s*platform :ios, '[\d.]+'", "platform :ios, '13.0'", t, flags=re.M)
        if t2 != t:
            podfile.write_text(t2, encoding="utf-8")
            print("✓ Podfile platform -> 13.0")


if __name__ == "__main__":
    patch_android()
    patch_ios()
    print("Done. Now run: flutter pub get")
