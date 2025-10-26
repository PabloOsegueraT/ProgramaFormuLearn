import 'package:flutter/material.dart';
import '../../router.dart'; // o 'package:formulearn/src/router.dart'
import 'package:formulearn/src/features/ia/formulas_from_photo_screen.dart';
import 'package:formulearn/src/features/ia/graphs_from_photo_screen.dart';
class IAScreen extends StatelessWidget {
  const IAScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Módulo de IA')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Encabezado visual
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primaryContainer.withOpacity(.7), cs.surfaceVariant],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: const [
                CircleAvatar(radius: 26, child: Icon(Icons.psychology, size: 28)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '¿Qué quieres analizar?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Botón grande: Fórmulas
          _OptionCard(
            icon: Icons.functions_outlined,
            title: 'Fórmulas',
            subtitle: 'Problemas con texto o foto (OCR) • Sugerencia de fórmulas',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FormulasFromPhotoScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          // Botón grande: Gráficas
          _OptionCard(
            icon: Icons.show_chart_outlined,
            title: 'Gráficas',
            subtitle: 'Detectar tipo (lineal, parabólica, …) • Parámetros básicos',
            onTap: () {
              // Por ahora sólo demo visual; puedes navegar a tu flujo de "Gráficas"
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GraphsFromPhotoScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: cs.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        )),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(color: cs.onSurface.withOpacity(.8)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pantalla de demostración (placeholder) al tocar cada opción.
/// Puedes reemplazarla por tus pantallas reales de análisis.
class _StubPage extends StatelessWidget {
  const _StubPage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Aquí irá el flujo de "$title".\n(placeholder visual)',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}