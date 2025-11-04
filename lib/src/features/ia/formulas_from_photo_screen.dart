// lib/src/features/ia/formulas_from_photo_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../config/env.dart';
import '../../router.dart';

// USA el nombre real de tu repo:
import '../../data/formulas/formulas_repository.dart';
import '../../data/formulas/formula_model.dart';

/* =================== Tipos/Helpers de materia =================== */

enum Subject { matematicas, fisica, quimica, desconocida }

String subjectLabel(Subject s) {
  switch (s) {
    case Subject.matematicas:
      return 'Matemáticas';
    case Subject.fisica:
      return 'Física';
    case Subject.quimica:
      return 'Química';
    default:
      return 'Desconocido';
  }
}

Subject guessSubject(String text) {
  final t = text.toLowerCase();

  final mathHits = [
    'función','parábola','pendiente','derivada','integral','ecuación','cuadrática',
    'sistema','matriz','logaritmo','trig','seno','coseno','grados','rad','gráfica','recta',
  ].where((k) => t.contains(k)).length;

  final phyHits = [
    'fuerza','aceleración','velocidad','masa','newton','energia','energía','trabajo','potencia',
    'movimiento','tiro','mru','mrua','dinámica','cinemática',
  ].where((k) => t.contains(k)).length;

  final chemHits = [
    'ph','ácido','base','reacción','molar','mol','estequiometr','concentración','equilibrio','oxidación',
  ].where((k) => t.contains(k)).length;

  if (mathHits == 0 && phyHits == 0 && chemHits == 0) return Subject.desconocida;
  if (mathHits >= phyHits && mathHits >= chemHits) return Subject.matematicas;
  if (phyHits >= mathHits && phyHits >= chemHits) return Subject.fisica;
  return Subject.quimica;
}

/* =================== Widget principal =================== */

class FormulasFromPhotoScreen extends StatefulWidget {
  const FormulasFromPhotoScreen({super.key});

  @override
  State<FormulasFromPhotoScreen> createState() => _FormulasFromPhotoScreenState();
}

class _FormulasFromPhotoScreenState extends State<FormulasFromPhotoScreen> {
  final _picker = ImagePicker();
  final _repo = FormulaRepository();

  XFile? _image;
  bool _ocrRunning = false;
  bool _aiLoading = false;

  final _problemCtrl = TextEditingController();

  // Catálogo y candidatos
  bool _loadingFormulas = true;
  final List<_Formula> _catalog = [];
  List<_Formula> _candidates = [];

  // Datos IA parseados
  Subject? _subjectDetected;        // final: preferimos el de la IA
  String? _aiIntent;                // problema | formula
  String? _aiExplanation;           // texto breve
  List<_AiSuggestion> _aiSuggestions = [];

  // Si no se pudo parsear JSON
  String? _aiRaw;

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

  /* =================== OCR =================== */

  Future<void> _pick(ImageSource src) async {
    final img = await _picker.pickImage(source: src, imageQuality: 85);
    if (img == null) return;
    setState(() {
      _image = img;
      _aiLoading = false;
      _aiRaw = null;
      _aiExplanation = null;
      _aiIntent = null;
      _aiSuggestions = [];
      _subjectDetected = null;
      _candidates = [];
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

  /* =================== Cargar catálogo =================== */

  Future<void> _loadFormulas() async {
    setState(() => _loadingFormulas = true);
    try {
      final List<FormulaModel> list = await _repo.getAllOnce();
      _catalog
        ..clear()
        ..addAll(list.map((f) => _Formula(
          id: f.id,
          title: f.titulo,
          latex: f.latex,
          summary: f.explicacion,
          topic: f.tema,
          conditions: _asStringList(f.condicionesUso),
        )));
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
          conditions: const ['Sin aceleración', 'Trayectoria recta'],
        ),
        _Formula(
          id: 'newton2',
          title: 'Segunda ley de Newton',
          latex: r'\sum F = m \cdot a',
          summary: 'Aceleración proporcional a fuerza neta e inversa a la masa.',
          topic: 'Física',
          conditions: const ['Sistema de referencia inercial'],
        ),
        _Formula(
          id: 'cuadratica',
          title: 'Ecuación cuadrática',
          latex: r'x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}',
          summary: 'Solución general para ax² + bx + c = 0.',
          topic: 'Matemáticas',
          conditions: const ['a ≠ 0', 'Dominio real si Δ ≥ 0'],
        ),
        _Formula(
          id: 'pH',
          title: 'pH',
          latex: r'pH = -\log_{10}[H^+]',
          summary: 'Medida de acidez según concentración de H⁺.',
          topic: 'Química',
          conditions: const ['Soluciones acuosas diluidas'],
        ),
      ]);
  }

  /* =================== IA: Análisis =================== */

  Future<void> _analyzeWithAI() async {
    final text = _problemCtrl.text.trim();
    if (text.isEmpty) {
      _snack('Primero captura o escribe el enunciado.');
      return;
    }

    final apiKey = Env.geminiApiKey;
    if (apiKey.isEmpty) {
      _snack('Falta GEMINI_API_KEY en .env');
      return;
    }

    // Pre-detección (por si la IA no responde sujeto)
    final guessed = guessSubject(text);
    final filtered = _filterBySubject(_catalog, guessed);

    setState(() {
      _subjectDetected = guessed;
      _candidates = filtered.take(min(80, filtered.length)).toList();
      _aiLoading = true;
      _aiRaw = null;
      _aiExplanation = null;
      _aiIntent = null;
      _aiSuggestions = [];
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final catalogJson = _candidates
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
5) Da una "explanation" clara y concisa (150–250 palabras).

Devuelve EXCLUSIVAMENTE JSON:
{
  "subject": "matematicas|fisica|quimica|desconocido",
  "intent": "problema|formula",
  "matches": [
    {
      "id": "<id en catálogo o '' si no está>",
      "title": "<título>",
      "why": "<justificación corta>",
      "variables": [{"symbol":"x","fromText":"..."}],
      "confidence": 0.0
    }
  ],
  "explanation": "<texto breve y claro>"
}
''';

      final input = [
        Content.text(prompt),
        Content.text('ENUNCIADO:\n$text'),
        Content.text('CATALOGO_JSON:\n${jsonEncode(catalogJson)}'),
      ];

      final resp = await model.generateContent(input);
      final raw = resp.text?.trim() ?? '';
      final jsonStr = _extractJson(raw);

      Map<String, dynamic>? map;
      try {
        map = jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (_) {
        // No se pudo parsear: mostramos crudo
        if (!mounted) return;
        setState(() {
          _aiRaw = raw.isEmpty ? 'Respuesta vacía de la IA.' : raw;
        });
        return;
      }

      // Parse exitoso
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

      // Materia e intención desde IA
      final subj = (map['subject'] as String? ?? '').toLowerCase();
      final intent = (map['intent'] as String? ?? '').toLowerCase();
      final explanation = (map['explanation'] as String? ?? '').trim();

      Subject? detected;
      if (subj.contains('mat')) detected = Subject.matematicas;
      else if (subj.contains('fis') || subj.contains('fís')) detected = Subject.fisica;
      else if (subj.contains('quim') || subj.contains('quím')) detected = Subject.quimica;
      else detected = Subject.desconocida;

      // Si la IA nos dio materia, la priorizamos y re-filtramos candidatos para próxima consulta
      final newCandidates = _filterBySubject(_catalog, detected);

      if (!mounted) return;
      setState(() {
        _subjectDetected = detected;
        _aiIntent = intent.isEmpty ? null : intent;
        _aiExplanation = explanation.isEmpty ? null : explanation;
        _aiSuggestions = parsed;
        _candidates = newCandidates.take(min(80, newCandidates.length)).toList();
        _aiRaw = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiRaw = 'Error IA: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() => _aiLoading = false);
    }
  }

  List<_Formula> _filterBySubject(List<_Formula> all, Subject s) {
    if (s == Subject.desconocida) return all;
    final wanted = subjectLabel(s).toLowerCase();
    final exact = all.where((f) => f.topic.toLowerCase() == wanted).toList();
    if (exact.isNotEmpty) return exact;
    // Fallback por palabras clave
    return all.where((f) {
      final t = '${f.title} ${f.summary}'.toLowerCase();
      if (s == Subject.matematicas) {
        return t.contains('ecuación') || t.contains('función') || t.contains('gráfic') ||
            t.contains('algebra') || t.contains('trig');
      }
      if (s == Subject.fisica) {
        return t.contains('fuerza') || t.contains('aceleración') ||
            t.contains('velocidad') || t.contains('movimiento') || t.contains('newton');
      }
      if (s == Subject.quimica) {
        return t.contains('ph') || t.contains('reacción') ||
            t.contains('molar') || t.contains('estequio') || t.contains('concentración');
      }
      return false;
    }).toList();
  }

  /* =================== Navegación/Utils =================== */

  void _openFormulaDetail(_Formula f) {
    Navigator.pushNamed(
      context,
      AppRouter.formulaDetail,
      arguments: {
        'title': f.title,
        'expression': f.latex,
        'summary': f.summary,
        'topic': f.topic,
        'explanation': f.summary,
        'variables': const <String, String>{},
        'conditions': f.conditions,
      },
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _extractJson(String s) {
    // 1) ```json ... ```  2) primer { ... último }
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', multiLine: true);
    final m = fence.firstMatch(s);
    if (m != null) return m.group(1)!.trim();
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return s.substring(start, end + 1).trim();
    }
    return s.trim();
  }

  /* =================== UI =================== */

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
          Text('Enunciado del problema',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: _problemCtrl,
            minLines: 4,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Pega o edita aquí el texto extraído…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Materia detectada y tamaño catálogo
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (_subjectDetected != null)
                _BadgeChip(
                  icon: Icons.category_outlined,
                  text: 'Materia: ${subjectLabel(_subjectDetected!)}',
                  color: _subjectColor(_subjectDetected!, cs),
                ),
              _BadgeChip(
                icon: Icons.functions,
                text: 'Catálogo: ${_catalog.length} fórmulas',
                color: cs.secondaryContainer,
              ),
              if (_candidates.isNotEmpty)
                _BadgeChip(
                  icon: Icons.tune,
                  text: 'Candidatas: ${_candidates.length}',
                  color: cs.tertiaryContainer,
                ),
            ],
          ),
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
            label: const Text('Analizar problema con IA'),
            onPressed: _analyzeWithAI,
          ),

          const SizedBox(height: 16),

          // Resumen IA bonito
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: (_aiExplanation != null || _aiIntent != null || _subjectDetected != null)
                ? _AiSummaryCard(
              subject: _subjectDetected,
              intent: _aiIntent,
              explanation: _aiExplanation,
            )
                : const SizedBox.shrink(),
          ),

          // Resultados IA
          if (_aiSuggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Sugerencias',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ..._aiSuggestions.map(_buildSuggestionCard),
          ],

          // Texto crudo (si no hubo JSON)
          if (_aiRaw != null) ...[
            const SizedBox(height: 12),
            _RawCard(text: _aiRaw!),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(_AiSuggestion s) {
    final f = _catalog.firstWhere(
          (e) => e.id == s.id || e.title.toLowerCase() == s.title.toLowerCase(),
      orElse: () => _Formula(
        id: s.id.isEmpty ? 'n/a' : s.id,
        title: s.title,
        latex: '',
        summary: '',
        topic: _subjectDetected != null ? subjectLabel(_subjectDetected!) : '',
        conditions: const [],
      ),
    );

    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.surfaceVariant.withOpacity(.45), cs.surface.withOpacity(.95)],
          ),
          border: Border.all(color: cs.outlineVariant.withOpacity(.3)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              children: [
                const Icon(Icons.functions, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    f.title.isEmpty ? s.title : f.title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                if (s.confidence != null)
                  _ConfidencePill(value: s.confidence!),
              ],
            ),
            const SizedBox(height: 10),

            // Expresión
            if (f.latex.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  f.latex,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
                ),
              ),
            if (f.latex.isNotEmpty) const SizedBox(height: 8),

            // Por qué
            if (s.why.isNotEmpty)
              Text('¿Por qué? ${s.why}', style: TextStyle(color: cs.onSurfaceVariant)),
            if (s.variables.isNotEmpty) const SizedBox(height: 8),

            // Variables chips
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
                      style: TextStyle(color: cs.onSurfaceVariant),
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

  /* =================== Utilidades locales =================== */

  List<String> _asStringList(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      return v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    final s = v.toString().trim();
    if (s.isEmpty) return const [];
    final parts = s
        .split(RegExp(r'[\n•,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.isEmpty ? <String>[s] : parts;
  }

  Color _subjectColor(Subject s, ColorScheme cs) {
    switch (s) {
      case Subject.matematicas: return cs.primaryContainer;
      case Subject.fisica: return cs.secondaryContainer;
      case Subject.quimica: return cs.tertiaryContainer;
      default: return cs.surfaceVariant;
    }
  }
}

/* =================== Widgets de la UI mejorada =================== */

class _AiSummaryCard extends StatelessWidget {
  final Subject? subject;
  final String? intent; // problema | formula
  final String? explanation;

  const _AiSummaryCard({this.subject, this.intent, this.explanation});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [cs.primaryContainer.withOpacity(.55), cs.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: cs.outlineVariant.withOpacity(.25)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen de la IA',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (subject != null)
                  Chip(
                    avatar: const Icon(Icons.school, size: 18),
                    label: Text('Materia: ${subjectLabel(subject!)}'),
                  ),
                if ((intent ?? '').isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.bolt, size: 18),
                    label: Text('Intención: ${intent == 'formula' ? 'Fórmula' : 'Problema'}'),
                  ),
              ],
            ),
            if ((explanation ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                explanation!,
                style: const TextStyle(height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RawCard extends StatelessWidget {
  final String text;
  const _RawCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SelectableText(text),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _BadgeChip({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(text),
      backgroundColor: color,
    );
  }
}

class _ConfidencePill extends StatelessWidget {
  final double value; // 0..1
  const _ConfidencePill({required this.value});

  @override
  Widget build(BuildContext context) {
    final p = (value * 100).clamp(0, 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(.25),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text('conf $p%'),
    );
  }
}

/* =================== Modelos simples (UI local) =================== */

class _Formula {
  final String id;
  final String title;
  final String latex;
  final String summary;
  final String topic;
  final List<String> conditions;

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