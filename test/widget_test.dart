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
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });
}
