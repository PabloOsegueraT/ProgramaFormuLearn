import 'package:flutter/material.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});
  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen>
    with SingleTickerProviderStateMixin {
  // Baraja demo (pregunta/respuesta)
  final List<_CardItem> deck = const [
    _CardItem(
      front: '¿Qué es MRU?',
      back: 'Movimiento Rectilíneo Uniforme: v = d / t (velocidad constante).',
    ),
    _CardItem(
      front: 'Ley de Ohm',
      back: 'Relación entre voltaje, corriente y resistencia: V = I·R.',
    ),
    _CardItem(
      front: 'Ecuación cuadrática',
      back: 'x = (-b ± √(b²–4ac)) / (2a).',
    ),
    _CardItem(
      front: 'Gas ideal',
      back: 'Ecuación de estado: P·V = n·R·T.',
    ),
    _CardItem(
      front: 'pH',
      back: 'pH = –log₁₀[H⁺].',
    ),
  ];

  int index = 0;
  bool isBack = false; // ¿se está mostrando el reverso?

  // Estadística visual (solo UI)
  int known = 0;
  int unknown = 0;

  double get progress => (index + 1) / deck.length;

  void flip() => setState(() => isBack = !isBack);

  void next({required bool knewIt}) {
    setState(() {
      if (knewIt) {
        known++;
      } else {
        unknown++;
      }
      isBack = false;
      if (index < deck.length - 1) {
        index++;
      } else {
        // fin del mazo -> snackbar demo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Mazo terminado (demo visual)!')),
        );
      }
    });
  }

  void prev() {
    if (index == 0) return;
    setState(() {
      index--;
      isBack = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = deck[index];

    return Scaffold(
      appBar: AppBar(title: const Text('Test inicial')),
      body: Column(
        children: [
          // Progreso
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: progress, minHeight: 6),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tarjeta ${index + 1} / ${deck.length}'),
                    Row(
                      children: [
                        _StatDot(color: cs.primary, label: 'Sé', value: known),
                        const SizedBox(width: 10),
                        _StatDot(color: cs.error, label: 'No sé', value: unknown),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),

          // Tarjeta (Anki-like)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _FlipCard(
                isBack: isBack,
                frontChild: _CardFace(
                  title: 'Pregunta',
                  content: card.front,
                  icon: Icons.help_outline,
                ),
                backChild: _CardFace(
                  title: 'Respuesta',
                  content: card.back,
                  icon: Icons.lightbulb_outline,
                ),
                onTap: flip,
              ),
            ),
          ),

          // Controles
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Anterior
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: index > 0 ? prev : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Anterior'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Mostrar / Marcar
                Expanded(
                  child: isBack
                      ? Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.error,
                            foregroundColor: cs.onError,
                            padding:
                            const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => next(knewIt: false),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('No la sé'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            padding:
                            const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => next(knewIt: true),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('La sé'),
                        ),
                      ),
                    ],
                  )
                      : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: flip,
                    icon: const Icon(Icons.flip),
                    label: const Text('Mostrar respuesta'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ------- UI helpers -------

class _CardItem {
  final String front;
  final String back;
  const _CardItem({required this.front, required this.back});
}

class _CardFace extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  const _CardFace({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: cs.outline.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.all(18),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: cs.primary),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              content,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _FlipCard extends StatelessWidget {
  final bool isBack;
  final Widget frontChild;
  final Widget backChild;
  final VoidCallback onTap;

  const _FlipCard({
    required this.isBack,
    required this.frontChild,
    required this.backChild,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Flip sencillo con AnimatedSwitcher (visual)
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) {
          final rotate = Tween(begin: 1.0, end: 0.0).animate(anim);
          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (context, child) {
              final angle = rotate.value * 3.1416; // radianes aprox.
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
        child: isBack
            ? SizedBox(key: const ValueKey('back'), child: backChild)
            : SizedBox(key: const ValueKey('front'), child: frontChild),
      ),
    );
  }
}

class _StatDot extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  const _StatDot({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: $value'),
      ],
    );
  }
}
