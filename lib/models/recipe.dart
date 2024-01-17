import 'package:flutter/foundation.dart';

class Recipe{
  final String name;
  final String image;
  final double rating;
  final String totalTime;

  Recipe({
    required this.name,
    required this.image,
    required this.rating,
    required this.totalTime,
});
  factory Recipe.fromJson(dynamic json) {
    return Recipe(
      name: json['name'] as String? ?? '',
      image: json['images']?[0]['hostedLargeUrl'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalTime: json['totaltime'] as String? ?? '',
    );
  }

  static List<Recipe> recipesFromSnapshot(List? snapshot) {
    if (snapshot == null) return [];
    return snapshot.map((map) => Recipe.fromJson(map)).toList();
  }


@override
  String toString()
{
  return 'Recipe {name: $name  image: $image , rating: $rating , time $totalTime}';
}


}