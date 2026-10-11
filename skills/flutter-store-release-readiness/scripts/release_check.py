#!/usr/bin/env python3
"""Pre-submission scan of a Flutter app for common App Store / Play rejections.

Usage: python3 -I release_check.py <flutter-app-root>

Reads files only. Prints FAIL / WARN / OK lines; exit 1 if any FAIL.
Heuristic: confirm each finding in the code before acting on it.
"""
import re
import sys
from pathlib import Path

results = []


def add(level, msg):
    results.append((level, msg))


def read(p: Path) -> str:
    try:
        return p.read_text(errors="ignore")
    except OSError:
        return ""


def main(root: Path) -> int:
    pub = read(root / "pubspec.yaml")
    if not pub:
        print(f"error: no pubspec.yaml in {root}")
        return 2
    deps = set(re.findall(r"^\s{2}([a-z0-9_]+):", pub, re.M))
    has = deps.__contains__
    lib = "\n".join(read(p) for p in (root / "lib").rglob("*.dart")
                    if "/generated/" not in str(p) and not p.name.endswith((".g.dart", ".freezed.dart")))

    # ---------------- Versioning ----------------
    m = re.search(r"^version:\s*([\d.]+)\+(\d+)", pub, re.M)
    add("OK" if m else "FAIL", f"pubspec version with build number ({m.group(0) if m else 'missing +BUILD'})")

    # ---------------- iOS ----------------
    ios = root / "ios" / "Runner"
    if ios.exists():
        plist = read(ios / "Info.plist")
        pbx = read(root / "ios" / "Runner.xcodeproj" / "project.pbxproj")
        ent = read(ios / "Runner.entitlements")

        pm = ios / "PrivacyInfo.xcprivacy"
        if not pm.exists():
            add("FAIL", "ios/Runner/PrivacyInfo.xcprivacy missing (required privacy manifest)")
        elif "PrivacyInfo.xcprivacy" not in pbx:
            add("FAIL", "PrivacyInfo.xcprivacy exists but is not in the Xcode project (not bundled)")
        else:
            pmt = read(pm)
            add("OK", "privacy manifest bundled")
            if "<key>NSPrivacyTracking</key>\n  <true/>" in pmt or re.search(r"NSPrivacyTracking</key>\s*<true/>", pmt):
                add("WARN", "NSPrivacyTracking is true — requires ATT prompt + tracking domains")
            if "UserDefaults" not in pmt and has("shared_preferences"):
                add("WARN", "shared_preferences used but no UserDefaults required-reason (CA92.1) in manifest")

        configs = len(re.findall(r"isa = XCBuildConfiguration;", pbx))
        signed = len(re.findall(r"CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements", pbx))
        if has("firebase_messaging") or has("sign_in_with_apple") or has("firebase_app_check"):
            if not ent:
                add("FAIL", "Runner.entitlements missing but push / Sign in with Apple / App Attest are used")
            else:
                add("OK" if signed else "FAIL", f"CODE_SIGN_ENTITLEMENTS set in {signed} build configs (of {configs} total incl. Pods/targets)")
        if has("firebase_messaging"):
            add("OK" if "aps-environment" in ent else "FAIL", "aps-environment entitlement (push)")
            add("OK" if "remote-notification" in plist else "WARN", "UIBackgroundModes remote-notification (only needed for silent/data FCM messages)")
        if has("google_sign_in") or has("flutter_facebook_auth"):
            add("OK" if has("sign_in_with_apple") else "FAIL", "Sign in with Apple offered alongside third-party login (Guideline 4.8)")
            if "GOOGLE_REVERSED_CLIENT_ID" not in plist and "com.googleusercontent.apps" not in plist:
                add("FAIL", "Google Sign-In URL scheme (REVERSED_CLIENT_ID) not in Info.plist")
        if has("sign_in_with_apple"):
            add("OK" if "applesignin" in ent else "FAIL", "com.apple.developer.applesignin entitlement")
        if has("firebase_app_check"):
            add("OK" if "appattest" in ent else "WARN", "App Attest entitlement (App Check)")

        usage = {
            "image_picker": ["NSPhotoLibraryUsageDescription", "NSCameraUsageDescription"],
            "camera": ["NSCameraUsageDescription"],
            "record": ["NSMicrophoneUsageDescription"],
            "flutter_sound": ["NSMicrophoneUsageDescription"],
            "speech_to_text": ["NSMicrophoneUsageDescription", "NSSpeechRecognitionUsageDescription"],
            "geolocator": ["NSLocationWhenInUseUsageDescription"],
            "permission_handler": [],
        }
        for dep, keys in usage.items():
            if has(dep):
                for k in keys:
                    add("OK" if k in plist else "FAIL", f"{k} present ({dep})")
        if has("just_audio") or has("audio_service") or has("audioplayers"):
            add("OK" if "<string>audio</string>" in plist else "WARN", "UIBackgroundModes audio (background playback)")
        add("OK" if "ITSAppUsesNonExemptEncryption" in plist else "WARN",
            "ITSAppUsesNonExemptEncryption declared in Info.plist (else App Store Connect asks export compliance on every build)")

        arbs = sorted({p.stem.split("_", 1)[1] for p in (root / "lib").rglob("app_*.arb")})
        if len(arbs) > 1:
            loc = re.search(r"CFBundleLocalizations</key>\s*<array>(.*?)</array>", plist, re.S)
            listed = set(re.findall(r"<string>([^<]+)</string>", loc.group(1))) if loc else set()
            missing = [a for a in arbs if a not in listed]
            add("OK" if not missing else "FAIL", f"CFBundleLocalizations lists ARB locales {arbs} (missing: {missing or '-'})")

        if "GoogleService-Info.plist in Resources" in pbx and (root / "flavorizr.yaml").exists():
            add("WARN", "GoogleService-Info.plist is in Copy Bundle Resources with flavors — dev builds may hit prod; prefer Dart-side options")

    # ---------------- Android ----------------
    man = read(root / "android" / "app" / "src" / "main" / "AndroidManifest.xml")
    if man:
        for perm in ["READ_MEDIA_IMAGES", "READ_MEDIA_VIDEO", "READ_MEDIA_AUDIO", "READ_EXTERNAL_STORAGE"]:
            if re.search(rf'{perm}"(?![^>]*tools:node="remove")', man):
                add("WARN", f"{perm} requested — Play requires a core-use declaration; prefer Photo Picker")
        if has("firebase_analytics") or has("google_mobile_ads"):
            ok = re.search(r'AD_ID"[^>]*tools:node="remove"', man) or has("google_mobile_ads")
            add("OK" if ok else "WARN", "AD_ID permission removed (or declared in Play Console if you use ads)")
        if has("firebase_messaging"):
            add("OK" if "default_notification_icon" in man else "FAIL", "FCM default_notification_icon (monochrome) set")
            add("OK" if "POST_NOTIFICATIONS" in man else "WARN", "POST_NOTIFICATIONS permission (Android 13+)")
        add("OK" if "dataExtractionRules" in man else "WARN", "android:dataExtractionRules (exclude offline/paid files from backup)")

    gradle = read(root / "android" / "app" / "build.gradle.kts") or read(root / "android" / "app" / "build.gradle")
    if gradle:
        t = re.search(r"targetSdk(?:Version)?\s*=?\s*(\d+)", gradle)
        if t:
            add("OK" if int(t.group(1)) >= 35 else "FAIL", f"targetSdk {t.group(1)} (check Play's current minimum)")
        else:
            add("WARN", "targetSdk comes from flutter.targetSdkVersion — confirm it meets Play's minimum")
        if re.search(r"release\s*\{[^}]*signingConfig\s*=?\s*signingConfigs\.(getByName\(\"debug\"\)|debug)", gradle, re.S):
            add("FAIL", "release build signed with the debug key")

    # ---------------- Dart behaviour ----------------
    boot = read(root / "lib" / "main.dart") + read(root / "lib" / "bootstrap.dart")
    if "requestPermission(" in boot:
        add("WARN", "notification permission requested at launch — ask in context instead")
    if has("firebase_auth"):
        add("OK" if re.search(r"deleteAccount|deleteUser|\.delete\(\)", lib) else "FAIL",
            "in-app account deletion (App Store 5.1.1(v), Play policy)")
    if has("in_app_purchase"):
        add("OK" if "restorePurchases" in lib else "WARN", "Restore Purchases entry point (needed for non-consumables/subscriptions)")
        add("OK" if re.search(r"verify(Purchase|Subscription)|httpsCallable\(['\"]verify", lib) else "FAIL",
            "purchases verified server-side")
    if has("firebase_app_check"):
        add("OK" if "FirebaseAppCheck.instance.activate" in lib else "WARN", "App Check activated")
    add("OK" if re.search(r"min_build_|forceUpdate|AppUpdateGate", lib) else "WARN", "force-update mechanism")
    if re.search(r"onPressed:\s*\(\)\s*\{\s*\}|onPressed:\s*\(\)\s*\{\s*//\s*TODO", lib):
        add("WARN", "empty onPressed handlers found — hide unfinished controls (App Review 2.1)")
    if re.search(r"(?i)coming soon", lib):
        add("WARN", "'coming soon' text found — placeholder features are a common 2.1 rejection")

    order = {"FAIL": 0, "WARN": 1, "OK": 2}
    for level, msg in sorted(results, key=lambda r: order[r[0]]):
        print(f"[{level}] {msg}")
    fails = sum(1 for l, _ in results if l == "FAIL")
    print(f"\n{fails} FAIL, {sum(1 for l, _ in results if l == 'WARN')} WARN")
    return 1 if fails else 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(Path(sys.argv[1])))
