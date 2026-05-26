import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakki/app.dart';

void main() {
  testWidgets('Home screen renders title and tagline', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: JakkiApp()));
    await tester.pumpAndSettle();

    expect(find.text('Jakki Tunisie'), findsOneWidget);
    expect(find.text('Mahbousseh — chiche-biche'), findsOneWidget);
    // Pass-and-play + vs-computer Play buttons.
    expect(find.byType(FilledButton), findsNWidgets(2));
    // Continue (saved game) button.
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.text('Play (pass-and-play)'), findsOneWidget);
    expect(find.text('Play vs computer'), findsOneWidget);
  });
}
