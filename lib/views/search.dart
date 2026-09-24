import 'package:flutter/material.dart';

import 'package:foodrecipe/services/favorites_store.dart';
import 'package:foodrecipe/views/widgets/common.dart';

class SearchPage extends StatefulWidget {
  final FocusNode focusNode;

  const SearchPage({super.key, required this.focusNode});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const _suggestions = [
    'Chicken', 'Pasta', 'Vegan', 'Quick', 'Curry', 'Garlic', 'No-bake', 'Soup',
  ];

  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _useSuggestion(String s) {
    _controller.text = s;
    widget.focusNode.unfocus();
    setState(() => _query = s);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text('Search', style: theme.textTheme.displaySmall),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _controller,
              focusNode: widget.focusNode,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Dish, cuisine or ingredient',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _body(theme)),
        ],
      ),
    );
  }

  Widget _body(ThemeData theme) {
    if (_query.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          Text('Try searching for', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final s in _suggestions)
                ActionChip(
                  label: Text(s),
                  avatar: const Icon(Icons.north_east_rounded, size: 16),
                  onPressed: () => _useSuggestion(s),
                  shape: const StadiumBorder(),
                  side: BorderSide.none,
                  backgroundColor: theme.colorScheme.surfaceContainerLowest,
                ),
            ],
          ),
        ],
      );
    }
    final results = AppScope.repoOf(context).search(_query);
    if (results.isEmpty) {
      return MessageView(
        icon: Icons.search_off_rounded,
        title: 'Nothing for "$_query"',
        message: 'Try a single ingredient or dish, like "rice" or "tacos".',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) =>
          RecipeTile(recipe: results[i], heroPrefix: 'search-'),
    );
  }
}
