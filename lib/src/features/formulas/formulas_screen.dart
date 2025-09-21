import 'package:flutter/material.dart';
import '../../router.dart';

class FormulasScreen extends StatelessWidget {
  const FormulasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Libro de fórmulas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, AppRouter.search),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SubjectCard(
            icon: Icons.science_outlined,
            title: 'Física',
            subtitle: 'Cinemática, dinamica, energía…',
            onTap: () => Navigator.pushNamed(context, AppRouter.physics), // ← AQUI
          ),
          const SizedBox(height: 12),
          _SubjectCard(
            icon: Icons.calculate_outlined,
            title: 'Matemáticas',
            subtitle: 'Álgebra, cálculo, geometría (demo)',
            onTap: () => Navigator.pushNamed(context, AppRouter.math),
          ),
          const SizedBox(height: 12),
          _SubjectCard(
            icon: Icons.biotech_outlined,
            title: 'Química',
            subtitle: 'Estequiometría, gases, pH (demo)',
            onTap: () => Navigator.pushNamed(context, AppRouter.chemistry),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _SubjectCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
