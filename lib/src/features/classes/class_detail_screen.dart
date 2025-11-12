// lib/src/features/classes/class_detail_screen.dart
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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
    if (user == null || classId.isEmpty) {
      return const Scaffold(body: Center(child: Text('Clase no encontrada.')));
    }
    final uid = user.uid;

    return Scaffold(
      appBar: AppBar(title: Text(fallbackName.isEmpty ? 'Clase' : fallbackName)),
      body: StreamBuilder<ClassRoom?>(
        stream: ClassService.instance.classStream(classId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final cls = snap.data;
          if (cls == null) {
            return const Center(child: Text('Esta clase ya no existe.'));
          }
          final isTeacher = cls.teacherId == uid;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                cls.displayName,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(isTeacher ? 'Vista para profesor' : 'Vista para estudiante',
                  style: TextStyle(
                      color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),

              if (isTeacher) _TeacherMetrics(classId: classId),
              if (isTeacher) const SizedBox(height: 16),

              _AssignmentsSection(classId: classId, isTeacher: isTeacher, uid: uid),
              const SizedBox(height: 16),

              if (isTeacher) _MembersSection(classId: classId),
              if (!isTeacher)
                _StudentEvaluationsSection(classId: classId, studentId: uid),
            ],
          );
        },
      ),
    );
  }
}

/* ──────────────── Métricas (profe) ──────────────── */
class _TeacherMetrics extends StatelessWidget {
  final String classId;
  const _TeacherMetrics({required this.classId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ClassMetrics>(
      stream: ClassService.instance.metricsForClass(classId),
      builder: (context, snapshot) {
        final m = snapshot.data;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: m == null || m.totalEvaluations == 0
                ? const Text('Aún no hay evaluaciones registradas en esta clase.',
                style: TextStyle(fontStyle: FontStyle.italic))
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Métricas de la clase',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Evaluaciones: ${m.totalEvaluations}'),
                Text('Promedio: ${m.averagePercent.toStringAsFixed(1)}%'),
                Text('Mediana: ${m.medianPercent.toStringAsFixed(1)}%'),
              ],
            ),
          ),
        );
      },
    );
  }
}

/* ──────────────── Actividades (ambos) ──────────────── */
class _AssignmentsSection extends StatelessWidget {
  final String classId;
  final bool isTeacher;
  final String uid;
  const _AssignmentsSection({
    required this.classId,
    required this.isTeacher,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              const Text('Actividades',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (isTeacher)
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva'),
                  onPressed: () => _showNewAssignmentDialog(context, classId),
                ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Assignment>>(
            stream: ClassService.instance.assignmentsStream(classId),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Aún no hay actividades.',
                      style: TextStyle(fontStyle: FontStyle.italic)),
                );
              }
              return Column(
                children: items.map((a) {
                  if (isTeacher) {
                    // Vista PROFESOR: igual que antes
                    return ListTile(
                      leading: const Icon(Icons.assignment_outlined),
                      title: Text(a.title),
                      subtitle: Text(a.description?.isNotEmpty == true
                          ? a.description!
                          : 'Creada: ${a.createdAt}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showSubmissionsSheet(context, classId, a),
                    );
                  }

                  // Vista ALUMNO: mostrar estado de la entrega + calificación
                  return StreamBuilder<Submission?>(
                    stream: ClassService.instance.mySubmissionStream(
                      classId: classId,
                      assignmentId: a.id,
                      studentId: uid,
                    ),
                    builder: (context, subSnap) {
                      final s = subSnap.data;
                      final submitted = s != null;
                      final graded =
                          (s?.gradeScore != null) && (s?.gradeMax != null);
                      final lines = <String>[];

                      if (submitted) {
                        lines.add('Entregado');
                        if ((s!.fileName ?? '').isNotEmpty) {
                          lines.add('Archivo: ${s.fileName}');
                        }
                        if ((s.note ?? '').isNotEmpty) {
                          lines.add('Nota: ${s.note}');
                        }
                        if (graded) {
                          final pct = s.percent!.toStringAsFixed(1);
                          lines.add('Calificación: ${s.gradeScore}/${s.gradeMax} ($pct%)');
                          if ((s.feedback ?? '').isNotEmpty) {
                            lines.add('Feedback: ${s.feedback}');
                          }
                        }
                      } else {
                        lines.add('Sin entregar');
                      }

                      return ListTile(
                        leading: Icon(
                          submitted ? Icons.check_circle : Icons.assignment_outlined,
                          color: submitted ? Colors.green : null,
                        ),
                        title: Text(a.title),
                        subtitle: Text(lines.join(' · ')),
                        trailing: OutlinedButton(
                          onPressed: () => _showSubmitDialog(context, classId, a.id, uid),
                          child: Text(submitted ? 'Editar entrega' : 'Entregar'),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ]),
      ),
    );
  }

  void _showNewAssignmentDialog(BuildContext context, String classId) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? dueAt;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Nueva actividad'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                      controller: titleCtrl,
                      decoration:
                      const InputDecoration(labelText: 'Título')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: descCtrl,
                      decoration:
                      const InputDecoration(labelText: 'Descripción')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(dueAt == null
                            ? 'Sin fecha límite'
                            : 'Entrega: ${dueAt.toString().substring(0, 16)}'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final now = DateTime.now();
                          final date = await showDatePicker(
                            context: ctx,
                            firstDate: now,
                            lastDate: DateTime(now.year + 5),
                            initialDate: now,
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                                context: ctx,
                                initialTime:
                                const TimeOfDay(hour: 23, minute: 59));
                            setState(() {
                              dueAt = DateTime(date.year, date.month, date.day,
                                  time?.hour ?? 23, time?.minute ?? 59);
                            });
                          }
                        },
                        child: const Text('Elegir fecha'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar')),
              FilledButton(
                onPressed: () async {
                  final me = FirebaseAuth.instance.currentUser!;
                  if (titleCtrl.text.trim().isEmpty) return;
                  await ClassService.instance.createAssignment(
                    classId: classId,
                    teacherId: me.uid,
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty
                        ? null
                        : descCtrl.text.trim(),
                    dueAt: dueAt,
                  );
                  // ignore: use_build_context_synchronously
                  Navigator.pop(ctx);
                },
                child: const Text('Crear'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSubmitDialog(BuildContext context, String classId,
      String assignmentId, String uid) async {
    final noteCtrl = TextEditingController();

    Uint8List? fileBytes;
    String? fileName;
    String? filePath;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Entregar actividad'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Notas (opcional)')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(fileName ?? 'Sin archivo',
                          overflow: TextOverflow.ellipsis),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final res = await FilePicker.platform.pickFiles(
                          allowMultiple: false,
                          withData: true, // Android/iOS modernos
                          type: FileType.any,
                        );
                        if (res != null && res.files.isNotEmpty) {
                          final f = res.files.single;
                          setState(() {
                            fileName = f.name;
                            fileBytes = f.bytes;
                            filePath = f.path;
                          });
                        }
                      },
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Archivo'),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar')),
              FilledButton(
                onPressed: () async {
                  await ClassService.instance.submitAssignment(
                    classId: classId,
                    assignmentId: assignmentId,
                    studentId: uid,
                    note: noteCtrl.text.trim().isEmpty
                        ? null
                        : noteCtrl.text.trim(),
                    fileName: fileName,
                    fileBytes: fileBytes,
                    filePath: filePath,
                  );
                  // ignore: use_build_context_synchronously
                  Navigator.pop(ctx);
                },
                child: const Text('Enviar'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSubmissionsSheet(
      BuildContext context, String classId, Assignment a) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .85,
        minChildSize: .5,
        maxChildSize: .95,
        builder: (_, controller) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Entregas — ${a.title}',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<List<Submission>>(
                    stream: ClassService.instance.submissionsStream(
                        classId: classId, assignmentId: a.id),
                    builder: (context, snap) {
                      final subs = snap.data ?? [];
                      if (subs.isEmpty) {
                        return const Center(
                            child: Text('Aún no hay entregas.'));
                      }
                      return ListView.builder(
                        controller: controller,
                        itemCount: subs.length,
                        itemBuilder: (_, i) {
                          final s = subs[i];
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text('Alumno: ${s.studentId}'),
                            subtitle: Text([
                              if ((s.note ?? '').isNotEmpty) 'Nota: ${s.note}',
                              if ((s.fileName ?? '').isNotEmpty)
                                'Archivo: ${s.fileName}',
                              if (s.percent != null)
                                'Calificación: ${s.gradeScore}/${s.gradeMax} (${s.percent!.toStringAsFixed(1)}%)',
                              if ((s.feedback ?? '').isNotEmpty)
                                'Feedback: ${s.feedback}',
                            ].join(' · ')),
                            trailing: OutlinedButton(
                              onPressed: () => _gradeDialog(
                                  ctx, classId, a.id, s.studentId),
                              child: const Text('Calificar'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _gradeDialog(BuildContext context, String classId, String assignmentId,
      String studentId) async {
    final scoreCtrl = TextEditingController();
    final maxCtrl = TextEditingController(text: '100');
    final fbCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Calificar entrega'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: scoreCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Puntaje')),
            const SizedBox(height: 8),
            TextField(
                controller: maxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Máximo')),
            const SizedBox(height: 8),
            TextField(
                controller: fbCtrl,
                decoration: const InputDecoration(
                    labelText: 'Retroalimentación (opcional)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final s = double.tryParse(scoreCtrl.text) ?? 0;
              final m = double.tryParse(maxCtrl.text) ?? 100;
              await ClassService.instance.gradeSubmission(
                classId: classId,
                assignmentId: assignmentId,
                studentId: studentId,
                score: s,
                maxScore: m,
                feedback: fbCtrl.text.trim().isEmpty
                    ? null
                    : fbCtrl.text.trim(),
              );
              // ignore: use_build_context_synchronously
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

/* ──────────────── Alumnos inscritos (profe) ──────────────── */
class _MembersSection extends StatelessWidget {
  final String classId;
  const _MembersSection({required this.classId});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Alumnos inscritos',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      SizedBox(
        height: 220,
        child: StreamBuilder<List<ClassMember>>(
          stream: ClassService.instance.classMembers(classId),
          builder: (context, snapshot) {
            final members =
            (snapshot.data ?? []).where((m) => m.role == 'student').toList();
            if (members.isEmpty) {
              return const Text('Aún no hay alumnos.',
                  style: TextStyle(fontStyle: FontStyle.italic));
            }
            return ListView(
              children: members.map((m) {
                final name =
                (m.displayName?.isNotEmpty == true) ? m.displayName : m.uid;
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text('Alumno: $name'),
                  subtitle: const Text(
                      'Toca para ver reporte individual (por implementar).'),
                );
              }).toList(),
            );
          },
        ),
      ),
    ]);
  }
}

/* ──────────────── Evaluaciones del alumno ──────────────── */
class _StudentEvaluationsSection extends StatelessWidget {
  final String classId;
  final String studentId;
  const _StudentEvaluationsSection(
      {required this.classId, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Tus evaluaciones en esta clase',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      SizedBox(
        height: 180,
        child: StreamBuilder<List<ClassEvaluation>>(
          stream:
          ClassService.instance.studentEvaluations(classId, studentId),
          builder: (context, snapshot) {
            final evals = snapshot.data ?? [];
            if (evals.isEmpty) {
              return const Text('Aún no tienes evaluaciones registradas en esta clase.',
                  style: TextStyle(fontStyle: FontStyle.italic));
            }
            return ListView(
              children: evals.map((e) {
                return ListTile(
                  leading: const Icon(Icons.assignment_turned_in_outlined),
                  title: Text(
                      'Puntaje: ${e.score}/${e.maxScore}   (${e.percent.toStringAsFixed(1)}%)'),
                  subtitle: Text('Fecha: ${e.createdAt}'),
                );
              }).toList(),
            );
          },
        ),
      ),
    ]);
  }
}
