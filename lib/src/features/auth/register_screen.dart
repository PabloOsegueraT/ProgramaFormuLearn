import 'package:flutter/material.dart';
import '../../common/widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Paso actual: 0..2
  int step = 0;

  // Paso 1 – datos básicos
  final nameCtrl = TextEditingController(text: 'Pablo');
  final ageCtrl = TextEditingController(text: '18');
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String level = 'Bachillerato';

  // Paso 2 – test rápido
  String? prefLearning; // visual, ejemplos, lectura
  String? dailyMinutes; // 10-15, 20-30, 40+
  final Set<String> mainSubjects = {}; // Matemáticas, Física, Química

  @override
  void dispose() {
    nameCtrl.dispose();
    ageCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  double get progress => (step + 1) / 3.0;

  void next() => setState(() => step = (step + 1).clamp(0, 2));
  void back() => setState(() => step = (step - 1).clamp(0, 2));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FormuLearn'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Center(child: Text('MVP UI')),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(value: progress, minHeight: 6),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Título grande
            Text(
              'Crear cuenta',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text('Paso ${step + 1} de 3',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 16),

            // Contenido según el paso
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: switch (step) {
                0 => _StepOne(
                  nameCtrl: nameCtrl,
                  ageCtrl: ageCtrl,
                  emailCtrl: emailCtrl,
                  passCtrl: passCtrl,
                  level: level,
                  onLevelChanged: (v) => setState(() => level = v),
                ),
                1 => _StepTwo(
                  prefLearning: prefLearning,
                  onPrefLearning: (v) => setState(() => prefLearning = v),
                  dailyMinutes: dailyMinutes,
                  onDailyMinutes: (v) => setState(() => dailyMinutes = v),
                  mainSubjects: mainSubjects,
                  onToggleSubject: (s) => setState(() {
                    mainSubjects.contains(s)
                        ? mainSubjects.remove(s)
                        : mainSubjects.add(s);
                  }),
                ),
                _ => _StepThree(
                  prefLearning: prefLearning,
                  dailyMinutes: dailyMinutes,
                  mainSubjects: mainSubjects,
                ),
              },
            ),
            const SizedBox(height: 16),

            // Botonera inferior
            Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    text: step < 2 ? 'Continuar' : 'Crear cuenta',
                    onPressed: () {
                      if (step < 2) {
                        next();
                      } else {
                        Navigator.pushReplacementNamed(context, '/login');
                        // Solo visual: mostrar snack
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: cs.primary,
                            content: const Text('Cuenta creada'),
                          ),
                        );
                      }
                    },
                    icon: step < 2 ? Icons.arrow_forward_rounded : Icons.check,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Paso 1 – Datos básicos
class _StepOne extends StatelessWidget {
  const _StepOne({
    required this.nameCtrl,
    required this.ageCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.level,
    required this.onLevelChanged,
  });

  final TextEditingController nameCtrl;
  final TextEditingController ageCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final String level;
  final ValueChanged<String> onLevelChanged;

  @override
  Widget build(BuildContext context) {
    final levels = const ['Bachillerato', 'Universidad', 'Otro'];
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        _FieldLabel('Nombre'),
        TextField(controller: nameCtrl),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Edad'),
                  TextField(
                    controller: ageCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Nivel'),
                  _LevelDropdown(
                    value: level,
                    items: levels,
                    onChanged: onLevelChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _FieldLabel('Correo'),
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'tu@correo.com'),
        ),
        const SizedBox(height: 12),

        _FieldLabel('Contraseña'),
        TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: const InputDecoration(hintText: '••••••••'),
        ),
      ],
    );
  }
}

/// Paso 2 – Test de aprendizaje
class _StepTwo extends StatelessWidget {
  const _StepTwo({
    required this.prefLearning,
    required this.onPrefLearning,
    required this.dailyMinutes,
    required this.onDailyMinutes,
    required this.mainSubjects,
    required this.onToggleSubject,
  });

  final String? prefLearning;
  final ValueChanged<String> onPrefLearning;

  final String? dailyMinutes;
  final ValueChanged<String> onDailyMinutes;

  final Set<String> mainSubjects;
  final ValueChanged<String> onToggleSubject;

  @override
  Widget build(BuildContext context) {
    Widget chip(String text, bool selected, VoidCallback onTap) {
      return ChoiceChip(
        label: Text(text),
        selected: selected,
        onSelected: (_) => onTap(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      );
    }

    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Test de aprendizaje',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            )),
        const SizedBox(height: 6),
        Text('Ayúdanos a personalizar tus repasos',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),

        _SubHeader('¿Cómo aprendes mejor?'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            chip('Videos/visual', prefLearning == 'visual',
                    () => onPrefLearning('visual')),
            chip('Ejemplos prácticos', prefLearning == 'ejemplos',
                    () => onPrefLearning('ejemplos')),
            chip('Lecturas/conceptos', prefLearning == 'lectura',
                    () => onPrefLearning('lectura')),
          ],
        ),
        const SizedBox(height: 16),

        _SubHeader('¿Cuántos minutos al día quieres estudiar?'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            chip('10–15', dailyMinutes == '10-15',
                    () => onDailyMinutes('10-15')),
            chip('20–30', dailyMinutes == '20-30',
                    () => onDailyMinutes('20-30')),
            chip('40+', dailyMinutes == '40+', () => onDailyMinutes('40+')),
          ],
        ),
        const SizedBox(height: 16),

        _SubHeader('Materia principal de interés'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilterChip(
              label: const Text('Matemáticas'),
              selected: mainSubjects.contains('Matemáticas'),
              onSelected: (_) => onToggleSubject('Matemáticas'),
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            FilterChip(
              label: const Text('Física'),
              selected: mainSubjects.contains('Física'),
              onSelected: (_) => onToggleSubject('Física'),
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            FilterChip(
              label: const Text('Química'),
              selected: mainSubjects.contains('Química'),
              onSelected: (_) => onToggleSubject('Química'),
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ],
        ),
      ],
    );
  }
}

/// Paso 3 – Resumen
class _StepThree extends StatelessWidget {
  const _StepThree({
    required this.prefLearning,
    required this.dailyMinutes,
    required this.mainSubjects,
  });

  final String? prefLearning;
  final String? dailyMinutes;
  final Set<String> mainSubjects;

  @override
  Widget build(BuildContext context) {
    final bullets = [
      'Preferencia: ${prefLearning ?? '—'}',
      'Ritmo diario: ${dailyMinutes ?? '—'}',
      'Materia foco: ${mainSubjects.isEmpty ? '—' : mainSubjects.join(', ')}',
    ];
    return Column(
      key: const ValueKey('step3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resumen',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            )),
        const SizedBox(height: 6),
        Text('Confirma tu información',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: bullets
                  .map((b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(b)),
                  ],
                ),
              ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widgets auxiliares de estilo
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child:
      Text(text, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _SubHeader extends StatelessWidget {
  const _SubHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

class _LevelDropdown extends StatelessWidget {
  const _LevelDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(),
      items: items
          .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
