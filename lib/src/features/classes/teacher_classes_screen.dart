// lib/src/features/classes/teacher_classes_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/class_service.dart';
import '../../data/classes/class_model.dart';
import '../../router.dart';

class TeacherClassesScreen extends StatelessWidget {
  const TeacherClassesScreen({super.key});

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
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, AppRouter.createClass),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<ClassRoom>>(
        stream: ClassService.instance.teacherClasses(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final classes = snapshot.data ?? [];
          if (classes.isEmpty) {
            return const Center(child: Text('Aún no has creado clases.'));
          }
          return ListView.builder(
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final c = classes[index];
              return ListTile(
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
              );
            },
          );
        },
      ),
    );
  }
}
