# Stepwise Kitchen

A calm, offline recipe app built with Flutter: 530 recipes from 127 countries, with nutrition, a daily pick, ingredient checklists and a step-by-step Cook Mode. No account needed; recipes work offline. Free, supported by Google AdMob ads.

![Stepwise Kitchen feature graphic](docs/play/feature-graphic.png)

## Features

- **Discover**: a daily recipe pick (or a random one), a "Ready in 30 minutes" row, and browsing by category
- **Recipe pages**: total time, servings, difficulty, nutrition per serving, an ingredient checklist you can tick off, and numbered steps with timings
- **Cook Mode**: one large step per screen with a progress bar
- **Search**: instant matching on dish, cuisine, tag or ingredient
- **Saved**: favourites stored on the device
- Light and dark themes, bundled fonts; recipes work fully offline
- Ads: a bottom banner and an occasional full-screen ad (at most every 4 recipes, 3-minute cooldown, never in Cook Mode), with Google's UMP consent form. See `lib/services/ads.dart` and PUBLISHING.md for AdMob setup

## Getting started

```sh
flutter pub get
flutter run
flutter test
```

## Project layout

```
assets/data/recipes.json     Our own 32 recipes and the category list
assets/data/unitools-recipes.json
                             498 recipes adapted from UniTools (CC BY-SA 4.0)
assets/fonts/                Fraunces, Plus Jakarta Sans, Noto Color Emoji subset (OFL)
assets/icon/                 Launcher icon sources (flutter_launcher_icons)
lib/models/recipe.dart       Recipe, Ingredient, RecipeCategory
lib/services/                Recipe repository and on-device favourites
lib/theme/app_theme.dart     Colours, typography, light/dark themes
lib/views/                   Discover, Search, Saved, recipe detail, Cook Mode, About
tool/import_unitools.py      Regenerates unitools-recipes.json from the UniTools dataset
docs/                        Privacy policy (GitHub Pages) and Play Store listing
```

## Adding a recipe

Append an entry to `recipes` in `assets/data/recipes.json` (optional fields: `nativeName`, `stepMinutes`, `nutrition`):

```json
{
  "id": "unique-kebab-case-id",
  "name": "Dish Name",
  "category": "Pasta",
  "cuisine": "Italian",
  "emoji": "🍝",
  "prepMinutes": 10,
  "cookMinutes": 20,
  "servings": 4,
  "difficulty": "Easy",
  "tags": ["Quick", "Vegetarian"],
  "description": "One enticing sentence.",
  "ingredients": [["200 g", "Spaghetti"], ["2 tbsp", "Olive oil"]],
  "steps": ["First step.", "Second step."]
}
```

`category` must match one of the `categories`. To show a photo instead of the illustrated card, add `"image": "assets/photos/dish.jpg"` and list that folder under `assets:` in `pubspec.yaml`. Run `flutter test` afterwards to catch mistakes.

## Recipe data and licences

- `assets/data/recipes.json` holds the recipes written for this app.
- `assets/data/unitools-recipes.json` is adapted from [UniTools World Recipes](https://github.com/farcrak/unitools-recipes) and is licensed **CC BY-SA 4.0**. Attribution: *Recipe data: UniTools (theunitools.com), CC BY-SA 4.0*. The app shows this credit on each adapted recipe and on the About screen. To update it, download the latest `unitools-recipes-v1.json` and run `python3 tool/import_unitools.py path/to/unitools-recipes-v1.json`.
- Emoji come from a subset of [Noto Color Emoji](https://github.com/googlefonts/noto-emoji) (OFL) so they render the same on every device. If you add a recipe with a new emoji, `flutter test` tells you which characters to add to the subset (`pyftsubset NotoColorEmoji.ttf --unicodes=... --drop-tables+=SVG`).

## Releasing

See [PUBLISHING.md](PUBLISHING.md) for signing and building, and [docs/store-listing.md](docs/store-listing.md) for the Play Store text and graphics. The privacy policy lives at `docs/privacy-policy.html`.
