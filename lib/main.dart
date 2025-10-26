// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';     // generado por flutterfire configure
import 'src/app.dart';              // tu widget raíz
import 'src/features/ia/debug_gemini.dart'; // util para listar modelos (opcional)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Cargar .env
  await dotenv.load(fileName: '.env');

  // 2) (Solo debug) probar la API de Gemini sin bloquear el arranque si falla
  if (kDebugMode) {
    try {
      await debugListModels();
    } catch (e) {
      debugPrint('debugListModels error: $e');
    }
  }

  // 3) Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 4) Correr la app
  runApp(const FormuLearnApp());
}