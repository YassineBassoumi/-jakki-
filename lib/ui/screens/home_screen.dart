import 'package:flutter/material.dart';

/// Placeholder home screen. Replaced in Milestone 2 by a real menu
/// (`New game`, `Continue`, `Settings`, `Tutorial`, `Stats`).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Jakki Tunisie',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Mahbousseh — chiche-biche',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const FilledButton(
                  onPressed: null,
                  child: Text('New game (coming soon)'),
                ),
                const SizedBox(height: 12),
                const OutlinedButton(
                  onPressed: null,
                  child: Text('Settings (coming soon)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
