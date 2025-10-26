// lib/src/features/ia/formulas_from_photo_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../router.dart';
import '../../config/env.dart';

class FormulasFromPhotoScreen extends StatefulWidget {
  const FormulasFromPhotoScreen({super.key});

  @override
  State<FormulasFromPhotoScreen> createState() =>
      _FormulasFromPhotoScreenState();
}

class _FormulasFromPhotoScreenState extends State<FormulasFromPhotoScreen> {
  final _picker = ImagePicker();
  XFile? _image;
  bool _ocrRunning = false;
  bool _aiLoading = false;

  final _problemCtrl = TextEditingController(); // texto del OCR editable

  // Estado UI IA
  List<_AiSuggestion> _aiSuggestions = [];
  String? _aiExplanation; // explicación global del modelo
  String? _subject;       // matematicas | fisica | quimica | desconocido
  String? _intent;        // problema | formula

  // Catálogo de fórmulas
  bool _loadingFormulas = true;
  final List<_Formula> _catalog = [];

  @override
  void initState() {
    super.initState();
    _loadFormulas();
  }

  @override
  void dispose() {
    _problemCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource src) async {
    final img = await _picker.pickImage(source: src, imageQuality: 85);
    if (img == null) return;
    setState(() {
      _image = img;
      _aiSuggestions = [];
      _aiExplanation = null;
      _subject = null;
      _intent = null;
    });
    await _runOCR();
  }

  Future<void> _runOCR() async {
    if (_image == null) return;
    setState(() => _ocrRunning = true);

    final recognizer = TextRecognizer();
    try {
      final file = File(_image!.path);
      final input = InputImage.fromFile(file);
      final result = await recognizer.processImage(input);
      final text = result.text.trim();
      setState(() {
        _problemCtrl.text = text;
      });
    } catch (e) {
      _snack('OCR falló: $e');
    } finally {
      await recognizer.close();
      if (!mounted) return;
      setState(() => _ocrRunning = false);
    }
  }

  Future<void> _loadFormulas() async {
    setState(() => _loadingFormulas = true);
    try {
      final qs = await FirebaseFirestore.instance
          .collection('formulas')
          .limit(200)
          .get();

      if (qs.docs.isNotEmpty) {
        _catalog.clear();
        for (final d in qs.docs) {
          final data = d.data();
          _catalog.add(
            _Formula(
              id: d.id,
              title: (data['titulo'] ?? data['title'] ?? '') as String,
              latex:
              (data['latex_expresion'] ?? data['expression'] ?? '') as String,
              summary: (data['explicacion'] ?? data['summary'] ?? '') as String,
              topic: (data['tema'] ?? data['topic'] ?? '') as String,
              conditions: (data['condiciones_uso'] ?? '') as String,
            ),
          );
        }
      } else {
        _useLocalFallback();
      }
    } catch (_) {
      _useLocalFallback();
    } finally {
      if (!mounted) return;
      setState(() => _loadingFormulas = false);
    }
  }

  void _useLocalFallback() {
    _catalog
      ..clear()
      ..addAll([
        _Formula(
          id: 'mru',
          title: 'MRU (Movimiento rectilíneo uniforme)',
          latex: r'v = \frac{d}{t}',
          summary: 'Velocidad constante; distancia proporcional al tiempo.',
          topic: 'Física',
          conditions: 'Sin aceleración; trayectoria recta.',
        ),
        _Formula(
          id: 'newton2',
          title: 'Segunda ley de Newton',
          latex: r'\sum F = m \cdot a',
          summary:
          'La aceleración es proporcional a la fuerza neta e inversa a la masa.',
          topic: 'Física',
          conditions: 'Sistema de referencia inercial.',
        ),
        _Formula(
          id: 'cuadratica',
          title: 'Ecuación cuadrática',
          latex: r'x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}',
          summary: 'Solución general para ax² + bx + c = 0.',
          topic: 'Matemáticas',
          conditions: 'a ≠ 0; dominio real si Δ≥0.',
        ),
        _Formula(
          id: 'pH',
          title: 'pH',
          latex: r'pH = -\log_{10}[H^+]',
          summary: 'Medida de acidez según [H⁺].',
          topic: 'Química',
          conditions: 'Soluciones acuosas diluidas.',
        ),
      ]);
  }

  // ---------- IA ----------
  Future<void> _analyzeWithAI() async {
    final text = _problemCtrl.text.trim();
    if (text.isEmpty) {
      _snack('Primero captura o escribe el enunciado.');
      return;
    }
    if (Env.geminiApiKey.isEmpty) {
      _snack('Falta GEMINI_API_KEY en .env');
      return;
    }

    setState(() {
      _aiLoading = true;
      _aiSuggestions = [];
      _aiExplanation = null;
      _subject = null;
      _intent = null;
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: Env.geminiApiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

      final catalogJson = _catalog
          .map((f) => {
        'id': f.id,
        'title': f.title,
        'latex': f.latex,
        'summary': f.summary,
        'topic': f.topic,
        'conditions': f.conditions,
      })
          .toList();

      final prompt = '''
Eres un asistente de matemáticas, física y química.

Tareas:
1) Detecta "subject" ∈ {"matematicas","fisica","quimica","desconocido"}.
2) Detecta "intent" ∈ {"problema","formula"} según si el usuario pegó un enunciado o solo fórmulas.
3) Elige hasta 3 fórmulas candidatas del catálogo (ID y título) que ayuden a resolver el caso.
4) Para cada candidata explica brevemente por qué aplica y mapea variables desde el texto.
5) Da una "explanation" clara y concisa (máx. 150–250 palabras) que ayude a empezar a resolver.

Si el usuario solo pegó fórmulas (LaTeX o texto), clasifícalas por materia y explícalas (igual formato).

Devuelve EXCLUSIVAMENTE JSON con este esquema:
{
  "subject": "matematicas|fisica|quimica|desconocido",
  "intent": "problema|formula",
  "matches": [
    {
      "id": "<id en catálogo o '' si no está>",
      "title": "<título de la fórmula>",
      "why": "<justificación corta>",
      "variables": [{"symbol":"x","fromText":"..."}],
      "confidence": 0.0
    }
  ],
  "explanation": "<texto breve y claro>"
}
''';

      final resp = await model.generateContent([
        Content.text(prompt),
        Content.text('ENUNCIADO_O_FORMULAS:\n$text'),
        Content.text('CATALOGO_JSON:\n${jsonEncode(catalogJson)}'),
      ]);

      final raw = (resp.text ?? '').trim();
      final jsonStr = _extractJson(raw);

      // Parseo robusto
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final subject = (map['subject'] as String?)?.toLowerCase();
      final intent = (map['intent'] as String?)?.toLowerCase();
      final explanation = (map['explanation'] as String?)?.trim();

      final matches = (map['matches'] as List<dynamic>? ?? []);
      final parsed = <_AiSuggestion>[];
      for (final m in matches) {
        parsed.add(
          _AiSuggestion(
            id: (m['id'] ?? '') as String,
            title: (m['title'] ?? '') as String,
            why: (m['why'] ?? '') as String,
            confidence: (m['confidence'] is num)
                ? (m['confidence'] as num).toDouble()
                : null,
            variables: ((m['variables'] as List?) ?? [])
                .map<_VarMap>((v) => _VarMap(
              symbol: (v['symbol'] ?? '') as String,
              fromText: (v['fromText'] ?? '') as String,
            ))
                .toList(),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _aiSuggestions = parsed;
        _aiExplanation =
        (explanation != null && explanation.isNotEmpty) ? explanation : null;
        _subject = subject;
        _intent = intent;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiExplanation = 'Error IA: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() => _aiLoading = false);
    }
  }

  /// Si la respuesta viene como ```json ... ```, recorta y extrae el primer objeto JSON.
  String _extractJson(String text) {
    // quita fences comunes
    var t = text.trim();
    if (t.startsWith('```')) {
      final firstBrace = t.indexOf('{');
      final lastBrace = t.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        t = t.substring(firstBrace, lastBrace + 1);
      }
    }
    // fallback: intenta encontrar el primer {...}
    final s = t.indexOf('{');
    final e = t.lastIndexOf('}');
    if (s != -1 && e != -1 && e > s) return t.substring(s, e + 1);
    return t; // dejar tal cual (para que lance en decode y veamos el error)
  }

  // ---------- UI helpers ----------
  void _openFormulaDetail(_Formula f) {
    Navigator.pushNamed(
      context,
      AppRouter.formulaDetail,
      arguments: {
        'title': f.title,
        'expression': f.latex,
        'summary': f.summary,
        'topic': f.topic,
        'conditions': f.conditions,
      },
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Color _subjectColor(String s, ColorScheme cs) {
    switch (s) {
      case 'matematicas':
        return cs.primaryContainer;
      case 'fisica':
        return cs.tertiaryContainer;
      case 'quimica':
        return cs.secondaryContainer;
      default:
        return cs.surfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Resolver por foto (Fórmulas)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Selector de imagen
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_camera),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Cámara'),
                  ),
                  onPressed: () => _pick(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Galería'),
                  ),
                  onPressed: () => _pick(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Preview
          if (_image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(_image!.path), height: 200, fit: BoxFit.cover),
            ),
          if (_image != null) const SizedBox(height: 12),

          // OCR state
          if (_ocrRunning)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(height: 8),
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Leyendo texto (OCR)…'),
                ],
              ),
            ),

          // Texto del problema (editable)
          Text('Enunciado o fórmulas',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: _problemCtrl,
            minLines: 4,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText:
              'Pega o edita aquí el enunciado o las fórmulas detectadas…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Catálogo cargando/ok
          if (_loadingFormulas)
            Row(
              children: const [
                SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Cargando catálogo de fórmulas…'),
              ],
            )
          else
            Text('Fórmulas cargadas: ${_catalog.length}',
                style: TextStyle(color: cs.onSurfaceVariant)),

          const SizedBox(height: 12),

          // Botón IA o loader
          _aiLoading
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(height: 8),
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Analizando con IA…'),
              ],
            ),
          )
              : FilledButton.icon(
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Analizar con IA'),
            onPressed: _analyzeWithAI,
          ),

          const SizedBox(height: 16),

          // Chips de materia/intent
          if (_subject != null || _intent != null) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (_subject != null)
                  Chip(
                    label: Text('Materia: ${_subject!}'),
                    backgroundColor: _subjectColor(_subject!, cs),
                  ),
                if (_intent != null)
                  Chip(
                    label: Text('Tipo: ${_intent!}'),
                    backgroundColor: cs.surfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Sugerencias IA
          if (_aiSuggestions.isNotEmpty) ...[
            Text('Sugerencias',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ..._aiSuggestions.map(_buildSuggestionCard),
          ],

          // Explicación global (en lugar de JSON crudo)
          if (_aiExplanation != null) ...[
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(_aiExplanation!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(_AiSuggestion s) {
    final f = _catalog.firstWhere(
          (e) => e.id == s.id || e.title.toLowerCase() == s.title.toLowerCase(),
      orElse: () => _Formula(
        id: s.id,
        title: s.title,
        latex: '',
        summary: '',
        topic: '',
        conditions: '',
      ),
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // título y score
            Row(
              children: [
                const Icon(Icons.functions, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    f.title.isEmpty ? s.title : f.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (s.confidence != null)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child:
                    Text('conf ${(s.confidence! * 100).toStringAsFixed(0)}%'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (f.latex.isNotEmpty)
              Text('Expresión: ${f.latex}',
                  style: const TextStyle(fontFamily: 'monospace')),
            if (f.latex.isNotEmpty) const SizedBox(height: 6),

            if (s.why.isNotEmpty) Text('¿Por qué? ${s.why}'),
            if (s.variables.isNotEmpty) const SizedBox(height: 6),
            if (s.variables.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: s.variables
                    .map((v) => Chip(
                  label: Text('${v.symbol} ← "${v.fromText}"'),
                  visualDensity: VisualDensity.compact,
                ))
                    .toList(),
              ),

            const SizedBox(height: 10),
            Row(
              children: [
                if (f.summary.isNotEmpty)
                  Expanded(
                    child: Text(
                      f.summary,
                      style: TextStyle(color: Colors.black.withOpacity(.7)),
                    ),
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Ver detalle'),
                  onPressed: f.title.isEmpty ? null : () => _openFormulaDetail(f),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* =================== Modelos simples =================== */

class _Formula {
  final String id;
  final String title;
  final String latex;
  final String summary;
  final String topic;
  final String conditions;

  _Formula({
    required this.id,
    required this.title,
    required this.latex,
    required this.summary,
    required this.topic,
    required this.conditions,
  });
}

class _AiSuggestion {
  final String id;
  final String title;
  final String why;
  final double? confidence;
  final List<_VarMap> variables;

  _AiSuggestion({
    required this.id,
    required this.title,
    required this.why,
    required this.confidence,
    required this.variables,
  });
}

class _VarMap {
  final String symbol;
  final String fromText;
  _VarMap({required this.symbol, required this.fromText});
}