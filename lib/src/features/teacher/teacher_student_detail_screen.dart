import 'package:flutter/material.dart';

class TeacherStudentDetailScreen extends StatelessWidget {
  const TeacherStudentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final name = (args?['name'] ?? 'Estudiante') as String;
    final email = (args?['email'] ?? 'sin-email') as String;
    final gradeGroup = (args?['gradeGroup'] ?? '—') as String;
    final style = (args?['style'] ?? '—') as String;
    final hits = (args?['hits'] ?? const <String, int>{}) as Map<String, int>;

    // Ordenamos de mayor a menor
    final sorted = hits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final cs = Theme.of(context).colorScheme;

    int totalConsultas = hits.values.fold(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ficha del alumno
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(radius: 28, child: Text(name.characters.first)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('$gradeGroup · $email'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.style_outlined, size: 16),
                              const SizedBox(width: 6),
                              Text('Estilo: $style'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Resumen rápido
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  icon: Icons.remove_red_eye_outlined,
                  label: 'Consultas totales',
                  value: '$totalConsultas',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  icon: Icons.today_outlined,
                  label: 'Hoy (demo)',
                  value: '${(totalConsultas / 10).floor()}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text('Consultas por fórmula (mayor a menor)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          // Lista de fórmulas con barras
          ...sorted.map((e) {
            final label = e.key;
            final value = e.value;
            final pct = totalConsultas == 0 ? 0.0 : value / totalConsultas;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(value: pct, minHeight: 10),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Consultas: $value'),
                        Text('${(pct * 100).round()}%'),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          if (sorted.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: Text('Sin datos de consulta (demo).')),
            ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _KpiCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.secondaryContainer,
              child: Icon(icon, color: cs.onSecondaryContainer),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label),
            ),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
