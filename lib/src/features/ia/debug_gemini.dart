// lib/src/features/ia/debug_gemini.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/env.dart';

Future<void> debugListModels() async {
  final uri = Uri.parse(
    'https://generativelanguage.googleapis.com/v1/models?key=${Env.geminiApiKey}',
  );
  final res = await http.get(uri);
  debugPrint('LIST MODELS -> ${res.statusCode}');
  debugPrint(res.body); // aquí verás los IDs disponibles
}