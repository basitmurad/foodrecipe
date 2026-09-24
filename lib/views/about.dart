import 'package:flutter/material.dart';

import 'package:foodrecipe/services/favorites_store.dart';
import 'package:foodrecipe/theme/app_theme.dart';

/// App info, recipe credits (required by CC BY-SA 4.0) and open-source licences.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final repo = AppScope.repoOf(context);
    final soft = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      height: 1.5,
    );

    Widget card(List<Widget> children) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/icon/icon.png', width: 88),
                ),
                const SizedBox(height: 12),
                Text(AppTheme.appName, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  '${repo.recipes.length} recipes · works offline · no ads',
                  style: soft,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          card([
            Text('Recipes', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '${repo.ownRecipeCount} recipes were written for '
              '${AppTheme.appName}.',
              style: soft,
            ),
            for (final d in repo.datasets) ...[
              const SizedBox(height: 12),
              Text(
                '${d.count} recipes are adapted from ${d.name} '
                '(${d.homepage}), licensed ${d.license} '
                '(${d.licenseUrl}).',
                style: soft,
              ),
              const SizedBox(height: 8),
              Text('Changes made: ${d.changes}', style: soft),
              const SizedBox(height: 8),
              Text(
                'These adapted recipes are shared under the same licence.',
                style: soft,
              ),
            ],
          ]),
          card([
            Text('Nutrition', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Nutrition values are estimates calculated from the '
              'ingredients. They are a guide for planning, not medical or '
              'dietary advice.',
              style: soft,
            ),
          ]),
          card([
            Text('Privacy', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '${AppTheme.appName} collects no data and never connects to the '
              'internet. Saved recipes stay on this device.',
              style: soft,
            ),
          ]),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: AppTheme.appName,
            ),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Licences'),
          ),
        ],
      ),
    );
  }
}
