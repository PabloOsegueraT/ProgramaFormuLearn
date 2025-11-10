
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/class_service.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gradeCtrl = TextEditingController();
  final _groupCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  bool _loading = false;
  String? _createdCode;

  @override
  void dispose() {
    _gradeCtrl.dispose();
    _groupCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión como profesor.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final cls = await ClassService.instance.createClass(
        teacherId: user.uid,
        subject: _subjectCtrl.text.trim(),
        grade: _gradeCtrl.text.trim(),
        group: _groupCtrl.text.trim(),
      );
      setState(() => _createdCode = cls.code);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear clase: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear clase')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _gradeCtrl,
                    decoration: const InputDecoration(labelText: 'Grado'),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Obligatorio' : null,
                  ),
                  TextFormField(
                    controller: _groupCtrl,
                    decoration: const InputDecoration(labelText: 'Grupo'),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Obligatorio' : null,
                  ),
                  TextFormField(
                    controller: _subjectCtrl,
                    decoration: const InputDecoration(labelText: 'Materia'),
                    validator: (v) =>
                    v == null || v.isEmpty ? 'Obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _onSubmit,
                    child: _loading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Crear clase'),
                  ),
                ],
              ),
            ),
            if (_createdCode != null) ...[
              const SizedBox(height: 24),
              const Text('Código para compartir:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SelectableText(
                _createdCode!,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
