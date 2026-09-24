import 'package:flutter/material.dart';

import 'package:foodrecipe/models/recipe.dart';
import 'package:foodrecipe/services/favorites_store.dart';
import 'package:foodrecipe/views/widgets/common.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onSearchTap;

  const HomePage({super.key, required this.onSearchTap});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _all = 'All';

  Recipe? _shuffled;
  String _selected = _all;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = AppScope.repoOf(context);
    final pick = _shuffled ?? repo.recipeOfTheDay();
    final quick = repo.recipes.where((r) => r.totalMinutes <= 30).toList();
    final grid =
        _selected == _all ? repo.recipes : repo.byCategory(_selected);

    return CustomScrollView(
      slivers: [
        SliverSafeArea(
          bottom: false,
          sliver: SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverList.list(
              children: [
                Text(
                  _greeting.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.6,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'What\'s cooking\ntoday?',
                  style: theme.textTheme.displaySmall?.copyWith(height: 1.05),
                ),
                const SizedBox(height: 20),
                _SearchPill(onTap: widget.onSearchTap),
                const SizedBox(height: 28),
                _SectionHeader(
                  title: _shuffled == null ? 'Today\'s pick' : 'How about…',
                  trailing: IconButton.filledTonal(
                    tooltip: 'Surprise me',
                    onPressed: () => setState(
                      () => _shuffled = repo.random(excludeId: pick.id),
                    ),
                    icon: const Icon(Icons.casino_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 1.05,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _PickCard(key: ValueKey(pick.id), recipe: pick),
                  ),
                ),
                const SizedBox(height: 28),
                const _SectionHeader(title: 'Ready in 30 minutes'),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 210,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: quick.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) => SizedBox(
                width: 140,
                child: RecipeCard(recipe: quick[i], heroPrefix: 'quick-'),
              ),
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(title: 'Browse by craving'),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 100,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: repo.categories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final c = i == 0
                    ? RecipeCategory(
                        name: _all,
                        emoji: '🍽️',
                        color: theme.colorScheme.primary,
                      )
                    : repo.categories[i - 1];
                return _CategoryBubble(
                  category: c,
                  selected: c.name == _selected,
                  onTap: () => setState(() => _selected = c.name),
                );
              },
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Text(
              '${_selected == _all ? 'All recipes' : _selected} · ${grid.length}',
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 20,
              crossAxisSpacing: 14,
              childAspectRatio: 0.68,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => RecipeCard(recipe: grid[i]),
              childCount: grid.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ),
          if (trailing != null) trailing!,
        ],
      );
}

class _SearchPill extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(
                'Search dishes or ingredients…',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickCard extends StatelessWidget {
  final Recipe recipe;

  const _PickCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const onArt = Color(0xFF211C17);
    return GestureDetector(
      onTap: () => openRecipe(context, recipe, heroPrefix: 'pick-'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'pick-${recipe.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: RecipeArt(
                recipe: recipe,
                emojiScale: 0.32,
                emojiAlignment: const Alignment(0, -0.55),
              ),
            ),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: SaveButton(recipe: recipe, size: 42),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(color: onArt),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onArt.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 14,
                    children: [
                      MetaChip(
                        icon: Icons.schedule_rounded,
                        label: formatMinutes(recipe.totalMinutes),
                        color: onArt,
                      ),
                      MetaChip(
                        icon: Icons.public_rounded,
                        label: recipe.cuisine,
                        color: onArt,
                      ),
                      MetaChip(
                        icon: Icons.bar_chart_rounded,
                        label: recipe.difficulty,
                        color: onArt,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBubble extends StatelessWidget {
  final RecipeCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryBubble({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? category.color
                      : category.color.withValues(alpha: 0.16),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: category.color.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Text(category.emoji, style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(height: 6),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
