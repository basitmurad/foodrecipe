import 'package:flutter/material.dart';

import 'package:foodrecipe/models/recipe.dart';
import 'package:foodrecipe/views/cook_mode.dart';
import 'package:foodrecipe/views/widgets/common.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;
  final String heroTag;

  const RecipeDetailPage({
    super.key,
    required this.recipe,
    required this.heroTag,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final _checked = <int>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final recipe = widget.recipe;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.sizeOf(context).width * 0.85,
            pinned: true,
            stretch: true,
            backgroundColor: scheme.surface,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton.filledTonal(
                tooltip: 'Back',
                style: IconButton.styleFrom(
                  backgroundColor:
                      scheme.surfaceContainerLowest.withValues(alpha: 0.92),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SaveButton(recipe: recipe, size: 40),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Hero(
                tag: widget.heroTag,
                child: RecipeArt(recipe: recipe, emojiScale: 0.34),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -28, 0),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.name,
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(height: 1.1)),
                  if (recipe.nativeName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      recipe.nativeName!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    recipe.description,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in [recipe.cuisine, ...recipe.tags]) _Tag(t),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _StatsRow(recipe: recipe),
                  if (recipe.nutrition != null) ...[
                    const SizedBox(height: 12),
                    _NutritionCard(nutrition: recipe.nutrition!),
                  ],
                ],
              ),
            ),
          ),
          _heading(
            context,
            'Ingredients',
            _checked.isEmpty
                ? 'Tap to tick off'
                : '${_checked.length}/${recipe.ingredients.length} ready',
          ),
          SliverList.builder(
            itemCount: recipe.ingredients.length,
            itemBuilder: (_, i) => _IngredientRow(
              ingredient: recipe.ingredients[i],
              checked: _checked.contains(i),
              onTap: () => setState(() {
                if (!_checked.remove(i)) _checked.add(i);
              }),
            ),
          ),
          _heading(context, 'Method', '${recipe.steps.length} steps'),
          SliverList.builder(
            itemCount: recipe.steps.length,
            itemBuilder: (_, i) => _StepRow(
              index: i,
              text: recipe.steps[i],
              minutes: recipe.minutesForStep(i),
              isLast: i == recipe.steps.length - 1,
            ),
          ),
          if (recipe.source != null)
            SliverToBoxAdapter(child: _SourceCredit(source: recipe.source!)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => CookModePage(recipe: recipe),
            ),
          ),
          icon: const Icon(Icons.local_fire_department_rounded),
          label: const Text('Start cooking'),
        ),
      ),
    );
  }

  Widget _heading(BuildContext context, String title, String hint) {
    final theme = Theme.of(context);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
      sliver: SliverToBoxAdapter(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(title, style: theme.textTheme.headlineSmall),
            const Spacer(),
            Text(
              hint,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.secondary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Recipe recipe;

  const _StatsRow({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget stat(IconData icon, String value, String label) => Expanded(
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 6),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          stat(Icons.schedule_rounded, formatMinutes(recipe.totalMinutes),
              'Total time'),
          stat(Icons.people_outline_rounded, '${recipe.servings}', 'Serves'),
          stat(Icons.bar_chart_rounded, recipe.difficulty, 'Difficulty'),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final Ingredient ingredient;
  final bool checked;
  final VoidCallback onTap;

  const _IngredientRow({
    required this.ingredient,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: checked ? 0.45 : 1,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: checked ? scheme.secondary : Colors.transparent,
                  border: Border.all(
                    color: checked ? scheme.secondary : scheme.outlineVariant,
                    width: 2,
                  ),
                ),
                child: checked
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingredient.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: checked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (ingredient.note != null)
                      Text(
                        ingredient.note!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                ingredient.measure,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int index;
  final String text;
  final int? minutes;
  final bool isLast;

  const _StepRow({
    required this.index,
    required this.text,
    required this.minutes,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: scheme.onPrimary),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: scheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
                    ),
                    if (minutes != null && minutes! > 0) ...[
                      const SizedBox(height: 6),
                      MetaChip(
                        icon: Icons.timer_outlined,
                        label: formatMinutes(minutes!),
                        color: scheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final Nutrition nutrition;

  const _NutritionCard({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget value(String amount, String label) => Expanded(
          child: Column(
            children: [
              Text(amount, style: theme.textTheme.titleMedium),
              Text(
                label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              value('${nutrition.calories}', 'kcal'),
              value('${nutrition.protein} g', 'Protein'),
              value('${nutrition.carbs} g', 'Carbs'),
              value('${nutrition.fat} g', 'Fat'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Per serving · estimated from ingredients',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Attribution required by the recipe's licence (CC BY-SA 4.0 for UniTools).
class _SourceCredit extends StatelessWidget {
  final RecipeSource source;

  const _SourceCredit({required this.source});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final soft = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.menu_book_outlined, size: 18, color: soft),
            const SizedBox(width: 10),
            Expanded(
              child: SelectableText.rich(
                TextSpan(
                  style: theme.textTheme.bodySmall?.copyWith(color: soft),
                  children: [
                    TextSpan(text: 'Recipe adapted from ${source.name}, '
                        'licensed CC BY-SA 4.0.\n'),
                    TextSpan(
                      text: source.url,
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
