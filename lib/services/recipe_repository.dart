import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'package:foodrecipe/models/recipe.dart';

/// Licence and attribution for an imported recipe collection.
class Dataset {
  final String name;
  final String homepage;
  final String license;
  final String licenseUrl;
  final String attribution;
  final String changes;
  final int count;

  const Dataset({
    required this.name,
    required this.homepage,
    required this.license,
    required this.licenseUrl,
    required this.attribution,
    required this.changes,
    required this.count,
  });
}

/// All recipes ship inside the app, so it works fully offline and needs no
/// API key:
///  * assets/data/recipes.json — the app's own recipes and the category list
///  * assets/data/unitools-recipes.json — adapted from UniTools, CC BY-SA 4.0
///    (regenerate with tool/import_unitools.py)
class RecipeRepository {
  static const ownAsset = 'assets/data/recipes.json';
  static const unitoolsAsset = 'assets/data/unitools-recipes.json';

  final List<RecipeCategory> categories;
  final List<Recipe> recipes;
  final List<Dataset> datasets;
  final Map<String, Recipe> _byId;
  final Map<String, RecipeCategory> _categoryByName;

  RecipeRepository({
    required this.categories,
    required this.recipes,
    this.datasets = const [],
  })  : _byId = {for (final r in recipes) r.id: r},
        _categoryByName = {for (final c in categories) c.name: c};

  /// [own] holds the categories; each of [imported] adds recipes plus a
  /// `source` block describing its licence.
  factory RecipeRepository.fromJson(
    Map<String, dynamic> own, [
    List<Map<String, dynamic>> imported = const [],
  ]) {
    List<Recipe> parse(Map<String, dynamic> json) => (json['recipes'] as List)
        .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
        .toList();

    return RecipeRepository(
      categories: (own['categories'] as List)
          .map((c) => RecipeCategory.fromJson(c as Map<String, dynamic>))
          .toList(),
      recipes: [parse(own), ...imported.map(parse)].expand((r) => r).toList(),
      datasets: [
        for (final json in imported)
          Dataset(
            name: json['source']['name'] as String,
            homepage: json['source']['homepage'] as String,
            license: json['source']['license'] as String,
            licenseUrl: json['source']['licenseUrl'] as String,
            attribution: json['source']['attribution'] as String,
            changes: json['source']['changes'] as String,
            count: (json['recipes'] as List).length,
          ),
      ],
    );
  }

  static Future<RecipeRepository> load() async {
    Future<Map<String, dynamic>> read(String asset) async =>
        jsonDecode(await rootBundle.loadString(asset)) as Map<String, dynamic>;
    return RecipeRepository.fromJson(
      await read(ownAsset),
      [await read(unitoolsAsset)],
    );
  }

  int get ownRecipeCount => recipes.where((r) => r.source == null).length;

  Recipe? byId(String id) => _byId[id];

  RecipeCategory? categoryOf(Recipe recipe) =>
      _categoryByName[recipe.category];

  List<Recipe> byCategory(String category) =>
      recipes.where((r) => r.category == category).toList();

  List<Recipe> search(String query) =>
      query.trim().isEmpty ? const [] : recipes.where((r) => r.matches(query)).toList();

  /// Same pick for everyone all day, changes at midnight. Stepping by a large
  /// prime spreads consecutive days across the whole collection.
  Recipe recipeOfTheDay([DateTime? now]) =>
      recipes[(_dayNumber(now ?? DateTime.now()) * 7919) % recipes.length];

  static int _dayNumber(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2024)).inDays;

  /// Up to [limit] recipes ready in 30 minutes, reshuffled each day.
  List<Recipe> quickPicks({int limit = 12, DateTime? now}) {
    final quick = recipes.where((r) => r.totalMinutes <= 30).toList()
      ..shuffle(Random(_dayNumber(now ?? DateTime.now())));
    return quick.take(limit).toList();
  }

  Recipe random({String? excludeId}) {
    final pool = recipes.where((r) => r.id != excludeId).toList();
    return pool[Random().nextInt(pool.length)];
  }
}
