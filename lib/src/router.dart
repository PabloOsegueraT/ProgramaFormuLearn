import 'package:flutter/material.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/home/home_screen.dart';
import 'features/formulas/formulas_screen.dart';
import 'features/formulas/formula_detail_screen.dart';
import 'features/formulas/search_screen.dart';
import 'features/ia/ia_screen.dart';
import 'features/reps/reps_screen.dart';
import 'features/portfolio/portfolio_screen.dart';
import 'features/test/test_screen.dart';
import 'features/metrics/metrics_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/formulas/physics_screen.dart';
import 'features/formulas/math_screen.dart';
import 'features/formulas/chemistry_screen.dart';

class AppRouter {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';

  // rutas internas
  static const formulas = '/formulas';
  static const physics = '/formulas/physics';
  static const math = '/formulas/math';
  static const chemistry = '/formulas/chemistry';
  static const formulaDetail = '/formula-detail';
  static const search = '/search';
  static const ia = '/ia';
  static const reps = '/reps';
  static const portfolio = '/portfolio';
  static const test = '/test';
  static const metrics = '/metrics';
  static const profile = '/profile';
  static const settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    home: (_) => const HomeScreen(),

    // Estas se alcanzan por Navigator.pushNamed desde Home o secciones
    formulas: (_) => const FormulasScreen(),
    physics: (_) => const PhysicsScreen(),
    math: (_) => const MathScreen(),
    chemistry: (_) => const ChemistryScreen(),
    formulaDetail: (_) => const FormulaDetailScreen(),
    search: (_) => const SearchScreen(),
    ia: (_) => const IAScreen(),
    reps: (_) => const TestScreen(),
    portfolio: (_) => const PortfolioScreen(),
    test: (_) => const TestScreen(),
    metrics: (_) => const MetricsScreen(),
    profile: (_) => const ProfileScreen(),
    settings: (_) => const SettingsScreen(),
  };
}
