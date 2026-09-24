import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:foodrecipe/models/recipe.dart';
import 'package:foodrecipe/services/recipe_repository.dart';

/// Saved recipe ids, persisted on device. Newest first.
class FavoritesStore extends ChangeNotifier {
  static const _prefsKey = 'favorite_ids_v2';

  final SharedPreferences _prefs;
  final RecipeRepository _repo;
  final List<String> _ids;

  FavoritesStore(this._prefs, this._repo)
      : _ids = (_prefs.getStringList(_prefsKey) ?? <String>[])
            .where((id) => _repo.byId(id) != null)
            .toList();

  static Future<FavoritesStore> load(RecipeRepository repo) async =>
      FavoritesStore(await SharedPreferences.getInstance(), repo);

  List<Recipe> get items => _ids.map((id) => _repo.byId(id)!).toList();

  bool contains(String id) => _ids.contains(id);

  Future<void> toggle(Recipe recipe) async {
    if (!_ids.remove(recipe.id)) _ids.insert(0, recipe.id);
    notifyListeners();
    await _prefs.setStringList(_prefsKey, _ids);
  }
}

/// Makes the app's data available to the widget tree.
class AppScope extends InheritedNotifier<FavoritesStore> {
  final RecipeRepository repo;

  const AppScope({
    super.key,
    required this.repo,
    required FavoritesStore favorites,
    required super.child,
  }) : super(notifier: favorites);

  static AppScope _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  static FavoritesStore favoritesOf(BuildContext context) =>
      _of(context).notifier!;

  static RecipeRepository repoOf(BuildContext context) => _of(context).repo;
}
