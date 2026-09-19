import 'package:flutter/material.dart';
import 'package:rickipedia/features/character/views/characters_page.dart';

import '../theme/app_theme.dart';

class RickipediaApp extends StatefulWidget {
  const RickipediaApp({super.key});

  @override
  State<RickipediaApp> createState() => _RickipediaAppState();
}

class _RickipediaAppState extends State<RickipediaApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: AppTheme.lightTheme, home: CharactersPage());
  }
}
