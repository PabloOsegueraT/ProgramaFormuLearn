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
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final title = (args?['title'] ?? 'Fórmula') as String;
    final expression = (args?['expression'] ?? '') as String;
    final summary = (args?['summary'] ?? '') as String;
    final topic = (args?['topic'] ?? '') as String;

    final explanation = (args?['explanation'] ?? summary) as String;
    final variables = (args?['variables'] ?? const <String, String>{}) as Map<String, String>;
    final conditions = (args?['conditions'] ?? const <String>[]) as List<String>;

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
                  Text(title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
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
          _SectionTitle('Explicación'),
          _SectionCard(
            child: Text(
              explanation,
              style: const TextStyle(height: 1.35),
            ),
          ),
          const SizedBox(height: 12),

          // Variables y unidades
          _SectionTitle('Variables y unidades'),
          _SectionCard(
            child: Column(
              children: variables.entries
                  .map((e) => ListTile(
                dense: true,
                leading: const Icon(Icons.label_outline),
                title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(e.value),
              ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Condiciones de uso
          _SectionTitle('Condiciones de uso'),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: conditions.isEmpty
                  ? [const Text('—')]
                  : conditions
                  .map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(c)),
                  ],
                ),
              ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Generación de ejemplos con IA (visual)
          _SectionTitle('Generación de ejemplos con IA'),
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
                    hintText: 'p.ej. “correr 100 m en 12 s”, “carrito con masa 2 kg en una rampa”…',
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
                      // Solo demo visual: “generamos” un ejemplo usando la fórmula y el prompt
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

  String _demoExample(String expr, Map<String, String> variables) {
    // Crea un texto demostrativo a partir de la ecuación y sus variables (solo UI)
    if (expr.contains('v = d / t')) {
      return 'Si d = 100 m y t = 10 s → v = 100 / 10 = 10 m/s.';
    }
    if (expr.contains('ΣF = m · a')) {
      return 'Si m = 2 kg y a = 3 m/s² → ΣF = 2 · 3 = 6 N.';
    }
    if (expr.contains('K = ½')) {
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
      style:
      Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
