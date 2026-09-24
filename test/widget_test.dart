import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:foodrecipe/main.dart';
import 'package:foodrecipe/models/recipe.dart';
import 'package:foodrecipe/services/ads.dart';
import 'package:foodrecipe/services/favorites_store.dart';
import 'package:foodrecipe/services/recipe_repository.dart';

Map<String, dynamic> _readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Code points mapped by a TrueType font's format-12 cmap subtable.
Set<int> _fontCodePoints(String path) {
  final data = ByteData.sublistView(File(path).readAsBytesSync());
  final numTables = data.getUint16(4);
  var cmap = -1;
  for (var i = 0; i < numTables; i++) {
    final rec = 12 + i * 16;
    final tag = String.fromCharCodes(
        data.buffer.asUint8List(data.offsetInBytes + rec, 4));
    if (tag == 'cmap') cmap = data.getUint32(rec + 8);
  }
  final points = <int>{};
  for (var i = 0; i < data.getUint16(cmap + 2); i++) {
    final sub = cmap + data.getUint32(cmap + 4 + i * 8 + 4);
    if (data.getUint16(sub) != 12) continue;
    for (var g = 0; g < data.getUint32(sub + 12); g++) {
      final group = sub + 16 + g * 12;
      for (var c = data.getUint32(group); c <= data.getUint32(group + 4); c++) {
        points.add(c);
      }
    }
  }
  return points;
}

void main() {
  final unitools = _readJson(RecipeRepository.unitoolsAsset);
  final repo = RecipeRepository.fromJson(
    _readJson(RecipeRepository.ownAsset),
    [unitools],
  );

  group('bundled recipes', () {
    test('have unique ids and valid categories', () {
      final ids = repo.recipes.map((r) => r.id).toSet();
      expect(ids.length, repo.recipes.length);
      final categories = repo.categories.map((c) => c.name).toSet();
      for (final r in repo.recipes) {
        expect(categories, contains(r.category), reason: r.id);
      }
    });

    test('include our own recipes and the UniTools collection', () {
      expect(repo.ownRecipeCount, 32);
      expect(repo.recipes.length, greaterThan(500));
      expect(repo.datasets.single.license, 'CC BY-SA 4.0');
    });

    test('every recipe is complete', () {
      for (final r in repo.recipes) {
        expect(r.ingredients, isNotEmpty, reason: r.id);
        expect(r.steps, isNotEmpty, reason: r.id);
        expect(r.description, isNotEmpty, reason: r.id);
        expect(r.emoji, isNotEmpty, reason: r.id);
        expect(r.servings, greaterThan(0), reason: r.id);
        expect(r.totalMinutes, greaterThan(0), reason: r.id);
        if (r.stepMinutes.isNotEmpty) {
          expect(r.stepMinutes.length, r.steps.length, reason: r.id);
        }
      }
    });

    test('imported recipes carry attribution and nutrition', () {
      final imported = repo.recipes.where((r) => r.id.startsWith('ut-'));
      expect(imported.length, (unitools['recipes'] as List).length);
      for (final r in imported) {
        expect(r.source?.name, 'UniTools', reason: r.id);
        expect(r.source?.url, startsWith('https://theunitools.com/'), reason: r.id);
        expect(r.nutrition, isNotNull, reason: r.id);
      }
    });

    test('every emoji is in the bundled emoji font', () {
      final font = _fontCodePoints('assets/fonts/NotoColorEmoji-Subset.ttf');
      final used = {
        for (final r in repo.recipes) ...r.emoji.runes,
        for (final c in repo.categories) ...c.emoji.runes,
        ...'🍽️'.runes,
      }..remove(0xFE0F); // variation selector, not a glyph
      final missing = used.difference(font).map(String.fromCharCode);
      expect(missing, isEmpty,
          reason: 'Re-subset the emoji font to include: ${missing.join()}');
    });

    test('every category has recipes', () {
      for (final c in repo.categories) {
        expect(repo.byCategory(c.name), isNotEmpty, reason: c.name);
      }
    });
  });

  group('RecipeRepository', () {
    test('search matches names, ingredients and tags, all words required', () {
      expect(repo.search('carbonara').map((r) => r.id).first, 'carbonara');
      expect(repo.search('chickpeas').map((r) => r.id),
          containsAll(['chana-masala', 'baked-falafel']));
      final veganSoups = repo.search('vegan soup');
      expect(veganSoups.map((r) => r.id), contains('red-lentil-soup'));
      for (final r in veganSoups) {
        expect(r.matches('vegan') && r.matches('soup'), isTrue);
      }
      expect(repo.search('   '), isEmpty);
    });

    test('search finds dishes by their native name', () {
      final withNative = repo.recipes.firstWhere((r) => r.nativeName != null);
      expect(repo.search(withNative.nativeName!), contains(withNative));
    });

    test('quick picks are quick, capped and stable for a day', () {
      final morning = repo.quickPicks(now: DateTime(2026, 9, 24, 7));
      expect(morning.length, 12);
      expect(morning.every((r) => r.totalMinutes <= 30), isTrue);
      expect(repo.quickPicks(now: DateTime(2026, 9, 24, 22)), morning);
    });

    test('recipe of the day is stable within a day', () {
      final morning = repo.recipeOfTheDay(DateTime(2026, 9, 24, 7));
      final night = repo.recipeOfTheDay(DateTime(2026, 9, 24, 23));
      final next = repo.recipeOfTheDay(DateTime(2026, 9, 25, 7));
      expect(morning.id, night.id);
      expect(next.id, isNot(morning.id));
    });

    test('random never repeats the excluded recipe', () {
      for (var i = 0; i < 50; i++) {
        expect(repo.random(excludeId: 'carbonara').id, isNot('carbonara'));
      }
    });
  });

  test('formatMinutes', () {
    expect(formatMinutes(25), '25 min');
    expect(formatMinutes(60), '1 h');
    expect(formatMinutes(95), '1 h 35 min');
  });

  testWidgets('saving a recipe shows it in the Saved tab', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final favorites = await FavoritesStore.load(repo);
    await tester.pumpWidget(MyApp(repo: repo, favorites: favorites, ads: Ads.disabled()));

    expect(find.text('What\'s cooking\ntoday?'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Save recipe').first);
    await tester.pump();

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 recipe in your cookbook'), findsOneWidget);
    expect(favorites.items, hasLength(1));
  });

  testWidgets('About screen credits the recipe sources', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final favorites = await FavoritesStore.load(repo);
    await tester.pumpWidget(MyApp(repo: repo, favorites: favorites, ads: Ads.disabled()));

    await tester.tap(find.byTooltip('About'));
    await tester.pumpAndSettle();
    expect(find.textContaining('32 recipes were written for'), findsOneWidget);
    expect(
      find.textContaining('recipes are adapted from UniTools World Recipes'),
      findsOneWidget,
    );
    expect(find.textContaining('CC BY-SA 4.0'), findsWidgets);
  });

  group('InterstitialPacer', () {
    test('waits for 4 recipes, then respects the 3-minute cooldown', () {
      var now = DateTime(2026, 9, 24, 12);
      final pacer = InterstitialPacer(now: () => now);

      expect([for (var i = 0; i < 3; i++) pacer.recipeClosed()],
          [false, false, false]);
      expect(pacer.recipeClosed(), isTrue);
      pacer.markShown();

      // Four more recipes within a minute: still cooling down.
      now = now.add(const Duration(minutes: 1));
      expect([for (var i = 0; i < 4; i++) pacer.recipeClosed()].last, isFalse);

      // After the cooldown, the next closed recipe may show an ad.
      now = now.add(const Duration(minutes: 2));
      expect(pacer.recipeClosed(), isTrue);
    });
  });
}
