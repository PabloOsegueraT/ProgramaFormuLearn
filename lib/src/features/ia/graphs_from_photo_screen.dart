// lib/src/features/ia/graphs_from_photo_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../config/env.dart';

class GraphsFromPhotoScreen extends StatefulWidget {
  const GraphsFromPhotoScreen({super.key});

  @override
  State<GraphsFromPhotoScreen> createState() => _GraphsFromPhotoScreenState();
}

class _GraphsFromPhotoScreenState extends State<GraphsFromPhotoScreen> {
  final _picker = ImagePicker();
  XFile? _image;
  bool _aiLoading = false;

  _GraphInsight? _insight; // datos estructurados
  String? _aiNotes;        // notas/advertencias legibles
  String? _friendlyError;  // errores para UI

  Future<void> _pick(ImageSource src) async {
    final img = await _picker.pickImage(source: src, imageQuality: 90);
    if (img == null) return;
    setState(() {
      _image = img;
      _insight = null;
      _aiNotes = null;
      _friendlyError = null;
    });
  }

  String _guessMime(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'heic':
        return 'image/heic';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _analyze() async {
    if (_image == null) {
      _snack('Primero toma o selecciona una imagen.');
      return;
    }
    final apiKey = Env.geminiApiKey;
    if (apiKey.isEmpty) {
      _snack('Falta GEMINI_API_KEY en .env');
      return;
    }

    setState(() {
      _aiLoading = true;
      _insight = null;
      _aiNotes = null;
      _friendlyError = null;
    });

    try {
      final bytes = await File(_image!.path).readAsBytes();
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        // generationConfig: GenerationConfig(temperature: 0.2),
      );

      final prompt = '''
Eres un analista de imágenes matemáticas. La imagen contiene una GRÁFICA.
Identifica el TIPO de gráfica y parámetros principales. Tipos soportados:
- "lineal" (y = m x + b) → params: {"m": <num>, "b": <num>}
- "parabolica" (y = a x^2 + b x + c) → params: {"a":<num>,"b":<num>,"c":<num>,"vertex":[xv,yv]}
- "exponencial" (y = A * e^(k x) o y = A * B^x) → params: {"A":<num>,"k":<num>} o {"A":<num>,"B":<num>}
- "barras" → bars: [{"label":"A","value":<num>}, ...]

Calcula además (si aplica):
- "intersections": {"x":[...], "y":<num|null>}  // x-intercepts y y-intercept
- "domain": "<texto corto>", "range": "<texto corto>"

Devuelve EXCLUSIVAMENTE un JSON con este esquema:
{
  "type": "lineal|parabolica|exponencial|barras|otro",
  "equation": "<ecuacion legible>",
  "params": { "m": 1.2, "b": -3.4 },          // o los que apliquen según el tipo
  "intersections": { "x": [..], "y": 0.0 },    // si aplica
  "bars": [ { "label": "A", "value": 10.0 } ], // solo si type == "barras"
  "pointsDetected": [ [x1,y1], [x2,y2] ],      // opcional, si los estimas
  "domain": "<texto>", "range": "<texto>",
  "explanation": "<explicacion concisa para estudiante>",
  "confidence": 0.0,
  "notes": "<advertencias o supuestos>"
}
No añadas texto fuera del JSON.
''';

      final mime = _guessMime(_image!.path);
      final content = Content.multi([
        TextPart(prompt),
        DataPart(mime, bytes),
      ]);

      final resp = await model.generateContent([content]);
      final out = (resp.text ?? '').trim();

      final parsed = _tryParseInsight(out);
      if (parsed != null) {
        setState(() {
          // ✅ Records: usar .$1 y .$2
          _insight = parsed.$1;
          _aiNotes = parsed.$2;
        });
      } else {
        setState(() {
          _friendlyError = 'No se pudo interpretar la respuesta de la IA.';
        });
      }
    } catch (e) {
      setState(() {
        _friendlyError = 'Error de IA: $e';
      });
    } finally {
      setState(() => _aiLoading = false);
    }
  }

  /// Devuelve (insight, notes) o null si falla.
  (_GraphInsight, String?)? _tryParseInsight(String raw) {
    try {
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      final jsonStr = (start >= 0 && end > start) ? raw.substring(start, end + 1) : raw;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      final insight = _GraphInsight.fromJson(map);
      final notes = (map['notes'] is String && (map['notes'] as String).trim().isNotEmpty)
          ? (map['notes'] as String).trim()
          : null;
      return (insight, notes); // record posicional
    } catch (_) {
      return null;
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Analizar gráfica (foto)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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

          if (_image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_image!.path),
                height: 220,
                fit: BoxFit.cover,
              ),
            ),

          const SizedBox(height: 16),

          _aiLoading
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(height: 8),
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Analizando gráfica con IA…'),
              ],
            ),
          )
              : FilledButton.icon(
            icon: const Icon(Icons.insights_outlined),
            label: const Text('Analizar gráfica con IA'),
            onPressed: _image == null ? null : _analyze,
          ),

          const SizedBox(height: 16),

          if (_friendlyError != null)
            _InfoCard(
              icon: Icons.error_outline,
              bg: Colors.red.withOpacity(.06),
              child: Text(_friendlyError!),
            ),

          if (_insight != null) ...[
            _SectionTitle('Resultado'),
            _ResultCard(insight: _insight!),

            if (_insight!.bars.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SectionTitle('Barras detectadas'),
              _BarsTable(bars: _insight!.bars),
            ],

            if (_aiNotes != null && _aiNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _SectionTitle('Notas'),
              _InfoCard(
                icon: Icons.info_outline,
                bg: cs.primaryContainer.withOpacity(.35),
                child: Text(_aiNotes!),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/* =================== UI widgets =================== */

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style:
      Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  final IconData icon;
  final Color bg;
  const _InfoCard({required this.child, required this.icon, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final _GraphInsight insight;
  const _ResultCard({required this.insight});

  String _typeLabel(String t) {
    switch (t) {
      case 'lineal':
        return 'Lineal (y = m x + b)';
      case 'parabolica':
        return 'Parabólica (y = a x² + b x + c)';
      case 'exponencial':
        return 'Exponencial';
      case 'barras':
        return 'Gráfico de barras';
      default:
        return 'Otro';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _typeLabel(insight.type),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                if (insight.confidence != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                        'conf ${(insight.confidence! * 100).clamp(0, 100).toStringAsFixed(0)}%'),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (insight.equation.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  insight.equation,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),

            if (insight.params.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Parámetros', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: insight.params.entries
                    .map((e) => Chip(
                  label: Text('${e.key} = ${_fmt(e.value)}'),
                  visualDensity: VisualDensity.compact,
                ))
                    .toList(),
              ),
            ],

            if (insight.intersectionsX.isNotEmpty || insight.intersectionY != null) ...[
              const SizedBox(height: 10),
              const Text('Intersecciones', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (insight.intersectionsX.isNotEmpty)
                    Chip(
                      label: Text('Cortes en X: ${insight.intersectionsX.map(_fmt).join(', ')}'),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (insight.intersectionY != null)
                    Chip(
                      label: Text('Corte en Y: ${_fmt(insight.intersectionY!)}'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],

            if (insight.domain.isNotEmpty || insight.range.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Dominio y rango', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              if (insight.domain.isNotEmpty) Text('Dominio: ${insight.domain}'),
              if (insight.range.isNotEmpty) Text('Rango: ${insight.range}'),
            ],

            if (insight.points.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Puntos estimados', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: insight.points
                    .map((p) => Chip(
                  // ✅ Point<double> usa x / y (no dx/dy)
                  label: Text('(${_fmt(p.x)}, ${_fmt(p.y)})'),
                  visualDensity: VisualDensity.compact,
                ))
                    .toList(),
              ),
            ],

            if (insight.explanation.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                insight.explanation,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(num v) {
    final d = v.toDouble();
    if (d.abs() >= 1000) return d.toStringAsFixed(0);
    if (d.abs() >= 10) return d.toStringAsFixed(2);
    return d.toStringAsFixed(3);
  }
}

class _BarsTable extends StatelessWidget {
  final List<_BarItem> bars;
  const _BarsTable({required this.bars});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: bars
              .map((b) => ListTile(
            dense: true,
            leading: const Icon(Icons.bar_chart),
            title: Text(b.label),
            trailing: Text(b.value.toStringAsFixed(2)),
          ))
              .toList(),
        ),
      ),
    );
  }
}

/* =================== Modelo de datos =================== */

class _GraphInsight {
  final String type; // lineal | parabolica | exponencial | barras | otro
  final String equation;
  final Map<String, double> params;
  final List<double> intersectionsX;
  final double? intersectionY;
  final List<_BarItem> bars;
  final List<math.Point<double>> points;
  final String domain;
  final String range;
  final String explanation;
  final double? confidence;

  _GraphInsight({
    required this.type,
    required this.equation,
    required this.params,
    required this.intersectionsX,
    required this.intersectionY,
    required this.bars,
    required this.points,
    required this.domain,
    required this.range,
    required this.explanation,
    required this.confidence,
  });

  factory _GraphInsight.fromJson(Map<String, dynamic> m) {
    double? _asDouble(dynamic x) {
      if (x == null) return null;
      if (x is num) return x.toDouble();
      final s = x.toString().replaceAll(',', '.');
      return double.tryParse(s);
    }

    List<double> _numList(dynamic v) {
      if (v is List) {
        return v.map((e) => _asDouble(e) ?? double.nan).where((e) => e.isFinite).toList();
      }
      return const [];
    }

    List<math.Point<double>> _points2(dynamic v) {
      if (v is List) {
        final out = <math.Point<double>>[];
        for (final e in v) {
          if (e is List && e.length >= 2) {
            final a = _asDouble(e[0]);
            final b = _asDouble(e[1]);
            if (a != null && b != null) out.add(math.Point(a, b));
          }
        }
        return out;
      }
      return const [];
    }

    final params = <String, double>{};
    if (m['params'] is Map) {
      (m['params'] as Map).forEach((k, v) {
        final dv = _asDouble(v);
        if (dv != null) params[k.toString()] = dv;
      });
    }

    final bars = <_BarItem>[];
    if (m['bars'] is List) {
      for (final e in m['bars'] as List) {
        if (e is Map) {
          final label = (e['label'] ?? '').toString();
          final val = _asDouble(e['value']);
          if (label.isNotEmpty && val != null) {
            bars.add(_BarItem(label: label, value: val));
          }
        }
      }
    }

    final inter = (m['intersections'] is Map) ? (m['intersections'] as Map) : {};
    final xints = _numList(inter['x']);
    final yint = _asDouble(inter['y']);

    return _GraphInsight(
      type: (m['type'] ?? 'otro').toString().toLowerCase(),
      equation: (m['equation'] ?? '').toString(),
      params: params,
      intersectionsX: xints,
      intersectionY: yint,
      bars: bars,
      points: _points2(m['pointsDetected']),
      domain: (m['domain'] ?? '').toString(),
      range: (m['range'] ?? '').toString(),
      explanation: (m['explanation'] ?? '').toString(),
      confidence: _asDouble(m['confidence']),
    );
  }
}

class _BarItem {
  final String label;
  final double value;
  _BarItem({required this.label, required this.value});
}