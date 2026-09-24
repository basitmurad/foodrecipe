import 'package:flutter/material.dart';

import 'package:foodrecipe/models/recipe.dart';
import 'package:foodrecipe/services/favorites_store.dart';
import 'package:foodrecipe/views/detail.dart';

/// Recipe artwork: a bundled photo when the recipe has one, otherwise an
/// illustrated card — a gradient in the category colour with the dish emoji.
class RecipeArt extends StatelessWidget {
  final Recipe recipe;
  final double emojiScale;
  final Alignment emojiAlignment;

  const RecipeArt({
    super.key,
    required this.recipe,
    this.emojiScale = 0.42,
    this.emojiAlignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    if (recipe.image != null) {
      return Image.asset(recipe.image!, fit: BoxFit.cover);
    }
    final base = AppScope.repoOf(context).categoryOf(recipe)?.color ??
        Theme.of(context).colorScheme.primary;
    final light = Color.lerp(base, Colors.white, 0.55)!;
    final mid = Color.lerp(base, Colors.white, 0.2)!;
    return LayoutBuilder(
      builder: (context, c) {
        final side = c.biggest.shortestSide;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [light, mid],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: -side * 0.18,
                top: -side * 0.18,
                child: _Blob(size: side * 0.7, color: Colors.white),
              ),
              Positioned(
                left: -side * 0.12,
                bottom: -side * 0.22,
                child: _Blob(size: side * 0.55, color: base),
              ),
              Align(
                alignment: emojiAlignment,
                child: Text(
                  recipe.emoji,
                  style: TextStyle(
                    fontSize: side * emojiScale,
                    height: 1,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: side * 0.06,
                        offset: Offset(0, side * 0.03),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.22),
        ),
      );
}

void openRecipe(BuildContext context, Recipe recipe, {String heroPrefix = ''}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          RecipeDetailPage(recipe: recipe, heroTag: '$heroPrefix${recipe.id}'),
    ),
  );
}

/// Small pill with an icon and a label, e.g. "25 min".
class MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const MetaChip({super.key, required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: c)),
      ],
    );
  }
}

/// Round heart button that toggles a saved recipe.
class SaveButton extends StatelessWidget {
  final Recipe recipe;
  final double size;

  const SaveButton({super.key, required this.recipe, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.favoritesOf(context);
    final saved = store.contains(recipe.id);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: saved ? 'Remove from saved' : 'Save recipe',
      child: Material(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => store.toggle(recipe),
          child: SizedBox.square(
            dimension: size,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(
                saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(saved),
                size: size * 0.52,
                color: saved ? scheme.primary : scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Portrait card used in grids.
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final String heroPrefix;

  const RecipeCard({super.key, required this.recipe, this.heroPrefix = 'grid-'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.25,
    );
    return GestureDetector(
      onTap: () => openRecipe(context, recipe, heroPrefix: heroPrefix),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: '$heroPrefix${recipe.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: RecipeArt(recipe: recipe),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: SaveButton(recipe: recipe, size: 34),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Always reserve two lines so cards in a row keep equal image heights.
          Stack(
            children: [
              Text(' \n ', style: titleStyle),
              Text(
                recipe.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ],
          ),
          const SizedBox(height: 4),
          MetaChip(
            icon: Icons.schedule_rounded,
            label: formatMinutes(recipe.totalMinutes),
          ),
        ],
      ),
    );
  }
}

/// Horizontal row used in lists (search results, saved).
class RecipeTile extends StatelessWidget {
  final Recipe recipe;
  final String heroPrefix;

  const RecipeTile({super.key, required this.recipe, this.heroPrefix = 'tile-'});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openRecipe(context, recipe, heroPrefix: heroPrefix),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Hero(
                tag: '$heroPrefix${recipe.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox.square(
                    dimension: 84,
                    child: RecipeArt(recipe: recipe, emojiScale: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        MetaChip(
                          icon: Icons.schedule_rounded,
                          label: formatMinutes(recipe.totalMinutes),
                        ),
                        MetaChip(
                          icon: Icons.public_rounded,
                          label: recipe.cuisine,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SaveButton(recipe: recipe),
            ],
          ),
        ),
      ),
    );
  }
}

/// Friendly empty state with an optional action.
class MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
