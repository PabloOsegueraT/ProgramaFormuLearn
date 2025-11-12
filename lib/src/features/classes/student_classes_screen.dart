// lib/src/features/classes/student_classes_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/class_service.dart';
import '../../data/classes/class_model.dart';
import '../../router.dart';

class StudentClassesScreen extends StatefulWidget {
  const StudentClassesScreen({super.key});

  @override
  State<StudentClassesScreen> createState() => _StudentClassesScreenState();
}

class _StudentClassesScreenState extends State<StudentClassesScreen> {
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
        _error = 'Debes iniciar sesión.';
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
      await ClassService.instance.studentClassesOnce(user.uid);

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

  Future<void> _openJoin() async {
    final joined = await Navigator.pushNamed(context, AppRouter.joinClass);
    if (joined == true) {
      await _load();
    }
  }

  Future<void> _leave(ClassRoom c) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salir de la clase'),
        content: Text('¿Seguro que quieres salir de "${c.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await ClassService.instance.leaveClass(
        classId: c.id,
        uid: user.uid,
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis clases')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _classes.isEmpty
          ? const Center(
        child: Text(
          'Aún no estás en ninguna clase.\nÚnete con un código.',
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
              leading: const Icon(Icons.class_outlined),
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
                icon: const Icon(Icons.exit_to_app,
                    color: Colors.red),
                tooltip: 'Salir de la clase',
                onPressed: () => _leave(c),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openJoin,
        icon: const Icon(Icons.add),
        label: const Text('Unirse con código'),
      ),
    );
  }
}
