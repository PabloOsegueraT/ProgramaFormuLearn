import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // <<< DATOS FIJOS (puedes cambiarlos libremente) >>>
  static const _kName = 'Pablo Oseguera Torres';
  static const _kAge = '18';
  static const _kLevel = 'Bachillerato';
  static const _kEmail = 'pablo@formulearn.app';
  static const _kPrefLearning = 'Videos/visual';
  static const _kDailyMinutes = '20–30';
  static const List<String> _kSubjects = ['Matemáticas', 'Física'];

  @override
  Widget build(BuildContext context) {
    final subjectsText = _kSubjects.join(', ');

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              _kName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 16),

          // Datos básicos
          Card(
            child: Column(
              children: const [
                _ProfileItem(title: 'Nombre', value: _kName, icon: Icons.badge),
                Divider(height: 0),
                _ProfileItem(title: 'Edad', value: _kAge, icon: Icons.calendar_today),
                Divider(height: 0),
                _ProfileItem(title: 'Nivel', value: _kLevel, icon: Icons.school),
                Divider(height: 0),
                _ProfileItem(title: 'Correo', value: _kEmail, icon: Icons.email),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Preferencias (fijas)
          Card(
            child: Column(
              children: [
                const _ProfileItem(
                  title: 'Preferencia de aprendizaje',
                  value: _kPrefLearning,
                  icon: Icons.lightbulb,
                ),
                const Divider(height: 0),
                const _ProfileItem(
                  title: 'Minutos diarios',
                  value: _kDailyMinutes,
                  icon: Icons.timer,
                ),
                const Divider(height: 0),
                _ProfileItem(
                  title: 'Materias de interés',
                  value: subjectsText,
                  icon: Icons.bookmarks,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helpers visuales
class _ProfileItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _ProfileItem({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value.isEmpty ? '—' : value),
    );
  }
}
