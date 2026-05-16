import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/game_controller.dart';
import '../../state/locale_controller.dart';
import 'game_screen.dart';

/// Landing screen with title + tagline + Play / Continue buttons +
/// a language picker.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l = AppLocalizations.of(context);
    final Locale locale = ref.watch(localeControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l.appTitle,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  l.tagline,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l.playPassAndPlay),
                  onPressed: () {
                    ref.read(gameControllerProvider.notifier).newGame();
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (BuildContext _) => const GameScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.play_circle_outline),
                  label: Text(l.continueGame),
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (BuildContext _) => const GameScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                _LanguagePicker(
                  current: locale,
                  label: l.language,
                  english: l.languageEnglish,
                  french: l.languageFrench,
                  arabic: l.languageArabic,
                  onChanged: (Locale newLocale) {
                    ref
                        .read(localeControllerProvider.notifier)
                        .setLocale(newLocale);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({
    required this.current,
    required this.label,
    required this.english,
    required this.french,
    required this.arabic,
    required this.onChanged,
  });

  final Locale current;
  final String label;
  final String english;
  final String french;
  final String arabic;
  final ValueChanged<Locale> onChanged;

  @override
  Widget build(BuildContext context) {
    final TextStyle? labelStyle = Theme.of(context).textTheme.labelLarge;
    return Column(
      children: <Widget>[
        Text(label, style: labelStyle),
        const SizedBox(height: 8),
        SegmentedButton<Locale>(
          segments: <ButtonSegment<Locale>>[
            ButtonSegment<Locale>(
              value: const Locale('en'),
              label: Text(english),
            ),
            ButtonSegment<Locale>(
              value: const Locale('fr'),
              label: Text(french),
            ),
            ButtonSegment<Locale>(
              value: const Locale('ar'),
              label: Text(arabic),
            ),
          ],
          selected: <Locale>{current},
          onSelectionChanged: (Set<Locale> sel) => onChanged(sel.first),
        ),
      ],
    );
  }
}
