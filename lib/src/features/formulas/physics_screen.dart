import 'package:flutter/material.dart';
import '../../router.dart';

class PhysicsScreen extends StatelessWidget {
  const PhysicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _Phys(name: 'MRU (Movimiento rectilíneo uniforme)', expr: 'v = d / t', desc: 'Velocidad constante; distancia proporcional al tiempo.'),
      _Phys(name: 'Segunda ley de Newton', expr: '∑F = m · a', desc: 'La aceleración es proporcional a la fuerza neta e inversa a la masa.'),
      _Phys(name: 'Energía cinética', expr: 'K = ½ · m · v²', desc: 'Energía asociada al movimiento.'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Física')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final f = items[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.functions),
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
                    'topic': 'Física',
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

class _Phys {
  final String name, expr, desc;
  const _Phys({required this.name, required this.expr, required this.desc});
}
