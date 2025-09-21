import 'package:flutter/material.dart';
import '../../router.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  final pages = const [
    _HomeTab(),
    _ExploreTab(),
    _RepsTab(),
    _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final titles = ['Inicio', 'Explorar', 'Repasos', 'Perfil'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Repasos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}



class _FormHero extends StatelessWidget {
  final VoidCallback onExploreAll;
  const _FormHero({required this.onExploreAll});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer.withOpacity(.8), cs.surfaceVariant],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(blurRadius: 24, color: Colors.black12, offset: Offset(0, 10))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Animación
          Positioned.fill(
            child: Lottie.asset('assets/lottie/form.json', fit: BoxFit.cover, repeat: true),
          ),
          // Overlay “glass”
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(.25), Colors.white.withOpacity(.05)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Texto + CTA
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('FormuLearn', style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                    ],
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


/// ================== HOME TAB ==================
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final card = (
        IconData icon,
        String title,
        String subtitle,
        VoidCallback onTap,
        ) =>
        Card(
          child: ListTile(
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onTap,
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        SizedBox(
          height: 350,
          child: _FormHero(
            // acción del botón “Explorar todo” (elige a dónde quieres ir)
            onExploreAll: () => Navigator.pushNamed(context, AppRouter.formulas),
          ),
        ),
        const SizedBox(height: 16),
        card(
          Icons.functions,
          'Libro de fórmulas',
          'Buscar por materia, sección y tema',
              () => Navigator.pushNamed(context, AppRouter.formulas),
        ),
        card(
          Icons.psychology,
          'Módulo de IA',
          'Resolver problemas y generar gráficas',
              () => Navigator.pushNamed(context, AppRouter.ia),
        ),
        card(
          Icons.timeline,
          'Métricas y progreso',
          'Tu avance y recomendaciones',
              () => Navigator.pushNamed(context, AppRouter.metrics),
        ),
        card(
          Icons.folder_open,
          'Portafolio',
          'Historial y favoritos',
              () => Navigator.pushNamed(context, AppRouter.portfolio),
        ),
      ],
    );
  }
}

/// ================== EXPLORE TAB ==================
class _ExploreTab extends StatelessWidget {
  const _ExploreTab();

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _ExploreTile(
        'Fórmulas',
        'Explora el catálogo',
        Icons.functions,
            () => Navigator.pushNamed(context, AppRouter.formulas),
      ),
      _ExploreTile(
        'Buscar',
        'Encuentra rápidamente',
        Icons.search,
            () => Navigator.pushNamed(context, AppRouter.search),
      ),
      _ExploreTile(
        'IA',
        'Problemas y gráficas',
        Icons.psychology,
            () => Navigator.pushNamed(context, AppRouter.ia),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: tiles,
    );
  }
}

class _ExploreTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ExploreTile(this.title, this.subtitle, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 36),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(subtitle, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ================== REPS TAB ==================
class _RepsTab extends StatelessWidget {
  const _RepsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.style),
            title: const Text('Repasos inteligentes'),
            subtitle: const Text('Tarjetas tipo Anki por dificultad'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, AppRouter.reps),
          ),
        ),
      ],
    );
  }
}

/// ================== PROFILE TAB ==================
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const CircleAvatar(
          radius: 40,
          child: Icon(Icons.person, size: 40),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Pablo Oseguera',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 20),

        // Tarjetas de opciones
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.badge),
                title: const Text('Ver perfil'),
                onTap: () => Navigator.pushNamed(context, AppRouter.profile),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Privacidad y seguridad'),
                onTap: () => Navigator.pushNamed(context, AppRouter.settings),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Botón de salir
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.exit_to_app),
            label: const Text(
              'Salir',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('¿Cerrar sesión?'),
                  content:
                  const Text('¿Estás seguro que deseas salir de tu cuenta?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Salir'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.login,
                      (route) => false,
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
