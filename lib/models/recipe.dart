import 'dart:ui';

class Ingredient {
  final String measure;
  final String name;

  const Ingredient({required this.measure, required this.name});

  /// Stored as a compact `[measure, name]` pair in recipes.json.
  factory Ingredient.fromJson(List<dynamic> pair) =>
      Ingredient(measure: pair[0] as String, name: pair[1] as String);
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

  /// Optional bundled photo (asset path). Falls back to illustrated art.
  final String? image;

  const Recipe({
    required this.id,
    required this.name,
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
    this.image,
  });

  int get totalMinutes => prepMinutes + cookMinutes;

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: json['id'] as String,
        name: json['name'] as String,
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
        image: json['image'] as String?,
      );

  /// True when every word of [query] appears in the name, cuisine,
  /// category, tags or ingredients.
  bool matches(String query) {
    final haystack = [
      name,
      cuisine,
      category,
      ...tags,
      ...ingredients.map((i) => i.name),
    ].join(' ').toLowerCase();
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
