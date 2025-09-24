import 'package:flutter/material.dart';
import '../../router.dart';
import 'package:lottie/lottie.dart';


class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _ClassesTab(),
      const _TeacherProfileTab(),
    ];
    final titles = ['Panel del Profesor', 'Perfil del Profesor'];

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

/// ================== TAB: CLASES ==================
class _ClassesTab extends StatefulWidget {
  const _ClassesTab();

  @override
  State<_ClassesTab> createState() => _ClassesTabState();
}

class _ClassesTabState extends State<_ClassesTab> {
  // Controladores del formulario de “Crear clase”
  final _gradeCtrl = TextEditingController();   // p.ej. “3°”
  final _groupCtrl = TextEditingController();   // p.ej. “B”
  final _subjectCtrl = TextEditingController(); // p.ej. “Física”
  String? _generatedCode; // sólo visual

  // Lista demo de clases “creadas”
  final List<_ClassItem> _classes = [
    _ClassItem(grade: '1°', group: 'A', subject: 'Matemáticas', code: 'MAT-1A-8342'),
  ];

  @override
  void dispose() {
    _gradeCtrl.dispose();
    _groupCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  void _generateCode() {
    final g = _gradeCtrl.text.trim().replaceAll('°', '');
    final gr = _groupCtrl.text.trim().toUpperCase();
    final s = _subjectCtrl.text.trim();
    if (g.isEmpty || gr.isEmpty || s.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa Grado, Grupo y Materia')),
      );
      return;
    }
    final prefix = s.substring(0, s.length >= 3 ? 3 : s.length).toUpperCase();
    final millis = DateTime.now().millisecondsSinceEpoch.toString();
    final tail = millis.substring(millis.length - 4);
    setState(() => _generatedCode = '$prefix-$g$gr-$tail');
  }

  void _addClass() {
    if (_generatedCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Genera el código primero')),
      );
      return;
    }
    setState(() {
      _classes.insert(
        0,
        _ClassItem(
          grade: _gradeCtrl.text.trim(),
          group: _groupCtrl.text.trim().toUpperCase(),
          subject: _subjectCtrl.text.trim(),
          code: _generatedCode!,
        ),
      );
      _gradeCtrl.clear();
      _groupCtrl.clear();
      _subjectCtrl.clear();
      _generatedCode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cabecera
        // Cabecera animada con Lottie
        _TeacherHero(
          title: 'Gestiona tus clases',
          subtitle: 'Crea códigos y organiza tus grupos',
          // Puedes enlazar acciones rápidas (opcionales)
          primaryText: 'Generar código',
          onPrimary: _generateCode,
          secondaryText: 'Crear clase',
          onSecondary: _addClass,
        ),
        const SizedBox(height: 16),

        const SizedBox(height: 16),

        // Formulario crear clase
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Crear clase',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _OutlinedField(
                      controller: _gradeCtrl,
                      label: 'Grado',
                      hint: 'p.ej. 3°',
                      icon: Icons.grade,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OutlinedField(
                      controller: _groupCtrl,
                      label: 'Grupo',
                      hint: 'p.ej. B',
                      icon: Icons.group_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _OutlinedField(
                controller: _subjectCtrl,
                label: 'Materia',
                hint: 'p.ej. Física',
                icon: Icons.menu_book_outlined,
              ),
              const SizedBox(height: 12),

              if (_generatedCode != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline.withOpacity(.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.key, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Código de clase: $_generatedCode',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copiar (visual)',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Código copiado (demo)')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded),
                      ),
                    ],
                  ),
                ),
              if (_generatedCode != null) const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.vpn_key),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Generar código'),
                      ),
                      onPressed: _generateCode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add_circle),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Crear clase'),
                      ),
                      onPressed: _addClass,
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: const Text('Métricas de aprendizaje'),
            subtitle: const Text('Distribución VARK y detalle por estudiante'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, AppRouter.teacherAnalytics),
          ),
        ),

        const SizedBox(height: 16),

        Text('Mis clases',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),

        if (_classes.isEmpty)
          const _EmptyState(
            title: 'Aún no tienes clases',
            subtitle: 'Crea tu primera clase arriba y comparte el código con tus alumnos.',
          )
        else
          ..._classes.map((c) => _ClassCard(item: c)),
      ],
    );
  }
}

/// ================== TAB: PERFIL PROFESOR ==================
class _TeacherProfileTab extends StatelessWidget {
  const _TeacherProfileTab();

  // Datos fijos (visual)
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
              _ProfileItem(title: 'Correo', value: _kEmail, icon: Icons.email_outlined),
              Divider(height: 0),
              _ProfileItem(title: 'Materias', value: _kSubject, icon: Icons.menu_book_outlined),
              Divider(height: 0),
              _ProfileItem(title: 'Experiencia', value: _kExperience, icon: Icons.timeline),
              Divider(height: 0),
              _ProfileItem(title: 'Campus', value: _kCampus, icon: Icons.location_city_outlined),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Políticas y Privacidad (visual)
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Privacidad y seguridad',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'FormuLearn protege tu información siguiendo buenas prácticas de seguridad. '
                    'Los datos visibles aquí son solo de demostración. '
                    'Como profesor, podrás administrar clases y compartir códigos con tus alumnos. '
                    'En futuras versiones se habilitarán controles de acceso y cifrado de datos.',
                style: TextStyle(color: cs.onSurface.withOpacity(.9), height: 1.35),
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(Icons.privacy_tip_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('Consulta nuestras políticas en la sección de Ajustes.'),
                ],
              ),
            ]),
          ),
        ),
        const SizedBox(height: 24),

        // Botón Salir (regresa al login)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Salir de inicio de sesión',
                style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('¿Cerrar sesión?'),
                  content: const Text('¿Deseas salir y volver al inicio de sesión?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Salir'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (r) => false);
              }
            },
          ),
        ),
      ],
    );
  }
}

/// ================== Widgets de apoyo ==================
class _OutlinedField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  const _OutlinedField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ClassItem {
  final String grade;
  final String group;
  final String subject;
  final String code;
  _ClassItem({
    required this.grade,
    required this.group,
    required this.subject,
    required this.code,
  });
}

class _ClassCard extends StatelessWidget {
  final _ClassItem item;
  const _ClassCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.class_outlined),
        ),
        title: Text('${item.subject} — ${item.grade}${item.group}'),
        subtitle: Text('Código: ${item.code}'),
        trailing: const Icon(Icons.chevron_right),
        // 👇 Al tocar la clase, vamos al detalle con argumentos
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRouter.teacherClassDetail,
            arguments: {
              'subject': item.subject,
              'grade': item.grade,
              'group': item.group,
              'code': item.code,
              // Opcional: manda tu VARK/estudiantes si ya los tienes generados
              // 'vark': {'V': 50, 'A': 20, 'R': 20, 'K': 10},
              // 'students': <_Student>[...], // si los construyes antes
            },
          );
        },
      ),
    );
  }
}


class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.class_outlined, size: 42),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

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

class _TeacherHero extends StatelessWidget {
  const _TeacherHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.primaryText,
    this.secondaryText,
    this.onPrimary,
    this.onSecondary,
  });

  final String title;
  final String subtitle;
  final String? primaryText;
  final String? secondaryText;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 360,
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
          // Animación Lottie de fondo (puedes cambiar el asset)
          Positioned.fill(
            child: Lottie.asset(
              'assets/lottie/form.json', // o 'assets/lottie/teacher.json'
              fit: BoxFit.cover,
              repeat: true,
            ),
          ),
          // Capa “glass” para mejorar legibilidad del texto
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(.25), Colors.white.withOpacity(.05)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.2,
                  ),
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

