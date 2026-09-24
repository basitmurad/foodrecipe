import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:foodrecipe/models/recipe.dart';

/// Distraction-free, one-step-at-a-time view with large type for the kitchen.
class CookModePage extends StatefulWidget {
  final Recipe recipe;

  const CookModePage({super.key, required this.recipe});

  @override
  State<CookModePage> createState() => _CookModePageState();
}

class _CookModePageState extends State<CookModePage> {
  final _controller = PageController();
  late final List<String> _steps = widget.recipe.steps;
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0) return;
    if (next >= _steps.length) {
      Navigator.pop(context);
      return;
    }
    HapticFeedback.selectionClick();
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLast = _index == _steps.length - 1;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(
          widget.recipe.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _index
                              ? scheme.primary
                              : scheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STEP ${i + 1} OF ${_steps.length}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                          letterSpacing: 1.6,
                        ),
                      ),
                      if ((widget.recipe.minutesForStep(i) ?? 0) > 0) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 20, color: scheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'About ${formatMinutes(widget.recipe.minutesForStep(i)!)}',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(color: scheme.primary),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        _steps[i],
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Previous step',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(56, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _index == 0 ? null : () => _go(-1),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 56),
                        backgroundColor: isLast ? scheme.secondary : null,
                      ),
                      onPressed: () => _go(1),
                      child: Text(isLast ? 'Done — enjoy!' : 'Next step'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
