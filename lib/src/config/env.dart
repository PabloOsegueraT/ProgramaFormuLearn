// lib/src/config/env.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get qdrantUrl => dotenv.env['QDRANT_URL'] ?? '';
  static String get qdrantApiKey => dotenv.env['QDRANT_API_KEY'] ?? '';
  static String get qdrantCollection =>
      dotenv.env['QDRANT_COLLECTION'] ?? 'formulas';

  /// Lanza un error si faltan claves críticas en producción.
  static void validate() {
    final missing = <String>[];
    if ((dotenv.env['GEMINI_API_KEY'] ?? '').isEmpty) missing.add('GEMINI_API_KEY');
    // Agrega otras si son obligatorias para tu flujo:
    // if ((dotenv.env['QDRANT_URL'] ?? '').isEmpty) missing.add('QDRANT_URL');
    if (missing.isNotEmpty) {
      throw StateError('Faltan variables en .env: $missing');
    }
  }
}