// lib/src/features/teacher/teacher_home_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../router.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _ClassesTab(),
      _TeacherProfileTab(),
    ];
    final titles = ['Panel del profesor', 'Perfil del profesor'];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_tab])),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.class_outlined),
            selectedIcon: Icon(Icons.class_),
            label: 'Clases',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

/// =============== TAB: CLASES (usa las nuevas rutas) ===============
class _ClassesTab extends StatelessWidget {
  const _ClassesTab();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TeacherHero(
          title: 'Gestiona tus clases',
          subtitle:
          'Crea grupos, comparte códigos con tus alumnos y revisa su desempeño.',
        ),
        const SizedBox(height: 16),

        // Crear nueva clase (usa CreateClassScreen con ClassService)
        Card(
          child: ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Crear nueva clase'),
            subtitle: const Text(
                'Define grado, grupo y materia. Se genera un código automático.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.pushNamed(context, AppRouter.createClass),
          ),
        ),
        const SizedBox(height: 8),

        // Mis clases (usa TeacherClassesScreen con datos de Firestore)
        Card(
          child: ListTile(
            leading: const Icon(Icons.class_),
            title: const Text('Mis clases'),
            subtitle:
            const Text('Ver todas las clases que has creado y sus códigos.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.pushNamed(context, AppRouter.teacherClasses),
          ),
        ),
        const SizedBox(height: 8),

        // Métricas (si ya tienen vista de analytics)
        Card(
          child: ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('Métricas de aprendizaje'),
            subtitle: const Text(
                'Predominio de estilos de aprendizaje y rendimiento por clase.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.pushNamed(context, AppRouter.teacherAnalytics),
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Tip: Crea una clase, comparte el código con tus alumnos y luego '
                'revisa sus resultados y actividad desde "Mis clases" y "Métricas".',
          ),
        ),
      ],
    );
  }
}

/// =============== TAB: PERFIL PROFESOR (visual) ===============
class _TeacherProfileTab extends StatelessWidget {
  const _TeacherProfileTab();

  // Datos demo (puedes luego ligarlo al usuario real)
  static const _kName = 'Mtro. Juan Pérez';
  static const _kEmail = 'juan.perez@formulearn.app';
  static const _kSubject = 'Física y Matemáticas';
  static const _kExperience = '8 años de experiencia';
  static const _kCampus = 'Preparatoria #3';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 40)),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            _kName,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 16),

        Card(
          child: Column(
            children: const [
              _ProfileItem(
                  title: 'Correo',
                  value: _kEmail,
                  icon: Icons.email_outlined),
              Divider(height: 0),
              _ProfileItem(
                  title: 'Materias',
                  value: _kSubject,
                  icon: Icons.menu_book_outlined),
              Divider(height: 0),
              _ProfileItem(
                  title: 'Experiencia',
                  value: _kExperience,
                  icon: Icons.timeline),
              Divider(height: 0),
              _ProfileItem(
                  title: 'Campus',
                  value: _kCampus,
                  icon: Icons.location_city_outlined),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Card(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Privacidad y seguridad',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    'FormuLearn protege la información siguiendo buenas prácticas '
                        'de seguridad. Esta sección es demostrativa; más adelante '
                        'podrás vincular tu cuenta institucional.',
                    style: TextStyle(
                        color: cs.onSurface.withOpacity(.9), height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.privacy_tip_outlined, size: 18),
                      SizedBox(width: 6),
                      Text('Consulta políticas completas en Ajustes.'),
                    ],
                  ),
                ]),
          ),
        ),
      ],
    );
  }
}

/// =============== Widgets de apoyo ===============
class _ProfileItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _ProfileItem(
      {required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value.isEmpty ? '—' : value),
    );
  }
}

class _TeacherHero extends StatelessWidget {
  final String title;
  final String subtitle;

  const _TeacherHero({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [cs.primaryContainer.withOpacity(.85), cs.surfaceVariant],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            color: Colors.black12,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Lottie.asset(
              'assets/lottie/form.json',
              fit: BoxFit.cover,
              repeat: true,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(.25),
                    Colors.white.withOpacity(.05)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
