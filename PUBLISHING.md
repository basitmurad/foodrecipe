# Publishing Stepwise Kitchen to Google Play

App ID: `com.basitmurad.stepwisekitchen` — this can never change once uploaded to Play.

## 1. Create an upload key (once)

```sh
keytool -genkey -v -keystore ~/stepwise-upload.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
```

Back up this file and its passwords somewhere safe.

## 2. Point the build at it

Create `android/key.properties` (already git-ignored):

```properties
storePassword=<store password>
keyPassword=<key password>
keyAlias=upload
storeFile=/Users/<you>/stepwise-upload.jks
```

Without this file, release builds fall back to the debug key, which Play rejects.

## 3. Set up AdMob (once)

1. Sign in at https://admob.google.com and add an app: **Android**, "Is the app listed on a supported app store?" → **No** for now (link it after the Play listing is live).
2. Copy the **App ID** (`ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`) into `android/gradle.properties`:
   ```properties
   admobAppId=ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY
   ```
3. Create two ad units and note their IDs (`ca-app-pub-…/…`):
   - **Banner** (used as an anchored adaptive banner)
   - **Interstitial**
4. In AdMob → **Privacy & messaging**, create a **GDPR** message (and optionally a US states message) and publish it. The app's consent form shows whatever you publish there.
5. Add **app-ads.txt**: AdMob → Apps → your app → app-ads.txt gives you a line like
   `google.com, pub-XXXXXXXXXXXXXXXX, DIRECT, f08c47fec0942fa0`.
   Put it in a file named `app-ads.txt` at the root of the website you list on Play (for example `https://yoursite.com/app-ads.txt`). Without it, AdMob limits ad serving.

Until you do this, the app shows Google's **test ads**, which earn nothing. Never tap your own live ads: AdMob can suspend your account. Debug builds always use test ads.

## 4. Build

Bump `version:` in `pubspec.yaml` for every upload (`1.0.0+1` → `1.0.1+2`; the number after `+` must always increase).

```sh
flutter build appbundle --release \
  --dart-define=ADMOB_BANNER_ID=ca-app-pub-XXXXXXXXXXXXXXXX/1111111111 \
  --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-XXXXXXXXXXXXXXXX/2222222222
```

Upload `build/app/outputs/bundle/release/app-release.aab`.

## 5. Play Console checklist

- **Ads**: under App content, answer **Contains ads: Yes** and declare the **Advertising ID** use (advertising). Data safety answers for AdMob are in `docs/store-listing.md`.
- **Recipe data**: bundled in `assets/data/recipes.json` and `assets/data/unitools-recipes.json`; no API or key. The internet permission is only for ads. Add or edit recipes there; `flutter test` validates the file. A recipe can optionally set `"image": "assets/photos/x.jpg"` (add the folder to `pubspec.yaml`) to show a photo instead of the illustrated card.
- **Privacy policy URL**: `docs/privacy-policy.html`. Publish it for free with GitHub Pages: push to GitHub, then go to repo **Settings → Pages → Deploy from a branch → `master` / `/docs`**. The URL will be `https://basitmurad.github.io/foodrecipe/privacy-policy.html`. The same site also serves `terms.html` (Terms & Conditions) and a landing page at `https://basitmurad.github.io/foodrecipe/` that you can use as the app's website. Support email: apps.helpdesksupport@gmail.com.
- **Store listing text and graphics**: ready to paste from `docs/store-listing.md`; icon and feature graphic are in `docs/play/`.
- **Data safety form**: "No data collected" and "No data shared" are accurate for the current code.
- **Screenshots**: at least 2 phone screenshots (suggestions in `docs/store-listing.md`).
- **Content rating** questionnaire and **target audience** (not designed for children is simplest).
- New personal developer accounts must run a **closed test with 12+ testers for 14 days** before production access.
