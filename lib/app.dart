import 'package:flutter/material.dart';
import 'package:mesh/pages/splash/splash_page.dart';
import 'package:mesh/routes/routes.dart';
import 'package:mesh/ui/colors.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: AppRoutes.routes,
      theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),

      scaffoldBackgroundColor: AppColors.background,
    ),
      home: SplashPage(),
    );
  }
}