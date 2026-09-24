import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'package:foodrecipe/models/recipe.dart';

/// All recipes ship inside the app (assets/data/recipes.json), so the app
/// works fully offline and needs no API key.
class RecipeRepository {
  final List<RecipeCategory> categories;
  final List<Recipe> recipes;
  final Map<String, Recipe> _byId;
  final Map<String, RecipeCategory> _categoryByName;

  RecipeRepository({required this.categories, required this.recipes})
      : _byId = {for (final r in recipes) r.id: r},
        _categoryByName = {for (final c in categories) c.name: c};

  factory RecipeRepository.fromJson(Map<String, dynamic> json) =>
      RecipeRepository(
        categories: (json['categories'] as List)
            .map((c) => RecipeCategory.fromJson(c as Map<String, dynamic>))
            .toList(),
        recipes: (json['recipes'] as List)
            .map((r) => Recipe.fromJson(r as Map<String, dynamic>))
            .toList(),
      );

  static Future<RecipeRepository> load() async {
    final raw = await rootBundle.loadString('assets/data/recipes.json');
    return RecipeRepository.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Recipe? byId(String id) => _byId[id];

  RecipeCategory? categoryOf(Recipe recipe) =>
      _categoryByName[recipe.category];

  List<Recipe> byCategory(String category) =>
      recipes.where((r) => r.category == category).toList();

  List<Recipe> search(String query) =>
      query.trim().isEmpty ? const [] : recipes.where((r) => r.matches(query)).toList();

  /// Same pick for everyone all day, changes at midnight.
  Recipe recipeOfTheDay([DateTime? now]) {
    final d = now ?? DateTime.now();
    final day = DateTime.utc(d.year, d.month, d.day)
        .difference(DateTime.utc(2024))
        .inDays;
    return recipes[day % recipes.length];
  }

  Recipe random({String? excludeId}) {
    final pool = recipes.where((r) => r.id != excludeId).toList();
    return pool[Random().nextInt(pool.length)];
  }
}
