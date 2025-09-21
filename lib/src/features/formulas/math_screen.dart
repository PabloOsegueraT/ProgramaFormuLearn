import 'package:flutter/material.dart';
import '../../router.dart';

class MathScreen extends StatelessWidget {
  const MathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      _Item(
        name: 'Ecuación cuadrática',
        expr: 'x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}',
        desc: 'Solución general para ecuaciones ax² + bx + c = 0.',
      ),
      _Item(
        name: 'Teorema de Pitágoras',
        expr: 'a^2 + b^2 = c^2',
        desc: 'En triángulos rectángulos, c es la hipotenusa.',
      ),
      _Item(
        name: 'Derivada de potencia',
        expr: '\\frac{d}{dx}(x^n) = n x^{n-1}',
        desc: 'Regla básica de derivación para potencias de x.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Matemáticas')),
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
                    'expression': f.expr,   // texto plano; se muestra grande
                    'summary': f.desc,
                    'topic': 'Matemáticas',
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
