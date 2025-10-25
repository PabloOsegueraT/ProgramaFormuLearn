// lib/src/features/formulas/search_screen.dart
import 'package:flutter/material.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar fórmulas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Busca por nombre o tema',
              ),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Resultados (demo):'),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.functions),
                    title: Text('MRU'),
                    subtitle: Text('Física'),
                  ),
                  ListTile(
                    leading: Icon(Icons.functions),
                    title: Text('Ley de Ohm'),
                    subtitle: Text('Física/Eléctrica'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
