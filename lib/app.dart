import 'package:flutter/material.dart';

import 'ui/screens/home_screen.dart';
import 'ui/theme/jakki_theme.dart';

class JakkiApp extends StatelessWidget {
  const JakkiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jakki Tunisie',
      debugShowCheckedModeBanner: false,
      theme: JakkiTheme.light(),
      darkTheme: JakkiTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
