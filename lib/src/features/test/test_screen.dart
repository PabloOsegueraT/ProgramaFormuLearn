import 'package:flutter/material.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});
  @override
  State<TestScreen> createState() => _TestScreenState();
}

/// FASES del flujo: configurar -> rendir -> resultados
enum _Phase { config, quiz, results }

class _TestScreenState extends State<TestScreen> {
  _Phase phase = _Phase.config;

  // ====== CONFIG ======
  final Set<String> _topics = {}; // seleccionados por el alumno
  String _difficulty = 'Intermedio'; // Fácil | Intermedio | Avanzado
  double _count = 6; // cantidad de preguntas a generar

  // ====== QUIZ (generado) ======
  late List<_Q> _quiz;
  int _current = 0;

  int get answered =>
      _quiz.where((q) => q.selectedIndex != null).length;

  int get correct =>
      _quiz.where((q) => q.isCorrect == true).length;

  double get progress =>
      _quiz.isEmpty ? 0 : (answered / _quiz.length);

  // Generador VISUAL (sin IA real): crea preguntas en base a topics/difficulty
  List<_Q> _generateQuiz({
    required List<String> topics,
    required String difficulty,
    required int count,
  }) {
    final List<_Q> out = [];
    int i = 0;
    final bank = _makeBank(topics: topics, difficulty: difficulty);
    while (out.length < count && bank.isNotEmpty) {
      out.add(bank[i % bank.length]);
      i++;
    }
    return out;
  }

  // Banco “IA” simulado por temas + dificultad
  List<_Q> _makeBank({required List<String> topics, required String difficulty}) {
    final List<_Q> bank = [];

    bool easy = difficulty == 'Fácil';
    bool hard = difficulty == 'Avanzado';

    if (topics.contains('Física')) {
      bank.addAll([
        _Q(
          topic: 'Física',
          prompt: 'En MRU, si d = 120 m y t = 20 s, ¿cuál es v?',
          options: const ['4 m/s', '6 m/s', '8 m/s', '10 m/s'],
          correctIndex: 1,
          tip: 'MRU: v = d/t = 120/20 = 6 m/s.',
        ),
        _Q(
          topic: 'Física',
          prompt: 'Segunda ley de Newton: si m=3 kg y a=2 m/s², la fuerza neta es…',
          options: const ['1.5 N', '5 N', '6 N', '8 N'],
          correctIndex: 2,
          tip: 'ΣF = m·a = 3·2 = 6 N.',
        ),
        _Q(
          topic: 'Física',
          prompt: 'Energía cinética para m=2 kg y v=3 m/s:',
          options: const ['3 J', '6 J', '8 J', '9 J'],
          correctIndex: 3,
          tip: 'K = ½·m·v² = 0.5·2·9 = 9 J.',
        ),
      ]);
    }

    if (topics.contains('Matemáticas')) {
      bank.addAll([
        _Q(
          topic: 'Matemáticas',
          prompt: 'Ecuación x² − 5x + 6 = 0; una raíz es…',
          options: const ['x=1', 'x=2', 'x=4', 'x=6'],
          correctIndex: 1,
          tip: 'Factoriza: (x−2)(x−3)=0 → x=2 o x=3.',
        ),
        _Q(
          topic: 'Matemáticas',
          prompt: 'En un triángulo rectángulo, a=3, b=4; c = ?',
          options: const ['4', '5', '6', '7'],
          correctIndex: 1,
          tip: 'Pitágoras: c²=3²+4²=25 → c=5.',
        ),
        _Q(
          topic: 'Matemáticas',
          prompt: 'd/dx (x⁵) = ?',
          options: const ['x⁴', '4x³', '5x⁴', '6x⁵'],
          correctIndex: 2,
          tip: 'Regla potencia: n·x^(n−1) → 5·x⁴.',
        ),
      ]);
    }

    if (topics.contains('Química')) {
      bank.addAll([
        _Q(
          topic: 'Química',
          prompt: 'Gas ideal: Si P=1 atm, n=1 mol, R=0.082, T=300 K, V ≈ ?',
          options: const ['12.3 L', '24.6 L', '36.9 L', '49.2 L'],
          correctIndex: 0,
          tip: 'PV=nRT → V≈(1·0.082·300)/1 ≈ 24.6 L (si usas 0.082).',
        ),
        _Q(
          topic: 'Química',
          prompt: 'Para [H⁺]=1×10⁻³ M, el pH es…',
          options: const ['1', '2', '3', '4'],
          correctIndex: 2,
          tip: 'pH=−log[H⁺]=3.',
        ),
        _Q(
          topic: 'Química',
          prompt: 'Molaridad: 0.5 mol de soluto en 2 L → M = ?',
          options: const ['0.1', '0.25', '0.5', '1.0'],
          correctIndex: 1,
          tip: 'M = n/V = 0.5/2 = 0.25 M.',
        ),
      ]);
    }

    // Ajustes por dificultad (más trampa o más directas)
    if (easy) {
      // Simplifica: pone opciones más separadas (ya están simples)
    } else if (hard) {
      // Endurecer: reordenar/parecerse más
      for (var q in bank) {
        q.options = List<String>.from(q.options)..shuffle();
        // corrige índice correcto tras shuffle
        q.correctIndex = q.options.indexOf(q.correctText);
      }
    }
    return bank;
  }

  void _startQuiz() {
    if (_topics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un tema')),
      );
      return;
    }
    final list = _generateQuiz(
      topics: _topics.toList(),
      difficulty: _difficulty,
      count: _count.round(),
    );
    setState(() {
      _quiz = list;
      _current = 0;
      phase = _Phase.quiz;
    });
  }

  void _answer(int idx) {
    setState(() {
      final q = _quiz[_current];
      q.selectedIndex = idx;
    });
  }

  void _next() {
    if (_current < _quiz.length - 1) {
      setState(() => _current++);
    } else {
      setState(() => phase = _Phase.results);
    }
  }

  void _prev() {
    if (_current > 0) setState(() => _current--);
  }

  void _resetToConfig() {
    setState(() {
      phase = _Phase.config;
      _quiz = [];
      _current = 0;
      // mantenemos la config elegida
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (phase) {
      case _Phase.config:
        return _ConfigView(
          topics: _topics,
          difficulty: _difficulty,
          count: _count,
          onToggleTopic: (t) {
            setState(() =>
            _topics.contains(t) ? _topics.remove(t) : _topics.add(t));
          },
          onDifficulty: (d) => setState(() => _difficulty = d),
          onCount: (v) => setState(() => _count = v),
          onGenerate: _startQuiz,
        );
      case _Phase.quiz:
        return _QuizView(
          quiz: _quiz,
          current: _current,
          onAnswer: _answer,
          onNext: _next,
          onPrev: _prev,
          progress: progress,
        );
      case _Phase.results:
        return _ResultsView(
          quiz: _quiz,
          onRestart: _resetToConfig,
        );
    }
  }
}

/// ======================= CONFIG VIEW =======================
class _ConfigView extends StatelessWidget {
  const _ConfigView({
    required this.topics,
    required this.difficulty,
    required this.count,
    required this.onToggleTopic,
    required this.onDifficulty,
    required this.onCount,
    required this.onGenerate,
  });

  final Set<String> topics;
  final String difficulty;
  final double count;

  final ValueChanged<String> onToggleTopic;
  final ValueChanged<String> onDifficulty;
  final ValueChanged<double> onCount;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Test dinámico')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero/explicación
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primaryContainer.withOpacity(.8), cs.surfaceVariant],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_alt_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Selecciona los temas que quieres evaluar y genera un examen automático.\n'
                        'Obtén retroalimentación inmediata. (Solo UI, sin IA real aún)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text('Temas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _topicChip('Física', topics.contains('Física'), onToggleTopic),
              _topicChip('Matemáticas', topics.contains('Matemáticas'), onToggleTopic),
              _topicChip('Química', topics.contains('Química'), onToggleTopic),
            ],
          ),
          const SizedBox(height: 16),

          Text('Dificultad',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _pill('Fácil', difficulty == 'Fácil', () => onDifficulty('Fácil')),
              _pill('Intermedio', difficulty == 'Intermedio', () => onDifficulty('Intermedio')),
              _pill('Avanzado', difficulty == 'Avanzado', () => onDifficulty('Avanzado')),
            ],
          ),
          const SizedBox(height: 16),

          Text('Número de preguntas: ${count.round()}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              )),
          Slider(
            value: count,
            min: 3,
            max: 12,
            divisions: 9,
            label: count.round().toString(),
            onChanged: onCount,
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onGenerate,
              icon: const Icon(Icons.auto_awesome),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Generar examen con IA (demo)'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicChip(String label, bool sel, ValueChanged<String> onTap) {
    return FilterChip(
      label: Text(label),
      selected: sel,
      onSelected: (_) => onTap(label),
    );
  }

  Widget _pill(String label, bool sel, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      onSelected: (_) => onTap(),
    );
  }
}

/// ======================= QUIZ VIEW =======================
class _QuizView extends StatelessWidget {
  const _QuizView({
    required this.quiz,
    required this.current,
    required this.onAnswer,
    required this.onNext,
    required this.onPrev,
    required this.progress,
  });

  final List<_Q> quiz;
  final int current;
  final void Function(int index) onAnswer;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final q = quiz[current];
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluación'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text('Progreso ${(progress * 100).round()}%'),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(value: progress, minHeight: 6),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info del item
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pregunta ${current + 1} / ${quiz.length}',
                  style: Theme.of(context).textTheme.labelLarge),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.category_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text(q.topic),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tarjeta de pregunta
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                q.prompt,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Opciones
          ...List.generate(q.options.length, (i) {
            final sel = q.selectedIndex == i;
            final isAnswered = q.selectedIndex != null;
            final isCorrect = isAnswered && i == q.correctIndex;
            final isWrongSel = isAnswered && sel && i != q.correctIndex;

            Color? tileColor;
            if (isCorrect) tileColor = Colors.green.withOpacity(.12);
            if (isWrongSel) tileColor = Colors.red.withOpacity(.12);

            return Card(
              color: tileColor,
              child: RadioListTile<int>(
                value: i,
                groupValue: q.selectedIndex,
                title: Text(q.options[i]),
                onChanged: (val) {
                  if (q.selectedIndex == null) onAnswer(i);
                },
                activeColor: cs.primary,
              ),
            );
          }),

          // Tip/retroalimentación inmediata
          if (q.selectedIndex != null) ...[
            const SizedBox(height: 10),
            _TipCard(
              correct: q.isCorrect,
              tip: q.tip,
            ),
          ],

          const SizedBox(height: 12),

          // Controles
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: current > 0 ? onPrev : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Anterior'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: q.selectedIndex != null ? onNext : null,
                  icon: Icon(current == quiz.length - 1 ? Icons.flag : Icons.arrow_forward),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(current == quiz.length - 1 ? 'Terminar' : 'Siguiente'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ======================= RESULTS VIEW =======================
class _ResultsView extends StatelessWidget {
  const _ResultsView({
    required this.quiz,
    required this.onRestart,
  });

  final List<_Q> quiz;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = quiz.length;
    final correct = quiz.where((q) => q.isCorrect).length;
    final wrong = total - correct;
    final score = (correct / total);

    String badge() {
      if (score >= .9) return 'Excelente';
      if (score >= .75) return 'Muy bien';
      if (score >= .6) return 'Bien';
      return 'Repasar';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Resultados')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.assessment_outlined, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tu puntaje: ${(score * 100).round()}%',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text('Correctas: $correct   ·   Incorrectas: $wrong'),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.tertiaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(badge()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // “Guardado” (visual)
          _SectionTitle('Guardado y visibilidad (demo)'),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tus resultados se han guardado (solo demostración UI).',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Visibles para el profesor en su panel de clase (demo).'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.cloud_done_outlined, size: 18),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text('Sincronizados con tu portafolio de aprendizaje (visual).'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Listado de preguntas con estado
          _SectionTitle('Detalle de respuestas'),
          ...quiz.map((q) {
            return Card(
              child: ListTile(
                leading: Icon(q.isCorrect ? Icons.check_circle : Icons.cancel,
                    color: q.isCorrect ? Colors.green : Colors.red),
                title: Text(q.prompt),
                subtitle: Text('Respuesta correcta: ${q.correctText}'),
              ),
            );
          }).toList(),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.refresh),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Nuevo test'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Resultados “guardados” (demo)')),
                    );
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Guardar resultados (demo)'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ======================= MODELOS & WIDGETS =======================
class _Q {
  _Q({
    required this.topic,
    required this.prompt,
    required List<String> options,
    required this.correctIndex,
    required this.tip,
  })  : options = List<String>.from(options),
        correctText = options[correctIndex];

  final String topic;
  final String prompt;
  late List<String> options;
  int correctIndex;
  String correctText;

  final String tip;

  int? selectedIndex;

  bool get isCorrect => selectedIndex == correctIndex;
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.correct, required this.tip});
  final bool correct;
  final String tip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (correct ? Colors.green : cs.error).withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (correct ? Colors.green : cs.error).withOpacity(.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(correct ? Icons.check_circle : Icons.error_outline,
              color: correct ? Colors.green : cs.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              correct
                  ? '¡Correcto! $tip'
                  : 'Respuesta incorrecta. $tip',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style:
      Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}
