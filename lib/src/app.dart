// lib/src/app.dart
import 'package:flutter/material.dart';
import 'theme.dart';
import 'router.dart';

class FormuLearnApp extends StatelessWidget {
  const FormuLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FormuLearn (Visual)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRouter.splash,
      routes: AppRouter.routes,
    );
  }
}
