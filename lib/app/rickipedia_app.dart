import 'package:flutter/material.dart';
import 'package:rickipedia/features/splash/views/splash_page.dart';
import 'package:rickipedia/theme/app_theme.dart';



class RickipediaApp extends StatefulWidget {
  const RickipediaApp({super.key});

  @override
  State<RickipediaApp> createState() => _RickipediaAppState();
}

class _RickipediaAppState extends State<RickipediaApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: AppTheme.lightTheme, home: SplashPage());
  }
}
