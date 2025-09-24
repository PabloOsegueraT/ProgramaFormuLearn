import 'package:flutter/material.dart';
import '../../common/widgets/primary_button.dart';
import '../../router.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  // 👇 Controladores para los campos
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 40,
              backgroundColor: cs.primaryContainer,
              child: Icon(Icons.person, color: cs.primary, size: 42),
            ),
            const SizedBox(height: 16),

            // Campo correo
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            const SizedBox(height: 12),

            // Campo contraseña
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),

            const SizedBox(height: 20),

            // Botón ingresar
            PrimaryButton(
              text: 'Ingresar',
              icon: Icons.login,
              onPressed: () {
                final email = _emailCtrl.text.trim();
                final pass = _passwordCtrl.text.trim();

                final isProfesor = email.toLowerCase() == 'profesor' &&
                    pass.toLowerCase() == 'profesor';

                if (isProfesor) {
                  Navigator.pushReplacementNamed(context, AppRouter.teacherHome);
                } else {
                  Navigator.pushReplacementNamed(context, AppRouter.home);
                }
              },
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              icon: const Icon(Icons.app_registration),
              label: const Text('Crear cuenta'),
              onPressed: () => Navigator.pushNamed(context, AppRouter.register),
            ),
          ],
        ),
      ),
    );
  }
}

