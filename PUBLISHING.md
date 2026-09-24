# Publishing Savora to Google Play

App ID: `com.basitmurad.foodrecipe` — this can never change once uploaded to Play.

## 1. Create an upload key (once)

```sh
keytool -genkey -v -keystore ~/savora-upload.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
```

Back up this file and its passwords somewhere safe.

## 2. Point the build at it

Create `android/key.properties` (already git-ignored):

```properties
storePassword=<store password>
keyPassword=<key password>
keyAlias=upload
storeFile=/Users/<you>/savora-upload.jks
```

Without this file, release builds fall back to the debug key, which Play rejects.

## 3. Build

Bump `version:` in `pubspec.yaml` for every upload (`1.0.0+1` → `1.0.1+2`; the number after `+` must always increase).

```sh
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab`.

## 4. Play Console checklist

- **Recipe data**: bundled in `assets/data/recipes.json` — no API, no key, no internet permission. Add or edit recipes there; `flutter test` validates the file. A recipe can optionally set `"image": "assets/photos/x.jpg"` (add the folder to `pubspec.yaml`) to show a photo instead of the illustrated card.
- **Privacy policy URL**: `docs/privacy-policy.html`. Publish it for free with GitHub Pages: push to GitHub, then go to repo **Settings → Pages → Deploy from a branch → `master` / `/docs`**. The URL will be `https://basitmurad.github.io/foodrecipe/privacy-policy.html`.
- **Store listing text and graphics**: ready to paste from `docs/store-listing.md`; icon and feature graphic are in `docs/play/`.
- **Data safety form**: "No data collected" and "No data shared" are accurate for the current code.
- **Screenshots**: at least 2 phone screenshots (suggestions in `docs/store-listing.md`).
- **Content rating** questionnaire and **target audience** (not designed for children is simplest).
- New personal developer accounts must run a **closed test with 12+ testers for 14 days** before production access.
