import 'package:flutter/material.dart';
import '../../common/widgets/primary_button.dart';
import '../../router.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final uid = await AuthService.instance.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      // Lee el rol desde Firestore
      final rol = await AuthService.instance.fetchRole(uid);

      if (!mounted) return;
      if (rol == 'profesor') {
        Navigator.pushReplacementNamed(context, AppRouter.teacherHome);
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.home);
      }
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('invalid-email')) return 'El correo no tiene formato válido.';
    if (msg.contains('user-not-found')) return 'No existe un usuario con ese correo.';
    if (msg.contains('wrong-password')) return 'Contraseña incorrecta.';
    if (msg.contains('too-many-requests')) return 'Demasiados intentos. Intenta más tarde.';
    return 'No se pudo iniciar sesión. $msg';
  }

  Future<void> _showCreateProfesorDialog() async {
    final nameCtrl = TextEditingController(text: 'Mtro. Demo');
    final emailCtrl = TextEditingController(text: 'profe.demo@formulearn.app');
    final passCtrl  = TextEditingController(text: 'Profe12'); // contraseña corta válida (>= 6)

    final formKey = GlobalKey<FormState>();
    bool localLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: !localLoading,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Future<void> create() async {
              if (!formKey.currentState!.validate()) return;
              setLocal(() => localLoading = true);
              try {
                final uid = await AuthService.instance.signUp(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  password: passCtrl.text.trim(),
                  age: 30,
                  level: 'Universidad',
                  role: 'profesor',        // ← rol profesor en Firestore
                  // preferencias opcionales:
                  prefLearning: null,
                  dailyMinutes: null,
                  mainSubjects: const [],
                );

                if (!mounted) return;
                Navigator.pop(ctx); // cierra el diálogo

                // Al crear con Auth, ya quedas logueado con ese usuario.
                // Navega a la vista de profesor:
                Navigator.pushReplacementNamed(context, AppRouter.teacherHome);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profesor creado y autenticado.')),
                );
              } on Exception catch (e) {
                setLocal(() => localLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No se pudo crear el profesor: $e')),
                );
              }
            }

            return AlertDialog(
              title: const Text('Crear profesor (provisional)'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final e = v?.trim() ?? '';
                        final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
                        if (e.isEmpty) return 'Ingresa un correo';
                        if (!ok) return 'Correo inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: passCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (v) {
                        final p = v ?? '';
                        if (p.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nota: Esto es solo para desarrollo.\n'
                          'Si tus reglas requieren custom claims, puede que algunas\n'
                          'acciones no funcionen hasta asignarlas con Admin SDK.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: localLoading ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: localLoading ? null : create,
                  icon: const Icon(Icons.school),
                  label: localLoading
                      ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                      : const Text('Crear profesor'),
                ),
              ],
            );
          },
        );
      },
    );
  }

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

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Correo'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final e = v?.trim() ?? '';
                      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
                      if (e.isEmpty) return 'Ingresa tu correo';
                      if (!ok) return 'Correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    obscureText: true,
                    validator: (v) {
                      if ((v ?? '').isEmpty) return 'Ingresa tu contraseña';
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            PrimaryButton(
              text: _loading ? 'Ingresando...' : 'Ingresar',
              icon: Icons.login,
              onPressed: () {
                if (_loading) return;
                _submit();
              },
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              icon: const Icon(Icons.app_registration),
              label: const Text('Crear cuenta (alumno)'),
              onPressed: _loading ? null : () => Navigator.pushNamed(context, AppRouter.register),
            ),

            const SizedBox(height: 8),

            // === Botón provisional para crear PROFESOR ===
            TextButton.icon(
              icon: const Icon(Icons.school),
              label: const Text('Crear profesor (provisional)'),
              onPressed: _loading ? null : _showCreateProfesorDialog,
            ),
          ],
        ),
      ),
    );
  }
}