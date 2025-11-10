import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/class_service.dart';
import '../../data/classes/class_model.dart';

class ClassDetailScreen extends StatelessWidget {
  const ClassDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final classId = (args['classId'] ?? '') as String;
    final fallbackName = (args['className'] ?? '') as String;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Debes iniciar sesión.')),
      );
    }
    final uid = user.uid;

    if (classId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Clase no encontrada.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(fallbackName.isEmpty ? 'Clase' : fallbackName)),
      body: StreamBuilder<ClassRoom?>(
        stream: ClassService.instance.classStream(classId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final cls = snapshot.data;
          if (cls == null) {
            return const Center(child: Text('Esta clase ya no existe.'));
          }

          final isTeacher = cls.teacherId == uid;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cls.displayName,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  isTeacher ? 'Vista para profesor' : 'Vista para estudiante',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: isTeacher
                      ? _TeacherClassView(classId: classId)
                      : _StudentClassView(classId: classId, studentId: uid),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TeacherClassView extends StatelessWidget {
  final String classId;
  const _TeacherClassView({required this.classId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<ClassMetrics>(
          stream: ClassService.instance.metricsForClass(classId),
          builder: (context, snapshot) {
            final m = snapshot.data;
            if (m == null || m.totalEvaluations == 0) {
              return const Text(
                'Aún no hay evaluaciones registradas en esta clase.',
                style: TextStyle(fontStyle: FontStyle.italic),
              );
            }
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Métricas de la clase',
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text('Evaluaciones: ${m.totalEvaluations}'),
                    Text(
                        'Promedio: ${m.averagePercent.toStringAsFixed(1)}%'),
                    Text(
                        'Mediana: ${m.medianPercent.toStringAsFixed(1)}%'),
                    if (m.learningStyleCounts.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Estilos de aprendizaje (conteo):'),
                      Wrap(
                        spacing: 8,
                        children: m.learningStyleCounts.entries
                            .map(
                              (e) => Chip(
                            label: Text('${e.key}: ${e.value}'),
                          ),
                        )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Alumnos inscritos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<List<ClassMember>>(
            stream: ClassService.instance.classMembers(classId),
            builder: (context, snapshot) {
              final members = snapshot.data ?? [];
              final students =
              members.where((m) => m.role == 'student').toList();
              if (students.isEmpty) {
                return const Text(
                  'Aún no hay alumnos en esta clase.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                );
              }
              return ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final m = students[index];
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text('Alumno: ${m.uid}'),
                    subtitle: const Text(
                        'Toca para ver reporte individual (conectar luego).'),
                    onTap: () {
                      // Aquí luego conectas con AppRouter.teacherStudentDetail
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StudentClassView extends StatelessWidget {
  final String classId;
  final String studentId;
  const _StudentClassView({
    required this.classId,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ClassEvaluation>>(
      stream: ClassService.instance
          .studentEvaluations(classId, studentId),
      builder: (context, snapshot) {
        final evals = snapshot.data ?? [];
        if (evals.isEmpty) {
          return const Center(
            child: Text(
              'Aún no tienes evaluaciones registradas en esta clase.\n'
                  'Cuando completes evaluaciones, aparecerán aquí.',
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.builder(
          itemCount: evals.length,
          itemBuilder: (context, index) {
            final e = evals[index];
            return ListTile(
              leading:
              const Icon(Icons.assignment_turned_in_outlined),
              title: Text(
                  'Evaluación ${index + 1} - ${e.percent.toStringAsFixed(1)}%'),
              subtitle: Text(
                'Puntaje: ${e.score}/${e.maxScore}'
                    '${e.learningStyle != null ? ' · Estilo: ${e.learningStyle}' : ''}',
              ),
            );
          },
        );
      },
    );
  }
}

