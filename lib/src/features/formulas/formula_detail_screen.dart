import 'package:flutter/material.dart';

class FormulaDetailScreen extends StatefulWidget {
  const FormulaDetailScreen({super.key});

  @override
  State<FormulaDetailScreen> createState() => _FormulaDetailScreenState();
}

class _FormulaDetailScreenState extends State<FormulaDetailScreen> {
  final _iaCtrl = TextEditingController();
  String? _generated; // solo visual

  @override
  void dispose() {
    _iaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        (ModalRoute.of(context)?.settings.arguments as Map?) ?? <String, dynamic>{};

    // --- Normalización robusta (sin cambiar UI) ---
    final String title = (args['title'] ?? 'Fórmula').toString();
    final String expression = (args['expression'] ?? '').toString();
    final String summary = (args['summary'] ?? '').toString();
    final String topic = (args['topic'] ?? '').toString();

    final String explanation =
    (args['explanation'] ?? summary).toString();

    // variables puede venir como Map, List de maps o incluso String
    final Map<String, String> variables = _asStringMap(args['variables']);

    // conditions puede venir como List<String> o como String
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
                    child: SelectableText(
                      expression,
                      style: const TextStyle(fontSize: 18, fontFeatures: []),
                    ),
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

          // Generación de ejemplos con IA (visual)
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
                    labelText: 'Genere ejemplo a base de...',
                    hintText:
                    'p.ej. “correr 100 m en 12 s”, “carrito con masa 2 kg en una rampa”…',
                    border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.auto_awesome),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Generar ejemplo'),
                    ),
                    onPressed: () {
                      final prompt = _iaCtrl.text.trim();
                      if (prompt.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Escribe una base para el ejemplo')),
                        );
                        return;
                      }
                      // Solo demo visual
                      setState(() {
                        _generated =
                        'Ejemplo basado en: "$prompt"\n\n'
                            'Usando $expression:\n'
                            '${_demoExample(expression, variables)}\n\n'
                            'Interpretación: este ejemplo está adaptado a lo que escribiste. '
                            'En una versión con IA real, aquí verías el cálculo y la explicación paso a paso.';
                      });
                    },
                  ),
                ),
                if (_generated != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withOpacity(.45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outline.withOpacity(.15)),
                    ),
                    child: Text(_generated!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Helpers de normalización (no cambian UI) ----------

  /// Convierte cualquier entrada a `List<String>`:
  /// - null => []
  /// - List => lista de strings
  /// - String => intenta separar por saltos de línea, viñetas o comas; si no, devuelve [string]
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

  /// Convierte variables a `Map<String,String>` desde:
  /// - Map (cualquier tipo de claves/valores)
  /// - List de maps (ej: [{'symbol':'v','fromText':'velocidad'}])
  /// - String (ej: "v: velocidad, d: distancia")
  Map<String, String> _asStringMap(dynamic v) {
    if (v == null) return const {};
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), val.toString()));
    }
    if (v is List) {
      final out = <String, String>{};
      for (final item in v) {
        if (item is Map) {
          final key = (item['symbol'] ?? item['key'] ?? item['name'] ?? '').toString();
          final val = (item['meaning'] ??
              item['value'] ??
              item['desc'] ??
              item['fromText'] ??
              '')
              .toString();
          if (key.isNotEmpty) out[key] = val;
        } else {
          out[item.toString()] = '';
        }
      }
      return out;
    }
    // String plano
    final s = v.toString();
    final out = <String, String>{};
    for (final part in s.split(RegExp(r'[,\n]+'))) {
      final kv = part.split(':');
      if (kv.isEmpty) continue;
      final k = kv.first.trim();
      final val = kv.length > 1 ? kv.sublist(1).join(':').trim() : '';
      if (k.isNotEmpty) out[k] = val;
    }
    return out.isEmpty ? <String, String>{s: ''} : out;
  }

  String _demoExample(String expr, Map<String, String> variables) {
    if (expr.contains('v = d / t') || expr.contains(r'v = \frac{d}{t}')) {
      return 'Si d = 100 m y t = 10 s → v = 100 / 10 = 10 m/s.';
    }
    if (expr.contains('ΣF = m · a') || expr.contains(r'\sum F = m \cdot a')) {
      return 'Si m = 2 kg y a = 3 m/s² → ΣF = 2 · 3 = 6 N.';
    }
    if (expr.contains('K = ½') || expr.contains(r'K = \frac{1}{2}')) {
      return 'Si m = 1.5 kg y v = 4 m/s → K = ½ · 1.5 · 16 = 12 J.';
    }
    return 'Sustituye valores plausibles en las variables (${variables.keys.join(', ')}) y evalúa.';
  }
}

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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}