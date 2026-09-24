import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:foodrecipe/services/favorites_store.dart';
import 'package:foodrecipe/services/recipe_repository.dart';
import 'package:foodrecipe/theme/app_theme.dart';
import 'package:foodrecipe/views/home.dart';
import 'package:foodrecipe/views/saved.dart';
import 'package:foodrecipe/views/search.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  _registerFontLicenses();
  final repo = await RecipeRepository.load();
  final favorites = await FavoritesStore.load(repo);
  runApp(MyApp(repo: repo, favorites: favorites));
}

/// Bundled fonts are OFL-licensed; list them on Flutter's licence page.
void _registerFontLicenses() {
  const fonts = {'Fraunces': 'OFL-Fraunces', 'Plus Jakarta Sans': 'OFL-PlusJakartaSans'};
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: name, value: file) in fonts.entries) {
      final text = await rootBundle.loadString('assets/fonts/$file.txt');
      yield LicenseEntryWithLineBreaks([name], text);
    }
  });
}

class MyApp extends StatelessWidget {
  final RecipeRepository repo;
  final FavoritesStore favorites;

  const MyApp({super.key, required this.repo, required this.favorites});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repo: repo,
      favorites: favorites,
      child: MaterialApp(
        title: AppTheme.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const AppShell(),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  void _select(int tab) {
    setState(() => _tab = tab);
    if (tab == 1) {
      _searchFocus.requestFocus();
    } else {
      _searchFocus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = AppScope.favoritesOf(context).items.length;
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          HomePage(onSearchTap: () => _select(1)),
          SearchPage(focusNode: _searchFocus),
          SavedPage(onBrowse: () => _select(0)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _select,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Discover',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: saved > 0,
              label: Text('$saved'),
              child: const Icon(Icons.favorite_border_rounded),
            ),
            selectedIcon: const Icon(Icons.favorite_rounded),
            label: 'Saved',
          ),
        ],
      ),
    );
  }
}
