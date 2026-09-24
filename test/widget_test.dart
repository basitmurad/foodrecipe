import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:foodrecipe/main.dart';
import 'package:foodrecipe/models/recipe.dart';
import 'package:foodrecipe/services/favorites_store.dart';
import 'package:foodrecipe/services/recipe_repository.dart';

void main() {
  final repo = RecipeRepository.fromJson(
    jsonDecode(File('assets/data/recipes.json').readAsStringSync())
        as Map<String, dynamic>,
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

    test('every recipe is complete', () {
      for (final r in repo.recipes) {
        expect(r.ingredients, isNotEmpty, reason: r.id);
        expect(r.steps, isNotEmpty, reason: r.id);
        expect(r.description, isNotEmpty, reason: r.id);
        expect(r.servings, greaterThan(0), reason: r.id);
        expect(r.totalMinutes, greaterThan(0), reason: r.id);
      }
    });

    test('every category has recipes', () {
      for (final c in repo.categories) {
        expect(repo.byCategory(c.name), isNotEmpty, reason: c.name);
      }
    });
  });

  group('RecipeRepository', () {
    test('search matches names, ingredients and tags, all words required', () {
      expect(repo.search('carbonara').map((r) => r.id), ['carbonara']);
      expect(repo.search('chickpeas').map((r) => r.id),
          containsAll(['chana-masala', 'baked-falafel']));
      expect(repo.search('vegan soup').map((r) => r.id), ['red-lentil-soup']);
      expect(repo.search('   '), isEmpty);
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
    await tester.pumpWidget(MyApp(repo: repo, favorites: favorites));

    expect(find.text('What\'s cooking\ntoday?'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Save recipe').first);
    await tester.pump();

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 recipe in your cookbook'), findsOneWidget);
    expect(favorites.items, hasLength(1));
  });
}
