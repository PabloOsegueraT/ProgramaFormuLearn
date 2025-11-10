// lib/src/router.dart
import 'package:flutter/material.dart';

// Pantallas base
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/home/home_screen.dart';

// Fórmulas
import 'features/formulas/formulas_screen.dart';
import 'features/formulas/formula_detail_screen.dart';
import 'features/formulas/search_screen.dart';
import 'features/formulas/physics_screen.dart';
import 'features/formulas/math_screen.dart';
import 'features/formulas/chemistry_screen.dart';

// IA
import 'features/ia/ia_screen.dart';
import 'features/ia/formulas_from_photo_screen.dart';
import 'features/ia/graphs_from_photo_screen.dart';

// Otras secciones
import 'features/reps/reps_screen.dart';
import 'features/portfolio/portfolio_screen.dart';
import 'features/test/test_screen.dart';
import 'features/metrics/metrics_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/settings/settings_screen.dart';

// Teacher / Clases existentes
import 'features/teacher/teacher_home_screen.dart';
import 'features/teacher/teacher_analytics_screen.dart';
import 'features/teacher/teacher_student_detail_screen.dart';
import 'features/teacher/teacher_class_detail_screen.dart';

// NUEVAS pantallas de clases
import 'features/classes/student_classes_screen.dart';
import 'features/classes/create_class_screen.dart';
import 'features/classes/join_class_screen.dart';
import 'features/classes/teacher_classes_screen.dart';
import 'features/classes/class_detail_screen.dart';

// Admin (solo debug)
import 'features/admin/import_formulas_debug_screen.dart';

class AppRouter {
  // Core
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';

  // Fórmulas
  static const formulas = '/formulas';
  static const physics = '/formulas/physics';
  static const math = '/formulas/math';
  static const chemistry = '/formulas/chemistry';
  static const formulaDetail = '/formula-detail';
  static const search = '/search';

  // IA
  static const ia = '/ia';
  static const iaFormulasFromPhoto = '/ia/formulas-from-photo';
  static const iaGraphsFromPhoto = '/ia/graphs-from-photo';

  // Otras secciones
  static const reps = '/reps';
  static const portfolio = '/portfolio';
  static const test = '/test';
  static const metrics = '/metrics';
  static const profile = '/profile';
  static const settings = '/settings';

  // Teacher / Clases (existentes)
  static const teacherHome = '/teacher';
  static const teacherAnalytics = '/teacher/analytics';
  static const teacherClassDetail = '/teacher/class-detail';
  static const teacherStudentDetail = '/teacher/student-detail';

  // Clases (nueva organización)
  static const classes = '/classes';            // lista de clases del alumno
  static const joinClass = '/classes/join';     // alumno se une con código
  static const createClass = '/classes/create'; // profe crea clase
  static const classDetail = '/classes/detail'; // detalle con métricas
  static const teacherClasses = '/teacher/classes'; // lista de clases del profe

  // Admin (pantalla oculta de importación)
  static const importDebug = '/admin/import-formulas-debug';

  // Rutas generadas dinámicamente (por ahora solo la de import debug)
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case importDebug:
        return MaterialPageRoute(
          builder: (_) => const ImportFormulasDebugScreen(),
          settings: settings,
        );
    }
    // Si no matchea aquí, Flutter usa 'routes' y luego onUnknownRoute
    return null;
  }

  // Tabla de rutas normales
  static Map<String, WidgetBuilder> get routes => {
    // Core
    splash: (_) => const SplashScreen(),
    login: (_) => LoginScreen(),
    register: (_) => const RegisterScreen(),
    home: (_) => const HomeScreen(),

    // Fórmulas
    formulas: (_) => const FormulasScreen(),
    physics: (_) => const PhysicsScreen(),
    math: (_) => const MathScreen(),
    chemistry: (_) => const ChemistryScreen(),
    formulaDetail: (_) => const FormulaDetailScreen(),
    search: (_) => const SearchScreen(),

    // IA
    ia: (_) => const IAScreen(),
    iaFormulasFromPhoto: (_) => const FormulasFromPhotoScreen(),
    iaGraphsFromPhoto: (_) => const GraphsFromPhotoScreen(),

    // Otras secciones
    reps: (_) => const RepsScreen(),
    portfolio: (_) => const PortfolioScreen(),
    test: (_) => const TestScreen(),
    metrics: (_) => const MetricsScreen(),
    profile: (_) => const ProfileScreen(),
    settings: (_) => const SettingsScreen(),

    // Teacher / Clases (existentes)
    teacherHome: (_) => const TeacherHomeScreen(),
    teacherAnalytics: (_) => const TeacherAnalyticsScreen(),
    teacherStudentDetail: (_) => const TeacherStudentDetailScreen(),
    teacherClassDetail: (_) => const TeacherClassDetailScreen(),

    // NUEVAS vistas de clases
    classes: (_) => const StudentClassesScreen(),      // lista alumno
    joinClass: (_) => const JoinClassScreen(),         // unirse con código
    createClass: (_) => const CreateClassScreen(),     // crear clase
    teacherClasses: (_) => const TeacherClassesScreen(), // lista profe
    classDetail: (_) => const ClassDetailScreen(),     // detalle clase
  };
}
