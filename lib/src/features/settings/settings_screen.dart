import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad y seguridad')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 48, color: cs.primary),
                const SizedBox(height: 16),
                Text(
                  'Nuestra prioridad es tu seguridad',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'FormuLearn protege tus datos personales como nombre, edad, correo y preferencias de estudio. '
                      'Estos datos no se comparten con terceros y solo se usan dentro de la aplicación para mejorar tu experiencia.',
                  style: TextStyle(height: 1.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Toda la información que proporciones se almacena de forma segura y únicamente con fines académicos. '
                      'Tus consultas, repasos y métricas son privados y solo tú puedes acceder a ellos desde tu cuenta.',
                  style: TextStyle(height: 1.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Recuerda que puedes editar o eliminar tu información en cualquier momento desde tu perfil.',
                  style: TextStyle(height: 1.4, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
