import 'dart:ui';

class Ingredient {
  final String measure;
  final String name;
  final String? note;

  const Ingredient({required this.measure, required this.name, this.note});

  /// Stored compactly as `[measure, name]` or `[measure, name, note]`.
  factory Ingredient.fromJson(List<dynamic> entry) => Ingredient(
        measure: entry[0] as String,
        name: entry[1] as String,
        note: entry.length > 2 ? entry[2] as String? : null,
      );
}

/// Approximate values per serving, computed from ingredients.
class Nutrition {
  final int calories;
  final int protein;
  final int fat;
  final int carbs;

  const Nutrition({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  factory Nutrition.fromJson(Map<String, dynamic> json) => Nutrition(
        calories: (json['calories'] as num).round(),
        protein: (json['protein'] as num).round(),
        fat: (json['fat'] as num).round(),
        carbs: (json['carbs'] as num).round(),
      );
}

/// Where a recipe came from, for attribution. Null for the app's own recipes.
class RecipeSource {
  final String name;
  final String url;

  const RecipeSource({required this.name, required this.url});

  factory RecipeSource.fromJson(Map<String, dynamic> json) =>
      RecipeSource(name: json['name'] as String, url: json['url'] as String);
}

class RecipeCategory {
  final String name;
  final String emoji;
  final Color color;

  const RecipeCategory({
    required this.name,
    required this.emoji,
    required this.color,
  });

  factory RecipeCategory.fromJson(Map<String, dynamic> json) => RecipeCategory(
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        color: parseHexColor(json['color'] as String),
      );
}

class Recipe {
  final String id;
  final String name;
  final String? nativeName;
  final String category;
  final String cuisine;
  final String emoji;
  final String description;
  final int prepMinutes;
  final int cookMinutes;
  final int servings;
  final String difficulty;
  final List<String> tags;
  final List<Ingredient> ingredients;
  final List<String> steps;

  /// Minutes for each step, aligned with [steps]; entries may be null.
  final List<int?> stepMinutes;
  final Nutrition? nutrition;
  final RecipeSource? source;

  /// Optional bundled photo (asset path). Falls back to illustrated art.
  final String? image;

  Recipe({
    required this.id,
    required this.name,
    this.nativeName,
    required this.category,
    required this.cuisine,
    required this.emoji,
    required this.description,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.servings,
    required this.difficulty,
    required this.tags,
    required this.ingredients,
    required this.steps,
    this.stepMinutes = const [],
    this.nutrition,
    this.source,
    this.image,
  });

  int get totalMinutes => prepMinutes + cookMinutes;

  int? minutesForStep(int index) =>
      index < stepMinutes.length ? stepMinutes[index] : null;

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String,
        name: json['name'] as String,
        nativeName: json['nativeName'] as String?,
        category: json['category'] as String,
        cuisine: json['cuisine'] as String,
        emoji: json['emoji'] as String,
        description: json['description'] as String? ?? '',
        prepMinutes: json['prepMinutes'] as int? ?? 0,
        cookMinutes: json['cookMinutes'] as int? ?? 0,
        servings: json['servings'] as int? ?? 1,
        difficulty: json['difficulty'] as String? ?? 'Easy',
        tags: List<String>.from(json['tags'] as List? ?? const []),
        ingredients: (json['ingredients'] as List)
            .map((i) => Ingredient.fromJson(i as List))
            .toList(),
        steps: List<String>.from(json['steps'] as List),
        stepMinutes: List<int?>.from(json['stepMinutes'] as List? ?? const []),
        nutrition: json['nutrition'] == null
            ? null
            : Nutrition.fromJson(json['nutrition'] as Map<String, dynamic>),
        source: json['source'] == null
            ? null
            : RecipeSource.fromJson(json['source'] as Map<String, dynamic>),
        image: json['image'] as String?,
      );

  late final String _haystack = [
    name,
    if (nativeName != null) nativeName!,
    cuisine,
    category,
    ...tags,
    ...ingredients.map((i) => i.name),
  ].join(' ').toLowerCase();

  /// True when every word of [query] appears in the name, native name,
  /// cuisine, category, tags or ingredients.
  bool matches(String query) {
    final haystack = _haystack;
    return query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .every(haystack.contains);
  }
}

Color parseHexColor(String hex) =>
    Color(int.parse(hex.replaceFirst('#', ''), radix: 16) | 0xFF000000);

/// "1 h 20 min" style label.
String formatMinutes(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60, m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}
