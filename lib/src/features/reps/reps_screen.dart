import 'package:flutter/material.dart';

class RepsScreen extends StatelessWidget {
  const RepsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = List.generate(6, (i) => 'Tarjeta #${i + 1}');
    return Scaffold(
      appBar: AppBar(title: const Text('Repasos inteligentes')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) => Card(child: ListTile(leading: const Icon(Icons.style), title: Text(items[i]))),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: items.length,
      ),
    );
  }
}
