// lib/src/features/classes/teacher_classes_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/class_service.dart';
import '../../data/classes/class_model.dart';
import '../../router.dart';

class TeacherClassesScreen extends StatefulWidget {
  const TeacherClassesScreen({super.key});

  @override
  State<TeacherClassesScreen> createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends State<TeacherClassesScreen> {
  bool _loading = true;
  String? _error;
  List<ClassRoom> _classes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Debes iniciar sesión como profesor.';
        _classes = [];
      });
      return;
    }

    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final list =
      await ClassService.instance.teacherClassesOnce(user.uid);

      setState(() {
        _classes = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar clases: $e';
        _loading = false;
      });
    }
  }

  Future<void> _delete(ClassRoom c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar clase'),
        content: Text(
          '¿Seguro que deseas eliminar "${c.displayName}"?\n'
              'Esto la quitará para todos los alumnos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ClassService.instance.deleteClass(c.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Debes iniciar sesión como profesor.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis clases (profesor)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _classes.isEmpty
          ? const Center(
        child: Text(
          'Aún no has creado clases.\nUsa "Crear clase" para comenzar.',
          textAlign: TextAlign.center,
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          itemCount: _classes.length,
          itemBuilder: (context, index) {
            final c = _classes[index];
            return ListTile(
              leading: const Icon(Icons.class_),
              title: Text(c.displayName),
              subtitle: Text('Código: ${c.code}'),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRouter.classDetail,
                  arguments: {
                    'classId': c.id,
                    'className': c.displayName,
                  },
                );
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red),
                tooltip: 'Eliminar clase',
                onPressed: () => _delete(c),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRouter.createClass)
              .then((_) => _load());
        },
        icon: const Icon(Icons.add),
        label: const Text('Crear clase'),
      ),
    );
  }
}
