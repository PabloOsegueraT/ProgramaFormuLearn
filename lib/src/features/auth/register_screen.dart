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

/// Paso 2 – Test de aprendizaje VARK (completo) + minutos y materia
class _StepTwo extends StatefulWidget {
  const _StepTwo({
    required this.prefLearning,
    required this.onPrefLearning,
    required this.dailyMinutes,
    required this.onDailyMinutes,
    required this.mainSubjects,
    required this.onToggleSubject,
  });

  final String? prefLearning; // 'visual' | 'ejemplos' | 'lectura'
  final ValueChanged<String> onPrefLearning;

  final String? dailyMinutes; // '10-15' | '20-30' | '40+'
  final ValueChanged<String> onDailyMinutes;

  final Set<String> mainSubjects; // {'Matemáticas', 'Física', 'Química'}
  final ValueChanged<String> onToggleSubject;

  @override
  State<_StepTwo> createState() => _StepTwoState();
}

class _StepTwoState extends State<_StepTwo> {
  // Respuestas del VARK: por índice guardo 'V' | 'A' | 'R' | 'K'
  final Map<int, String> _answers = {};
  String? _resultado; // 'V' | 'A' | 'R' | 'K'

  // Preguntas (tipadas correctamente para evitar Object)
  final List<Map<String, Object>> _questions = [
    {
      'q': 'Cuando aprendes un tema nuevo, prefieres…',
      'options': <String, String>{
        'Ver esquemas o diagramas': 'V',
        'Escuchar explicaciones': 'A',
        'Leer un texto o manual': 'R',
        'Probarlo con un ejemplo': 'K',
      }
    },
    {
      'q': 'Si te pierdes en una ciudad, eliges…',
      'options': <String, String>{
        'Usar un mapa': 'V',
        'Preguntar a alguien': 'A',
        'Leer indicaciones/señales': 'R',
        'Explorar caminando': 'K',
      }
    },
    {
      'q': 'Para recordar una fórmula, prefieres…',
      'options': <String, String>{
        'Verla en un gráfico': 'V',
        'Repetirla en voz alta': 'A',
        'Escribirla en tus notas': 'R',
        'Aplicarla en ejercicios': 'K',
      }
    },
    {
      'q': 'Estudiando para un examen te sirve más…',
      'options': <String, String>{
        'Mapas conceptuales/diagramas': 'V',
        'Explicarlo con alguien': 'A',
        'Resumir y releer apuntes': 'R',
        'Resolver problemas prácticos': 'K',
      }
    },
    {
      'q': 'Si alguien explica un aparato…',
      'options': <String, String>{
        'Ver un esquema de piezas': 'V',
        'Escuchar los pasos': 'A',
        'Leer el manual': 'R',
        'Tocarlo y probarlo': 'K',
      }
    },
    {
      'q': 'En un curso online te atrae más…',
      'options': <String, String>{
        'Gráficos y presentaciones': 'V',
        'Audios o videos explicativos': 'A',
        'Textos descargables': 'R',
        'Ejercicios interactivos': 'K',
      }
    },
    {
      'q': 'Para entender una receta…',
      'options': <String, String>{
        'Ver imágenes de los pasos': 'V',
        'Que alguien te la cuente': 'A',
        'Leer los pasos escritos': 'R',
        'Hacerla tú mismo/a': 'K',
      }
    },
    {
      'q': 'Aprendiendo software nuevo…',
      'options': <String, String>{
        'Ver capturas/diagramas': 'V',
        'Escuchar a alguien explicarlo': 'A',
        'Leer tutorial escrito': 'R',
        'Explorar probando botones': 'K',
      }
    },
  ];

  void _calcularResultado() {
    final counts = {'V': 0, 'A': 0, 'R': 0, 'K': 0};
    for (final v in _answers.values) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
    String top = 'V';
    counts.forEach((k, v) {
      if (v > (counts[top] ?? 0)) top = k;
    });

    setState(() => _resultado = top);

    // Mapeo al estado del padre (tu variable prefLearning)
    // V -> 'visual', A -> 'ejemplos' (oral/explicar), R -> 'lectura', K -> 'ejemplos'
    // (Puedes ajustar esta traducción si prefieres otras etiquetas)
    final mapToParent = {
      'V': 'visual',
      'A': 'ejemplos',
      'R': 'lectura',
      'K': 'ejemplos',
    };
    widget.onPrefLearning(mapToParent[top]!);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Helpers UI locales para mantener tu API intacta
    Widget choice(String label, bool sel, VoidCallback onTap, IconData icon) {
      return ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Flexible(child: Text(label)),
          ],
        ),
        selected: sel,
        onSelected: (_) => onTap(),
        selectedColor: cs.primaryContainer,
        labelStyle: TextStyle(fontWeight: sel ? FontWeight.w700 : FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      );
    }

    Widget filt(String label, bool sel, VoidCallback onTap, IconData icon) {
      return FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: sel,
        onSelected: (_) => onTap(),
        selectedColor: cs.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      );
    }

    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER
        Text('Test de aprendizaje (VARK)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            )),
        const SizedBox(height: 6),
        Text('Responde cómo prefieres aprender. Al final calcularemos tu perfil.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),

        // VARK QUESTIONS
        ...List.generate(_questions.length, (i) {
          final q = _questions[i];
          final String questionText = q['q'] as String;
          final Map<String, String> options =
          q['options'] as Map<String, String>;
          final selected = _answers[i];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(questionText,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...options.entries.map((e) {
                    final sel = selected == e.value;
                    return RadioListTile<String>(
                      title: Text(e.key),
                      value: e.value,
                      groupValue: selected,
                      activeColor: cs.primary,
                      onChanged: (val) => setState(() => _answers[i] = val!),
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 8),
        Center(
          child: FilledButton.icon(
            onPressed: _answers.length == _questions.length ? _calcularResultado : null,
            icon: const Icon(Icons.check_circle),
            label: const Text('Calcular resultado'),
          ),
        ),

        // RESULTADO VARK
        if (_resultado != null) ...[
          const SizedBox(height: 16),
          _ResultCardVark(tipo: _resultado!),
        ],

        const SizedBox(height: 20),

        // MINUTOS DIARIOS (conservado para tu paso 3)
        Text('¿Cuántos minutos al día quieres estudiar?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                choice('10–15', widget.dailyMinutes == '10-15',
                        () => widget.onDailyMinutes('10-15'), Icons.timer_outlined),
                choice('20–30', widget.dailyMinutes == '20-30',
                        () => widget.onDailyMinutes('20-30'), Icons.schedule_outlined),
                choice('40+', widget.dailyMinutes == '40+',
                        () => widget.onDailyMinutes('40+'), Icons.av_timer_outlined),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // MATERIA PRINCIPAL (conservado para tu paso 3)
        Text('Materia principal de interés',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                filt('Matemáticas', widget.mainSubjects.contains('Matemáticas'),
                        () => widget.onToggleSubject('Matemáticas'), Icons.calculate_outlined),
                filt('Física', widget.mainSubjects.contains('Física'),
                        () => widget.onToggleSubject('Física'), Icons.science_outlined),
                filt('Química', widget.mainSubjects.contains('Química'),
                        () => widget.onToggleSubject('Química'), Icons.bubble_chart_outlined),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultCardVark extends StatelessWidget {
  const _ResultCardVark({required this.tipo}); // 'V' 'A' 'R' 'K'
  final String tipo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final map = {
      'V': {
        'titulo': 'Visual',
        'tip': 'Usa diagramas, mapas mentales, colores y esquemas; convierte ideas en imágenes.',
        'icon': Icons.insights_outlined,
      },
      'A': {
        'titulo': 'Aural',
        'tip': 'Explica en voz alta, escucha resúmenes, debate y usa grabaciones.',
        'icon': Icons.record_voice_over_outlined,
      },
      'R': {
        'titulo': 'Lectura/Escritura',
        'tip': 'Haz resúmenes y glosarios; reescribe con tus palabras y usa listas.',
        'icon': Icons.menu_book_outlined,
      },
      'K': {
        'titulo': 'Kinestésico',
        'tip': 'Aprende haciendo; ejercicios, simulaciones, laboratorios y casos reales.',
        'icon': Icons.handyman_outlined,
      },
    };
    final data = map[tipo]!;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(data['icon'] as IconData, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tu estilo predominante: ${data['titulo']}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 6),
                  Text(data['tip'] as String),
                  const SizedBox(height: 8),
                  Text(
                    'Nota: Es una preferencia, no una etiqueta fija. Combina estrategias según el contenido.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarVark extends StatelessWidget {
  const _BarVark({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label — ${(value * 100).round()}%'),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(value: value, minHeight: 8),
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
