import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/class_service.dart';
import '../../data/classes/class_model.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _gradeCtrl = TextEditingController();
  final _groupCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _gradeCtrl.dispose();
    _groupCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_loading) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión como profesor.')),
      );
      return;
    }

    final grade = _gradeCtrl.text.trim();
    final group = _groupCtrl.text.trim().toUpperCase();
    final subject = _subjectCtrl.text.trim();

    if (grade.isEmpty || group.isEmpty || subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa grado, grupo y materia.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final ClassRoom cls = await ClassService.instance.createClass(
        teacherId: user.uid,
        subject: subject,
        grade: grade,
        group: group,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text('Clase creada: ${cls.displayName}\nCódigo: ${cls.code}'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear clase: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear clase'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Completa los datos para crear tu clase y compartir el código con tus alumnos.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurface.withOpacity(.75)),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _gradeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Grado',
                        hintText: 'Ej. 1, 2, 3…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _groupCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Grupo',
                        hintText: 'Ej. A, B, C…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _subjectCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Materia',
                        hintText: 'Ej. Física, Matemáticas…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _loading ? null : _create,
                child: _loading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text(
                  'Crear clase',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
