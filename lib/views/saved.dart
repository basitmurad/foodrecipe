import 'package:flutter/material.dart';

import 'package:foodrecipe/services/favorites_store.dart';
import 'package:foodrecipe/views/widgets/common.dart';

class SavedPage extends StatelessWidget {
  final VoidCallback onBrowse;

  const SavedPage({super.key, required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = AppScope.favoritesOf(context).items;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text('Saved', style: theme.textTheme.displaySmall),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              items.isEmpty
                  ? 'Your personal cookbook'
                  : '${items.length} recipe${items.length == 1 ? '' : 's'} in your cookbook',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? MessageView(
                    icon: Icons.favorite_border_rounded,
                    title: 'No saved recipes yet',
                    message:
                        'Tap the heart on any dish to keep it here — it stays on your device.',
                    actionLabel: 'Discover recipes',
                    onAction: onBrowse,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) =>
                        RecipeTile(recipe: items[i], heroPrefix: 'saved-'),
                  ),
          ),
        ],
      ),
    );
  }
}
