# Google Play store listing — Stepwise Kitchen

Copy each field into **Play Console → Grow → Store presence → Main store listing**.

## App name (max 30)

```
Stepwise Kitchen: Easy Recipes
```

## Short description (max 80)

```
530 recipes from 127 countries, with nutrition and a step-by-step Cook Mode.
```

## Full description (max 4000)

```
Stepwise Kitchen is a calm, beautiful cookbook that fits in your pocket — free, no sign-up, and every recipe works offline.

Explore 530 home-cooking recipes from 127 countries. Every recipe has clear ingredients, simple numbered steps, and honest cooking times, so you can stop scrolling and start cooking.

🍳 TODAY'S PICK
A new dish every day to spark ideas. Not feeling it? Tap the dice for a surprise.

🔥 COOK MODE
Big, easy-to-read steps, one at a time, with how long each step takes. Swipe or tap "Next step" with messy hands and never lose your place in a recipe again.

🥗 NUTRITION AT A GLANCE
Calories, protein, carbs and fat per serving for more than 490 recipes.

✅ INGREDIENT CHECKLIST
Tick ingredients off as you gather them, so nothing gets forgotten.

⏱️ READY IN 30 MINUTES
Busy evening? Jump straight to dishes that are on the table in half an hour.

🔍 SMART SEARCH
Search by dish, cuisine, or ingredient. Have chickpeas? Stepwise Kitchen finds Chana Masala and Crispy Falafel instantly.

❤️ YOUR PERSONAL COOKBOOK
Save your favourites with one tap. They're stored only on your phone.

🌍 FLAVOURS FROM AROUND THE WORLD
From Georgian khinkali and Mongolian buuz to Peruvian lomo saltado, Persian tahdig and Ethiopian doro wat, across eleven categories: Breakfast, Chicken, Meat, Seafood, Vegetarian, Pasta & Noodles, Soup, Salads & Sides, Snacks & Sauces, Breads & Baking and Dessert.

Search by a dish's English or original name. Highlights include Butter Chicken, Pad Thai, Coq au Vin, Rendang, Tiramisu, Crème Brûlée and hundreds more, with plenty of vegetarian, vegan and gluten-free options.

🌙 LIGHT & DARK THEMES
A warm, easy-on-the-eyes design that follows your phone's theme.

📶 WORKS OFFLINE
All 530 recipes are built into the app, so they're there in the kitchen, on holiday, or anywhere with a weak signal. No account needed.

Happy cooking! 🍽️

Recipe data includes recipes adapted from UniTools (theunitools.com), licensed CC BY-SA 4.0.
```

## Other listing settings

| Field | Value |
|---|---|
| App category | Food & Drink |
| Tags (pick up to 5) | Recipes, Cooking, Food & Drink, Meal planning, Cookbook |
| Contact email | apps.helpdesksupport@gmail.com |
| Website | https://basitmurad.github.io/foodrecipe/ |
| Privacy policy URL | https://basitmurad.github.io/foodrecipe/privacy-policy.html |
| Terms & Conditions | https://basitmurad.github.io/foodrecipe/terms.html (not a Play field; linked from the website and the app's About screen) |
| Contains ads | **Yes** (Google AdMob) |
| Advertising ID | **Yes**, used for advertising (declare under App content → Advertising ID) |
| App access | All functionality available without special access |

## Graphics

| Asset | Size | File |
|---|---|---|
| App icon | 512 × 512 PNG | `docs/play/icon-512.png` |
| Feature graphic | 1024 × 500 PNG | `docs/play/feature-graphic.png` |
| Phone screenshots | 2–8, 9:16 or 16:9, min 320 px | Take from the emulator (see below) |

Suggested screenshots, in order:
1. Discover: the Today's pick card
2. The recipe grid with category bubbles
3. A recipe page showing time, servings and difficulty
4. Cook Mode on a step
5. Search results for "chickpeas"
6. The Saved tab with a few favourites

Take them with the app running on the emulator:

```sh
adb exec-out screencap -p > screenshot-1.png
```

## Data safety form answers

The app itself collects nothing, but the Google Mobile Ads SDK does. Google publishes the answers for its SDK here; check it before submitting, as it's updated from time to time: https://developers.google.com/admob/android/privacy/play-data-disclosure

- Does your app collect or share any of the required user data types? **Yes**
- Is all of the user data collected by your app encrypted in transit? **Yes**
- Do you provide a way for users to request that their data be deleted? **No** (the app has no accounts; users can reset their advertising ID in Android settings)

Data types to declare (collected **and** shared, by the Google Mobile Ads SDK):

| Data type | Collected / shared | Purposes |
|---|---|---|
| Location → Approximate location (from IP address) | Yes / Yes | Advertising or marketing, Analytics, Fraud prevention, security and compliance |
| App activity → App interactions | Yes / Yes | Advertising or marketing, Analytics, Fraud prevention, security and compliance |
| App info and performance → Crash logs, Diagnostics | Yes / Yes | Analytics, Fraud prevention, security and compliance |
| Device or other IDs (advertising ID) | Yes / Yes | Advertising or marketing, Analytics, Fraud prevention, security and compliance |

For each: processed ephemerally **No**; collection required **Yes** (users can't turn off ads in the app).

## Content rating questionnaire

Note: about 70 recipes use wine, beer or other alcohol as a cooking ingredient (e.g. Coq au Vin, Risotto alla Milanese). If the questionnaire asks about references to alcohol, answer **Yes**. Recipe apps that cook with wine are normally still rated for general audiences, but the questionnaire decides the final rating.


Category: **Reference, News, or Educational**. Answer **No** to violence, sexuality, language, gambling, user interaction, sharing location and purchases.

## Target audience

Choose **18 and over** (or 13+). Don't include under-13 age groups: apps for children must use only Families-certified ad SDKs and follow stricter ad rules.
