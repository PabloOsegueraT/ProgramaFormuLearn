import 'package:flutter/material.dart';
import '../../router.dart';

class PhysicsScreen extends StatefulWidget {
  const PhysicsScreen({super.key});

  @override
  State<PhysicsScreen> createState() => _PhysicsScreenState();
}

class _PhysicsScreenState extends State<PhysicsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  final List<_Phys> _items = const [
    _Phys(
      name: 'MRU (Movimiento rectilíneo uniforme)',
      expr: 'v = d / t',
      desc: 'Velocidad constante; la distancia es proporcional al tiempo.',
      explanation:
      'En el MRU, la velocidad es constante y el movimiento ocurre en línea recta. '
          'La relación entre distancia (d), velocidad (v) y tiempo (t) es lineal.',
      variables: {
        'v': 'Velocidad (m/s)',
        'd': 'Distancia (m)',
        't': 'Tiempo (s)',
      },
      conditions: [
        'La velocidad es constante (aceleración nula).',
        'Trayectoria rectilínea.',
        'Ausencia de fuerzas que cambien la velocidad.',
      ],
    ),
    _Phys(
      name: 'Segunda ley de Newton',
      expr: 'ΣF = m · a',
      desc: 'La aceleración es proporcional a la fuerza neta e inversa a la masa.',
      explanation:
      'La segunda ley de Newton establece que la aceleración de un objeto es directamente '
          'proporcional a la fuerza neta que actúa sobre él e inversamente proporcional a su masa.',
      variables: {
        'ΣF': 'Fuerza neta (N)',
        'm': 'Masa (kg)',
        'a': 'Aceleración (m/s²)',
      },
      conditions: [
        'Sistema inercial (o considerar fuerzas ficticias).',
        'Masa constante.',
        'Fuerzas correctamente sumadas vectorialmente.',
      ],
    ),
    _Phys(
      name: 'Energía cinética',
      expr: 'K = ½ · m · v²',
      desc: 'Energía asociada al movimiento de un cuerpo.',
      explanation:
      'La energía cinética es la energía que posee un cuerpo debido a su movimiento. '
          'Depende de su masa y del cuadrado de su velocidad.',
      variables: {
        'K': 'Energía cinética (J)',
        'm': 'Masa (kg)',
        'v': 'Velocidad (m/s)',
      },
      conditions: [
        'Sistema clásico (velocidades mucho menores que c).',
        'Masa constante.',
        'Medición de velocidad respecto a un marco de referencia definido.',
      ],
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((f) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return f.name.toLowerCase().contains(q) ||
          f.expr.toLowerCase().contains(q) ||
          f.desc.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Física')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Buscador
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar fórmula (p.ej. “MRU”, “Newtom”, “K=…”)',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),

          // Resultados
          ...filtered.map((f) => Card(
            child: ListTile(
              leading: const Icon(Icons.functions),
              title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(f.expr),
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
                    'explanation': f.explanation,
                    'variables': f.variables, // Map<String, String>
                    'conditions': f.conditions, // List<String>
                  },
                );
              },
            ),
          )),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(child: Text('Sin resultados para tu búsqueda.')),
            ),
        ],
      ),
    );
  }
}

class _Phys {
  final String name, expr, desc, explanation;
  final Map<String, String> variables;
  final List<String> conditions;
  const _Phys({
    required this.name,
    required this.expr,
    required this.desc,
    required this.explanation,
    required this.variables,
    required this.conditions,
  });
}
