import 'package:flutter/material.dart';
import '../../router.dart';

class ChemistryScreen extends StatefulWidget {
  const ChemistryScreen({super.key});

  @override
  State<ChemistryScreen> createState() => _ChemistryScreenState();
}

class _ChemistryScreenState extends State<ChemistryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  final List<_ChemItem> _items = const [
    _ChemItem(
      name: 'Ley de los gases ideales',
      expr: 'P·V = n·R·T',
      desc: 'Relaciona presión, volumen, cantidad de sustancia y temperatura.',
      explanation:
      'El gas ideal es un modelo que aproxima el comportamiento de gases a baja presión y alta temperatura. '
          'La ecuación P·V = n·R·T liga la presión (P), el volumen (V), los moles (n), la constante de los gases (R) y la temperatura absoluta (T).',
      variables: {
        'P': 'Presión (Pa o atm)',
        'V': 'Volumen (m³ o L)',
        'n': 'Cantidad de sustancia (mol)',
        'R': 'Constante de los gases (8.314 J·mol⁻¹·K⁻¹) ≈ 0.08206 L·atm·mol⁻¹·K⁻¹',
        'T': 'Temperatura absoluta (K)',
      },
      conditions: [
        'Gas ideal (interacciones intermoleculares despreciables).',
        'Baja presión y/o alta temperatura respecto al punto de licuefacción.',
        'Usar unidades coherentes (si V en L y P en atm, usar R = 0.08206 L·atm·mol⁻¹·K⁻¹).',
      ],
    ),
    _ChemItem(
      name: 'pH',
      expr: r'pH = -\log_{10}[H^+]',
      desc: 'Medida logarítmica de la acidez según [H⁺].',
      explanation:
      'El pH cuantifica la acidez de una disolución acuosa como el negativo del logaritmo decimal '
          'de la actividad o concentración efectiva de iones hidrógeno. A 25 °C, pH + pOH = 14 (aprox.).',
      variables: {
        '[H⁺]': 'Concentración de iones hidrógeno (mol·L⁻¹)',
        'pH': 'Índice de acidez (adimensional)',
      },
      conditions: [
        'Soluciones acuosas diluidas; aproximación [H⁺] ≈ actividad.',
        'Temperatura cerca de 25 °C para usar pH + pOH ≈ 14.',
        'Para ácidos fuertes monopróticos, [H⁺] ≈ concentración del ácido.',
      ],
    ),
    _ChemItem(
      name: 'Molaridad',
      expr: r'M = \frac{n}{V}',
      desc: 'Concentración: moles de soluto por litro de solución.',
      explanation:
      'La molaridad (M) expresa cuántos moles de soluto hay por litro de solución. '
          'Es útil para preparar disoluciones y para cálculos estequiométricos en fase líquida.',
      variables: {
        'M': 'Molaridad (mol·L⁻¹)',
        'n': 'Cantidad de soluto (mol)',
        'V': 'Volumen de solución (L)',
      },
      conditions: [
        'Temperatura controlada (el volumen varía con T).',
        'Disoluciones homogéneas; medir V del total de la solución, no solo del solvente.',
        'Para diluciones: M₁V₁ = M₂V₂ (si no hay reacción química).',
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
      return f.name.toLowerCase().contains(q)
          || f.expr.toLowerCase().contains(q)
          || f.desc.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Química')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Buscador
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar fórmula (p.ej. “pH”, “gases”, “molaridad”…)',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),

          // Resultados
          ...filtered.map((f) => Card(
            child: ListTile(
              leading: const Icon(Icons.science_outlined),
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
                    'topic': 'Química',
                    'explanation': f.explanation,
                    'variables': f.variables,   // Map<String, String>
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

class _ChemItem {
  final String name, expr, desc, explanation;
  final Map<String, String> variables;
  final List<String> conditions;
  const _ChemItem({
    required this.name,
    required this.expr,
    required this.desc,
    required this.explanation,
    required this.variables,
    required this.conditions,
  });
}
