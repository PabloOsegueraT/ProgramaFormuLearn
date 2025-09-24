import 'package:flutter/material.dart';
import '../../router.dart';

class MathScreen extends StatefulWidget {
  const MathScreen({super.key});

  @override
  State<MathScreen> createState() => _MathScreenState();
}

class _MathScreenState extends State<MathScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  final List<_MathItem> _items = const [
    _MathItem(
      name: 'Ecuación cuadrática',
      expr: r'x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}',
      desc: 'Solución general para ax² + bx + c = 0.',
      explanation:
      'La fórmula cuadrática permite hallar las raíces de un polinomio de segundo grado. '
          'Para ax²+bx+c=0, se sustituyen los coeficientes en la expresión y se obtienen hasta dos soluciones '
          'dependiendo del discriminante Δ = b² − 4ac.',
      variables: {
        'a': 'Coeficiente cuadrático (adimensional)',
        'b': 'Coeficiente lineal (adimensional)',
        'c': 'Término independiente (adimensional)',
        'Δ': 'Discriminante = b² − 4ac',
        'x': 'Solución/raíz (adimensional)',
      },
      conditions: [
        'a ≠ 0 (si a = 0 no es cuadrática).',
        'Si Δ > 0 hay dos raíces reales; Δ = 0 una raíz real doble; Δ < 0 raíces complejas.',
        'Conviene simplificar la ecuación antes de sustituir para evitar errores de signo.',
      ],
    ),
    _MathItem(
      name: 'Teorema de Pitágoras',
      expr: r'a^2 + b^2 = c^2',
      desc: 'En triángulos rectángulos, c es la hipotenusa.',
      explanation:
      'En un triángulo rectángulo, el cuadrado de la hipotenusa es igual a la suma de los cuadrados de los catetos. '
          'Permite calcular longitudes cuando se conocen las otras dos.',
      variables: {
        'a': 'Cateto (misma unidad de longitud)',
        'b': 'Cateto (misma unidad de longitud)',
        'c': 'Hipotenusa (misma unidad de longitud)',
      },
      conditions: [
        'Aplica únicamente a triángulos rectángulos (un ángulo de 90°).',
        'Todas las longitudes deben medirse en la misma unidad.',
      ],
    ),
    _MathItem(
      name: 'Derivada de potencia',
      expr: r'\frac{d}{dx}(x^n) = n \, x^{\,n-1}',
      desc: 'Regla básica de derivación para potencias de x.',
      explanation:
      'La derivada de x^n respecto a x es n·x^(n−1). Es la regla más usada para derivar polinomios y funciones potencia. '
          'Para n real, se asume dominio donde la expresión tenga sentido.',
      variables: {
        'x': 'Variable independiente',
        'n': 'Exponente real (adimensional)',
        'd/dx': 'Operador derivada respecto a x',
      },
      conditions: [
        'Para n ∈ ℝ, considerar el dominio donde x^n esté definido (p. ej., x>0 si n no entero).',
        'Linealidad: d/dx(ax^n + bx^m) = a·n·x^(n−1) + b·m·x^(m−1).',
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
      appBar: AppBar(title: const Text('Matemáticas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Buscador
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar fórmula (p.ej. “cuadrática”, “Pitágoras”, “derivada”…)',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),

          // Resultados
          ...filtered.map((f) => Card(
            child: ListTile(
              leading: const Icon(Icons.calculate_outlined),
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
                    'topic': 'Matemáticas',
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

class _MathItem {
  final String name, expr, desc, explanation;
  final Map<String, String> variables;
  final List<String> conditions;
  const _MathItem({
    required this.name,
    required this.expr,
    required this.desc,
    required this.explanation,
    required this.variables,
    required this.conditions,
  });
}

