import 'package:flutter/material.dart';

class FormulaDetailScreen extends StatelessWidget {
  const FormulaDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map;
    final title = (args['title'] ?? 'Fórmula').toString();
    final expr = (args['expression'] ?? '').toString();
    final summary = (args['summary'] ?? '').toString();
    final topic = (args['topic'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (topic.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.category, size: 18),
                  const SizedBox(width: 6),
                  Text(topic, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fórmula', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SelectableText(
                    expr.isEmpty ? '—' : expr,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Explicación', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    summary.isEmpty ? 'Descripción breve de la fórmula.' : summary,
                    style: const TextStyle(height: 1.35),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
