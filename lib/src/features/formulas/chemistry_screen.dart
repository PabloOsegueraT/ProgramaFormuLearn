import 'package:flutter/material.dart';
import '../../router.dart';

class ChemistryScreen extends StatelessWidget {
  const ChemistryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      _Item(
        name: 'Ley de los gases ideales',
        expr: 'P V = n R T',
        desc: 'Relaciona presión (P), volumen (V), moles (n) y temperatura (T).',
      ),
      _Item(
        name: 'pH',
        expr: 'pH = -\\log_{10}[H^+]',
        desc: 'Medida de la acidez según la concentración de iones hidrógeno.',
      ),
      _Item(
        name: 'Molaridad',
        expr: 'M = \\frac{n}{V}',
        desc: 'Concentración: moles de soluto por litro de solución.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Química')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final f = items[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.science),
              title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRouter.formulaDetail,
                  arguments: {
                    'title': f.name,
                    'expression': f.expr,
                    'summary': f.desc,
                    'topic': 'Química',
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Item {
  final String name, expr, desc;
  const _Item({required this.name, required this.expr, required this.desc});
}
