import 'package:flutter/material.dart';
import '../../common/widgets/primary_button.dart';
import '../../router.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int step = 0;

  // Paso 1 – datos básicos
  final nameCtrl = TextEditingController(text: 'Pablo');
  final ageCtrl = TextEditingController(text: '18');
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String level = 'Bachillerato';

  // Paso 2 – VARK + hábitos
  String? prefLearning;                // visual | auditiva | lectura | kinestesica (etiqueta amigable)
  String? dailyMinutes;                // 10-15 | 20-30 | 40+
  final Set<String> mainSubjects = {}; // Matemáticas, Física, Química

  // Resultado VARK a guardar
  Map<String, int>? varkCounts;        // {'V':x,'A':y,'R':z,'K':w}
  String? varkPredominant;             // 'V' | 'A' | 'R' | 'K'

  bool _loading = false;

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

  Future<void> _createAccount() async {
    final cs = Theme.of(context).colorScheme;
    final name = nameCtrl.text.trim();
    final age = int.tryParse(ageCtrl.text.trim()) ?? 0;
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa nombre, correo y contraseña.')),
      );
      return;
    }
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final uid = await AuthService.instance.signUp(
        name: name,
        email: email,
        password: pass,
        age: age,
        level: level,
        role: 'alumno',
        prefLearning: prefLearning,
        dailyMinutes: dailyMinutes,
        mainSubjects: mainSubjects.toList(),
      );

      // Guardar perfil VARK unificado si existe
      if (varkCounts != null && varkPredominant != null) {
        await AuthService.instance.saveLearningProfile(
          uid: uid,
          counts: varkCounts!,
          predominant: varkPredominant!,
          instrument: 'VARK',
          version: '1.0',
          // classId: null, // si lo necesitas en contexto de clase
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: cs.primary, content: const Text('Cuenta creada')),
      );
      Navigator.pushReplacementNamed(context, AppRouter.login);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo crear la cuenta: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget content;
    if (step == 0) {
      content = _StepOne(
        nameCtrl: nameCtrl,
        ageCtrl: ageCtrl,
        emailCtrl: emailCtrl,
        passCtrl: passCtrl,
        level: level,
        onLevelChanged: (v) => setState(() => level = v),
      );
    } else if (step == 1) {
      content = _StepTwo(
        prefLearning: prefLearning,
        onPrefLearning: (v) => setState(() => prefLearning = v),
        dailyMinutes: dailyMinutes,
        onDailyMinutes: (v) => setState(() => dailyMinutes = v),
        mainSubjects: mainSubjects,
        onToggleSubject: (s) => setState(() {
          mainSubjects.contains(s) ? mainSubjects.remove(s) : mainSubjects.add(s);
        }),
        onVarkComputed: (counts, predominant) {
          // Mapear etiqueta amigable (por si quieres mostrarla en preferencias)
          final mapToLabel = {
            'V': 'visual',
            'A': 'auditiva',
            'R': 'lectura',
            'K': 'kinestesica',
          };
          setState(() {
            varkCounts = counts;
            varkPredominant = predominant;
            prefLearning = mapToLabel[predominant];
          });
        },
      );
    } else {
      content = _StepThree(
        prefLearning: prefLearning,
        dailyMinutes: dailyMinutes,
        mainSubjects: mainSubjects,
      );
    }

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
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
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

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: content,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    if (step > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: back,
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Atrás'),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 12),
                    if (step > 0) const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        text: step < 2 ? 'Continuar' : 'Crear cuenta',
                        onPressed: () {
                          if (step < 2) {
                            next();
                          } else {
                            _createAccount();
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
            if (_loading)
              Positioned.fill(
                child: Container(
                  color: Colors.black12,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
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
        const _FieldLabel('Nombre'),
        TextField(controller: nameCtrl),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Edad'),
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
                  const _FieldLabel('Nivel'),
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
        const _FieldLabel('Correo'),
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'tu@correo.com'),
        ),
        const SizedBox(height: 12),
        const _FieldLabel('Contraseña'),
        TextField(
          controller: passCtrl,
          obscureText: true,
          decoration: const InputDecoration(hintText: '••••••••'),
        ),
      ],
    );
  }
}

/// Paso 2 – Test de aprendizaje (VARK) + hábitos
class _StepTwo extends StatefulWidget {
  const _StepTwo({
    required this.prefLearning,
    required this.onPrefLearning,
    required this.dailyMinutes,
    required this.onDailyMinutes,
    required this.mainSubjects,
    required this.onToggleSubject,
    required this.onVarkComputed,
  });

  final String? prefLearning;
  final ValueChanged<String> onPrefLearning;

  final String? dailyMinutes;
  final ValueChanged<String> onDailyMinutes;

  final Set<String> mainSubjects;
  final ValueChanged<String> onToggleSubject;

  final void Function(Map<String, int> counts, String predominant) onVarkComputed;

  @override
  State<_StepTwo> createState() => _StepTwoState();
}

class _StepTwoState extends State<_StepTwo> {
  final Map<int, String> _answers = {}; // por índice: 'V'|'A'|'R'|'K'
  String? _resultado;                   // 'V'|'A'|'R'|'K'
  Map<String, int> _counts = {'V': 0, 'A': 0, 'R': 0, 'K': 0};

  final List<Map<String, Object>> _questions = <Map<String, Object>>[
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

    setState(() {
      _resultado = top;
      _counts = Map<String, int>.from(counts);
    });

    widget.onVarkComputed(_counts, _resultado!);

    // Opcional: actualizar preferencia amigable
    final mapToLabel = {'V': 'visual', 'A': 'auditiva', 'R': 'lectura', 'K': 'kinestesica'};
    widget.onPrefLearning(mapToLabel[top]!);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
        Text('Test de aprendizaje (VARK)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Responde cómo prefieres aprender. Al final calcularemos tu perfil.',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),

        // Preguntas VARK
        ...List.generate(_questions.length, (i) {
          final q = _questions[i];
          final questionText = q['q'] as String;
          final options = q['options'] as Map<String, String>;
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
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

        if (_resultado != null) ...[
          const SizedBox(height: 16),
          _ResultCardVark(tipo: _resultado!, counts: _counts),
        ],

        const SizedBox(height: 20),

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
  const _ResultCardVark({required this.tipo, required this.counts});
  final String tipo; // 'V','A','R','K'
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final map = <String, Map<String, Object>>{
      'V': {
        'titulo': 'Visual',
        'tip': 'Usa diagramas, mapas mentales y colores; convierte ideas en imágenes.',
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
        'tip': 'Aprende haciendo; ejercicios, simulaciones y casos reales.',
        'icon': Icons.handyman_outlined,
      },
    };
    final data = map[tipo]!;
    final total =
        (counts['V'] ?? 0) + (counts['A'] ?? 0) + (counts['R'] ?? 0) + (counts['K'] ?? 0);
    double pct(String k) => total == 0 ? 0 : (counts[k] ?? 0) / total;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
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
            const SizedBox(height: 16),
            _BarVark(label: 'Visual', value: pct('V')),
            const SizedBox(height: 8),
            _BarVark(label: 'Aural', value: pct('A')),
            const SizedBox(height: 8),
            _BarVark(label: 'Lectura/Escritura', value: pct('R')),
            const SizedBox(height: 8),
            _BarVark(label: 'Kinestésico', value: pct('K')),
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
    final bullets = <String>[
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
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
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
      items: items.map((e) => DropdownMenuItem<String>(value: e, child: Text(e))).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}