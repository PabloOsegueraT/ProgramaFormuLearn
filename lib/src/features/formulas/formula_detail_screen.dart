// lib/src/features/formulas/formula_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../config/env.dart';

class FormulaDetailScreen extends StatefulWidget {
  const FormulaDetailScreen({super.key});

  @override
  State<FormulaDetailScreen> createState() => _FormulaDetailScreenState();
}

class _FormulaDetailScreenState extends State<FormulaDetailScreen> {
  final _iaCtrl = TextEditingController();
  bool _genLoading = false;

  /// Markdown que muestra la explicación bonita
  String? _generatedMd;

  /// Resultado breve extraído del markdown (para la tarjeta destacada)
  String? _finalResult;

  @override
  void dispose() {
    _iaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        (ModalRoute.of(context)?.settings.arguments as Map?) ?? <String, dynamic>{};

    // --- Normalización robusta (sin cambiar UI principal) ---
    final String title = (args['title'] ?? 'Fórmula').toString();
    final String expression = (args['expression'] ?? '').toString();
    final String summary = (args['summary'] ?? '').toString();
    final String topic = (args['topic'] ?? '').toString();

    final String explanation = (args['explanation'] ?? summary).toString();
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

          // Generación de ejemplos con IA (mejor presentación)
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
                    labelText: 'Generar ejemplo a partir de…',
                    hintText: 'p.ej. “correr 100 m en 12 s”, “carrito de 2 kg…”',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.auto_awesome),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(_genLoading ? 'Generando…' : 'Generar ejemplo'),
                    ),
                    onPressed: _genLoading
                        ? null
                        : () => _generateExampleWithAI(
                      title: title,
                      topic: topic,
                      expression: expression,
                      variables: variables,
                      userHint: _iaCtrl.text.trim(),
                    ),
                  ),
                ),

                // Resultado destacado
                if (_finalResult != null) ...[
                  const SizedBox(height: 12),
                  _ResultCallout(text: _finalResult!),
                ],

                // Markdown bonito
                if (_generatedMd != null) ...[
                  const SizedBox(height: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withOpacity(.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outline.withOpacity(.12)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: MarkdownBody(
                        data: _generatedMd!,
                        selectable: true,
                        softLineBreak: true,
                        styleSheet: _mdStyle(context),
                        onTapLink: (_, __, ___) {}, // por si hay links
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- IA: genera markdown + extrae el resultado ----------
  Future<void> _generateExampleWithAI({
    required String title,
    required String topic,
    required String expression,
    required Map<String, String> variables,
    required String userHint,
  }) async {
    if (userHint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe una base para el ejemplo')),
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
      _genLoading = true;
      _generatedMd = null;
      _finalResult = null;
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig:  GenerationConfig(
          temperature: 0.7,
          topP: 0.95,
        ),
      );

      // Le pedimos a la IA Markdown limpio y una línea marcada con [RESULTADO]:
      final prompt = '''
Eres un profesor. Crea un ejemplo resuelto, claro y breve, usando **Markdown** bonito.

Contexto:
- Materia: ${topic.isEmpty ? '—' : topic}
- Fórmula a usar: `$expression`
- Variables: ${variables.entries.map((e) => '${e.key} = ${e.value}').join(', ')}
- Pista del usuario: "$userHint"

Estructura requerida en Markdown:
### Planteamiento
(frase breve que conecte con la pista)

### Datos
- lista con valores simbólicos introducidos (si no hay, indica que se asumirán valores razonables)

### Desarrollo
- 2–5 pasos numerados con fórmulas en bloque rodeadas por **triple backticks**:
      
### Resultado
- frase final clara.

Al final escribe **una línea adicional** (fuera del Markdown) con este formato EXACTO para que la app lo destaque:
[RESULTADO]: <valor y unidades breves>
''';

      final res = await model.generateContent([Content.text(prompt)]);
      final text = (res.text ?? '').trim();

      // Extraer la línea [RESULTADO]:
      final rx = RegExp(r'^\[RESULTADO\]:\s*(.+)$', multiLine: true);
      String? result;
      String md = text;
      final m = rx.firstMatch(text);
      if (m != null) {
        result = m.group(1)?.trim();
        md = text.replaceAll(rx, '').trim();
      }

      if (!mounted) return;
      setState(() {
        _generatedMd = md.isEmpty ? 'No se pudo generar contenido.' : md;
        _finalResult = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generatedMd = 'Error IA: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() => _genLoading = false);
    }
  }

  // ---------- Helpers de normalización (no cambian UI) ----------
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

  MarkdownStyleSheet _mdStyle(BuildContext context) {
    final theme = Theme.of(context);
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      h3: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      p: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
      listBulletPadding: const EdgeInsets.only(right: 8),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(.4),
        borderRadius: BorderRadius.circular(12),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(.12)),
      ),
    );
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

class _ResultCallout extends StatelessWidget {
  final String text;
  const _ResultCallout({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Resultado: $text',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}