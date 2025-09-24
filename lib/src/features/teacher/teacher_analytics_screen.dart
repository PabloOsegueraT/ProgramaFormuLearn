import 'package:flutter/material.dart';
import '../../router.dart';

class TeacherAnalyticsScreen extends StatelessWidget {
  const TeacherAnalyticsScreen({super.key});

  // ====== DATOS DEMO (solo UI) ======
  // Distribución VARK (porcentaje)
  static const vark = {'V': 42, 'A': 18, 'R': 25, 'K': 15};

  // Lista de estudiantes (demo). En una app real, estos datos vendrían del backend.
  static final students = [
    _Student(
      name: 'Ana López',
      email: 'ana@example.com',
      gradeGroup: '3°B',
      style: 'Visual',
      formulaHits: {
        'MRU (v = d / t)': 18,
        '2ª Ley de Newton (ΣF=m·a)': 14,
        'Energía cinética (K=½mv²)': 9,
        'Ecuación cuadrática': 22,
        'Pitágoras': 5,
        'Derivada de potencia': 7,
        'Gas ideal (PV=nRT)': 3,
        'pH': 4,
        'Molaridad': 2,
      },
    ),
    _Student(
      name: 'Luis Pérez',
      email: 'luis@example.com',
      gradeGroup: '3°B',
      style: 'Lectura/Escritura',
      formulaHits: {
        'Ecuación cuadrática': 30,
        'Derivada de potencia': 15,
        'Pitágoras': 12,
        'MRU (v = d / t)': 6,
        '2ª Ley de Newton (ΣF=m·a)': 8,
        'Energía cinética (K=½mv²)': 4,
        'Gas ideal (PV=nRT)': 10,
        'pH': 9,
        'Molaridad': 5,
      },
    ),
    _Student(
      name: 'María Díaz',
      email: 'maria@example.com',
      gradeGroup: '3°B',
      style: 'Kinestésico',
      formulaHits: {
        'MRU (v = d / t)': 7,
        '2ª Ley de Newton (ΣF=m·a)': 20,
        'Energía cinética (K=½mv²)': 17,
        'Ecuación cuadrática': 10,
        'Pitágoras': 6,
        'Derivada de potencia': 3,
        'Gas ideal (PV=nRT)': 1,
        'pH': 2,
        'Molaridad': 1,
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Métricas de aprendizaje')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== Gráfica VARK =====
          Text('Distribución de estilos (VARK)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _VarkBarChart(data: vark),
            ),
          ),
          const SizedBox(height: 16),

          // ===== Lista de estudiantes =====
          Row(
            children: [
              const Icon(Icons.group_outlined, size: 20),
              const SizedBox(width: 8),
              Text('Estudiantes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${students.length}'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ...students.map((s) => Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(s.name.characters.first),
              ),
              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${s.gradeGroup} · ${s.email}\nEstilo: ${s.style}'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRouter.teacherStudentDetail,
                  arguments: {
                    'name': s.name,
                    'email': s.email,
                    'gradeGroup': s.gradeGroup,
                    'style': s.style,
                    'hits': s.formulaHits, // Map<String,int>
                  },
                );
              },
            ),
          )),
        ],
      ),
    );
  }
}

class _VarkBarChart extends StatelessWidget {
  const _VarkBarChart({required this.data});
  final Map<String, int> data; // {'V':%, 'A':%, 'R':%, 'K':%}

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<int>(0, (a, b) => a + b);
    // Normalizamos a porcentaje si no suma 100 (demo tolerante)
    Map<String, double> perc = {};
    if (total == 0) {
      perc = {'V': 0, 'A': 0, 'R': 0, 'K': 0};
    } else {
      data.forEach((k, v) => perc[k] = (v / total) * 100.0);
    }

    Widget bar(String label, double value, IconData icon) {
      final pct = value.clamp(0, 100);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Icon(icon, size: 20),
            ),
            SizedBox(
              width: 28,
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  minHeight: 14,
                  value: pct / 100.0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 48,
              child: Text('${pct.toStringAsFixed(0)}%'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bar('V', perc['V'] ?? 0, Icons.insights_outlined),
        bar('A', perc['A'] ?? 0, Icons.record_voice_over_outlined),
        bar('R', perc['R'] ?? 0, Icons.menu_book_outlined),
        bar('K', perc['K'] ?? 0, Icons.handyman_outlined),
        const SizedBox(height: 8),
        Text(
          'Visual • Aural • Lectura/Escritura • Kinestésico',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
        ),
      ],
    );
  }
}

class _Student {
  final String name;
  final String email;
  final String gradeGroup;
  final String style; // Visual, Aural, Lectura/Escritura, Kinestésico
  final Map<String, int> formulaHits;
  const _Student({
    required this.name,
    required this.email,
    required this.gradeGroup,
    required this.style,
    required this.formulaHits,
  });
}
