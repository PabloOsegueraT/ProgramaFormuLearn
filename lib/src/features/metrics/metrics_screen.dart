import 'package:flutter/material.dart';

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Métricas y progreso')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Card(child: ListTile(leading: Icon(Icons.timeline), title: Text('Progreso general'), subtitle: Text('Gráfica demo'))),
            SizedBox(height: 12),
            Card(child: ListTile(leading: Icon(Icons.star), title: Text('Recomendaciones'), subtitle: Text('Estudia MRU y pH'))),
          ],
        ),
      ),
    );
  }
}
