// lib/src/features/formulas/formula_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../widgets/formula_math.dart';
import '../../config/env.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../widgets/inline_math_text.dart';

class FormulaDetailScreen extends StatefulWidget {
  const FormulaDetailScreen({super.key});

  @override
  State<FormulaDetailScreen> createState() => _FormulaDetailScreenState();
}

class _FormulaDetailScreenState extends State<FormulaDetailScreen> {
  final _iaCtrl = TextEditingController();
  bool _aiLoading = false;
  _GenExample? _gen; // Ejemplo estructurado
  String? _aiRaw; // Fallback texto libre

  @override
  void dispose() {
    _iaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final String title = (args['title'] ?? 'Fórmula').toString();
    final String expression = (args['expression'] ?? '').toString();
    final String summary = (args['summary'] ?? '').toString();
    final String topic = (args['topic'] ?? '').toString();
    final String explanation = (args['explanation'] ?? summary).toString();

    // Normalizadores robustos
    final Map<String, String> variables = _asStringMap(args['variables']);
    final List<String> conditions = _asStringList(args['conditions']);

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(topic.isEmpty ? title : '$topic · $title')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cabecera con la expresión
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant.withOpacity(.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FormulaMath(expression, fontSize: 22),
                  ),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(summary),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Explicación
          const _SectionTitle('Explicación'),
          _SectionCard(
            child: Text(
              explanation,
              style: const TextStyle(height: 1.35),
            ),
          ),
          const SizedBox(height: 12),

          // Variables y unidades
          const _SectionTitle('Variables y unidades'),
          _SectionCard(
            child: Column(
              children: variables.entries
                  .map(
                    (e) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.label_outline),
                  title: Text(
                    e.key,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(e.value.isEmpty ? '—' : e.value),
                ),
              )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Condiciones de uso
          const _SectionTitle('Condiciones de uso'),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: conditions.isEmpty
                  ? [const Text('—')]
                  : conditions
                  .map(
                    (c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(child: Text(c)),
                    ],
                  ),
                ),
              )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Generación de ejemplos con IA (contextual)
          const _SectionTitle('Generación de ejemplos con IA'),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _iaCtrl,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Crea un ejemplo con…',
                    hintText:
                    'p.ej. “Checo Pérez”, “un dron en ascenso”, “un ciclista en subida”…',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.auto_awesome),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Generar ejemplo contextual'),
                    ),
                    onPressed: () => _onGeneratePressed(
                      title: title,
                      expression: expression,
                      variables: variables,
                      conditions: conditions,
                    ),
                  ),
                ),
                if (_aiLoading) ...[
                  const SizedBox(height: 12),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (!_aiLoading && _gen != null) ...[
                  const SizedBox(height: 12),
                  _AiResultCard(gen: _gen!, scheme: cs),
                ],
                if (!_aiLoading && _gen == null && _aiRaw != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withOpacity(.45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outline.withOpacity(.15)),
                    ),
                    child: Text(_aiRaw!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========= IA: generar ejemplo contextual =========
  Future<void> _onGeneratePressed({
    required String title,
    required String expression,
    required Map<String, String> variables,
    required List<String> conditions,
  }) async {
    final themeHint = _iaCtrl.text.trim();
    if (themeHint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un tema: p.ej. “Checo Pérez”.')),
      );
      return;
    }

    final apiKey = Env.geminiApiKey;
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falta GEMINI_API_KEY en .env')),
      );
      return;
    }

    setState(() {
      _aiLoading = true;
      _gen = null;
      _aiRaw = null;
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final ctx = {
        'formulaTitle': title,
        'formulaExpression': expression, // texto o LaTeX
        'variables': variables, // {symbol: meaning}
        'conditions': conditions,
        'userTheme': themeHint, // ej: "Checo Pérez"
      };

      // PROMPT: construir un ejemplo/escenario con el tema del usuario
      final prompt = '''
Eres creador de ejemplos didácticos. Recibirás una fórmula (puede venir en LaTeX o texto), sus variables y un TEMA dado por el usuario (p.ej. "Checo Pérez").
Crea UN SOLO ejemplo contextual breve (2–3 frases de escenario) que use explícitamente ese tema y requiera aplicar ESA fórmula. Elige valores plausibles en unidades SI, resuelve con 4–8 pasos, y da un resultado final (usa LaTeX si es posible).

Devuelve SOLO JSON VÁLIDO (sin backticks) con este esquema:
{
  "exampleTitle": "string",
  "scenario": "string",
  "given": [
    {"symbol":"v","value":"90 m/s","note":"velocidad constante"}
  ],
  "unknown": "string",
  "steps": ["...", "..."],
  "resultLatex": "string",
  "resultText": "string",
  "explanation": "string"
}

Reglas:
- Usa SI y consistencia de unidades.
- Mantén el escenario explícitamente ligado al tema del usuario.
- Si la fórmula viene como 'd / t', puedes transformar a LaTeX \\frac{d}{t}.
- No devuelvas nada fuera del JSON.
''';

      final resp = await model.generateContent([
        Content.text(prompt),
        Content.text('CONTEXTO:\n${jsonEncode(ctx)}'),
      ]);

      final raw = (resp.text ?? '').trim();
      final clean = _stripCodeFences(raw);

      _GenExample? parsed;
      try {
        parsed = _GenExample.fromJson(jsonDecode(clean) as Map<String, dynamic>);
      } catch (_) {
        parsed = null;
      }

      if (!mounted) return;

      setState(() {
        _gen = parsed;
        _aiRaw = parsed == null ? raw : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _gen = null;
        _aiRaw = 'Error IA: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _aiLoading = false;
      });
    }
  }

  // ========= Normalizadores =========
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

  Map<String, String> _asStringMap(dynamic v) {
    if (v == null) return const {};
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), val.toString()));
    }
    if (v is List) {
      final out = <String, String>{};
      for (final item in v) {
        if (item is Map) {
          final key =
          (item['symbol'] ?? item['key'] ?? item['name'] ?? '').toString();
          final val = (item['meaning'] ??
              item['value'] ??
              item['desc'] ??
              item['fromText'] ??
              '')
              .toString();
          if (key.isNotEmpty) out[key] = val;
        }
      }
      return out;
    }
    final out = <String, String>{};
    for (final part in v.toString().split(RegExp(r'[,\n]+'))) {
      final kv = part.split(':');
      if (kv.isEmpty) continue;
      final k = kv.first.trim();
      final val =
      kv.length > 1 ? kv.sublist(1).join(':').trim() : '';
      if (k.isNotEmpty) out[k] = val;
    }
    return out;
  }

  String _stripCodeFences(String s) {
    final fence = RegExp(r'^```[a-zA-Z]*\s*([\s\S]*?)\s*```$');
    final m = fence.firstMatch(s);
    return m != null ? (m.group(1) ?? s).trim() : s;
  }
}

// ====== UI helpers ======
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

// ====== Card de resultado IA (escenario + pasos + LaTeX) ======
class _AiResultCard extends StatelessWidget {
  const _AiResultCard({required this.gen, required this.scheme});
  final _GenExample gen;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (gen.exampleTitle.isNotEmpty)
        Text(
          gen.exampleTitle,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      if (gen.scenario.isNotEmpty) ...[
        const SizedBox(height: 6),
        InlineMathText(
          gen.scenario,
          style: TextStyle(
            color: Colors.black.withOpacity(.75),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
      const SizedBox(height: 10),

      if (gen.given.isNotEmpty || gen.unknown.isNotEmpty) ...[
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ...gen.given.map(
                  (g) => Chip(
                avatar: const Icon(Icons.info_outline, size: 18),
                label: Text(
                  '${g.symbol}: ${g.value}${g.note != null && g.note!.isNotEmpty ? ' (${g.note})' : ''}',
                ),
              ),
            ),
            if (gen.unknown.isNotEmpty)
              Chip(
                avatar: const Icon(Icons.help_outline, size: 18),
                label: Text('Incógnita: ${gen.unknown}'),
              ),
          ],
        ),
        const SizedBox(height: 10),
      ],

      if (gen.steps.isNotEmpty) ...[
        const Text('Pasos', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        ...gen.steps.map(
              (s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                const SizedBox(width: 2),
                Expanded(child: InlineMathText(s)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],

      // --- Resultado (bonito y robusto) ---
      const Text('Resultado', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Builder(
        builder: (context) {
          final cs = Theme.of(context).colorScheme;

          final rawText = (gen.resultText ?? '').trim();
          final cleanedText = _cleanFences(_stripLabel(rawText));

          // 1) Preferimos LaTeX explícito, pero lo normalizamos y saneamos
          var preferLatex = (gen.resultLatex ?? '').trim();
          if (preferLatex.isNotEmpty) {
            preferLatex = _stripMathDelimiters(preferLatex);
            preferLatex = _balanceBraces(preferLatex);
          }

          // 2) Si no hay, intentamos extraer LaTeX del texto o convertir ASCII→LaTeX
          final extracted = _pickLatex(cleanedText);
          var latex = preferLatex.isNotEmpty
              ? preferLatex
              : (extracted != null
              ? _balanceBraces(extracted)
              : _asciiToLatex(cleanedText));

          final hasAnything = latex.trim().isNotEmpty || cleanedText.isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outline.withOpacity(.12)),
                ),
                child: hasAnything
                    ? Center(child: FormulaMath(latex, fontSize: 22))
                    : const Text('—'),
              ),
              if (cleanedText.isNotEmpty) ...[
                const SizedBox(height: 8),
                InlineMathText(
                  cleanedText,
                  style: TextStyle(color: Colors.black.withOpacity(.8)),
                ),
              ],
            ],
          );
        },
      ),
    ]);
  }
}

// ====== Modelo del JSON IA (acepta claves alternativas) ======
class _GenExample {
  final String exampleTitle; // antes problemTitle
  final String scenario; // historia/escena
  final List<_Given> given;
  final String unknown;
  final List<String> steps;
  final String? resultLatex;
  final String? resultText;
  final String? explanation;

  _GenExample({
    required this.exampleTitle,
    required this.scenario,
    required this.given,
    required this.unknown,
    required this.steps,
    this.resultLatex,
    this.resultText,
    this.explanation,
  });

  factory _GenExample.fromJson(Map<String, dynamic> m) => _GenExample(
    exampleTitle:
    (m['exampleTitle'] ?? m['problemTitle'] ?? '').toString(),
    scenario: (m['scenario'] ?? '').toString(),
    given: ((m['given'] as List?) ?? [])
        .map((e) => _Given.fromJson(e as Map<String, dynamic>))
        .toList(),
    unknown: (m['unknown'] ?? '').toString(),
    steps: ((m['steps'] as List?) ?? [])
        .map((e) => e.toString())
        .toList(),
    resultLatex: (m['resultLatex'] as String?)?.toString(),
    resultText: (m['resultText'] as String?)?.toString(),
    explanation: (m['explanation'] as String?)?.toString(),
  );
}

class _Given {
  final String symbol;
  final String value;
  final String? note;
  _Given({required this.symbol, required this.value, this.note});

  factory _Given.fromJson(Map<String, dynamic> m) => _Given(
    symbol: (m['symbol'] ?? '').toString(),
    value: (m['value'] ?? '').toString(),
    note: (m['note'] as String?)?.toString(),
  );
}

// Bloque reutilizable opcional (no es obligatorio usarlo)
class _ResultBlock extends StatelessWidget {
  const _ResultBlock({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final cleaned = _cleanFences(text);
    final latex = _pickLatex(cleaned) ?? _asciiToLatex(cleaned);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resultado', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline.withOpacity(.15)),
          ),
          child: Center(
            child: FormulaMath(
              latex,
              fontSize: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        InlineMathText(
          cleaned,
          fontSize: 16,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}

// ====== Helpers globales reutilizados ======

// Quita ```...```, ```json...``` y similares
String _cleanFences(String s) {
  var t = s.trim();
  t = t.replaceAll(RegExp(r'^```[a-zA-Z]*'), '');
  t = t.replaceAll('```', '');
  return t.trim();
}

// Quita prefijos "Resultado:", "Result:", etc.
String _stripLabel(String s) {
  var t = s.trim();
  t = t.replaceFirst(
      RegExp(r'^(Resultado|Resultado\:)\s*', caseSensitive: false), '');
  t = t.replaceFirst(
      RegExp(r'^(Result|Answer|Output)\s*\:\s*', caseSensitive: false), '');
  return t.trim();
}

// Devuelve el primer bloque LaTeX si existe: $...$, $$...$$, \(...\), \[...\]
String? _pickLatex(String s) {
  var t = s
      .replaceAll(r'\(', r'$')
      .replaceAll(r'\)', r'$')
      .replaceAll(r'\[', r'$$')
      .replaceAll(r'\]', r'$$');
  final m = RegExp(r'(\${1,2})(.+?)\1').firstMatch(t);
  if (m != null) return (m.group(2) ?? '').trim();
  return null;
}

// Conversión rápida ASCII → LaTeX razonable
String _asciiToLatex(String s) {
  var t = s.trim();
  if (t.isEmpty) return r'\text{(sin datos)}';

  // productos
  t = t.replaceAll('·', r'\cdot ');
  t = t.replaceAll('*', r'\cdot ');

  // aproximación
  t = t.replaceAll('≈', r'\approx ');

  // índices tipo v0 -> v_{0}
  t = t.replaceAllMapped(RegExp(r'([A-Za-z])(\d+)'), (m) => '${m[1]}_{${m[2]}}');

  // exponentes x^2, v0^2, 10^3 -> ^{...}
  t = t.replaceAllMapped(
      RegExp(r'([A-Za-z0-9\}\)])\^(-?\d+(\.\d+)?)'), (m) => '${m[1]}^{${m[2]}}');

  // unidades comunes
  t = t.replaceAllMapped(
      RegExp(r'(?<=\d|\))\s*(m/s|m\/s)\b'), (m) => r'\text{ m/s}');
  t = t.replaceAllMapped(RegExp(r'\bJ\b'), (m) => r'\text{ J}');

  return t;
}

// Quita delimitadores $...$, $$...$$, \(...\), \[...\]
String _stripMathDelimiters(String s) {
  var t = s.trim();
  if (t.startsWith(r'\(') && t.endsWith(r'\)')) {
    return t.substring(2, t.length - 2).trim();
  }
  if (t.startsWith(r'\[') && t.endsWith(r'\]')) {
    return t.substring(2, t.length - 2).trim();
  }
  if (t.startsWith(r'$$') && t.endsWith(r'$$')) {
    return t.substring(2, t.length - 2).trim();
  }
  if (t.startsWith(r'$') && t.endsWith(r'$')) {
    return t.substring(1, t.length - 1).trim();
  }
  return t.replaceAll(RegExp(r'^\$+|\$+$'), '').trim();
}

// Balancea llaves { } en expresiones LaTeX
String _balanceBraces(String s) {
  final opens = RegExp(r'\{').allMatches(s).length;
  final closes = RegExp(r'\}').allMatches(s).length;

  if (closes >= opens) return s.trim();

  final missing = opens - closes;
  final extra = List.filled(missing, '}').join();
  return (s + extra).trim();
}
