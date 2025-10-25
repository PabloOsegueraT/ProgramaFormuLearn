import 'package:flutter/material.dart';
import '../../router.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  bool showOnlyFavorites = false;

  // Datos demo (visual)
  final List<_PortfolioItem> items = [
    _PortfolioItem(title: 'MRU', views: 3, isFavorite: false),
    _PortfolioItem(title: 'Ley de Ohm', views: 5, isFavorite: true),
    _PortfolioItem(title: 'Ecuación cuadrática', views: 1, isFavorite: false),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = showOnlyFavorites
        ? items.where((e) => e.isFavorite).toList()
        : items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portafolio'),
        actions: [
          IconButton(
            tooltip: showOnlyFavorites ? 'Ver todos' : 'Solo favoritos',
            icon: Icon(
              showOnlyFavorites ? Icons.star : Icons.star_border,
            ),
            onPressed: () {
              setState(() => showOnlyFavorites = !showOnlyFavorites);
            },
          ),
        ],
      ),
      body: filtered.isEmpty
          ? _EmptyFavorites(
        showingOnlyFavs: showOnlyFavorites,
        onShowAll: () => setState(() => showOnlyFavorites = false),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final item = filtered[i];
          return _PortfolioCard(
            item: item,
            onToggleFavorite: () {
              setState(() => item.isFavorite = !item.isFavorite);
            },
            onOpen: () {
              setState(() => item.views++); // demo: suma una visita
              // Visual: si quieres abrir detalle real, descomenta:
              // Navigator.pushNamed(context, AppRouter.formulaDetail, arguments: {
              //   'title': item.title,
              //   'expression': '',
              //   'summary': 'Detalle de ${item.title} (demo visual).',
              //   'topic': 'Portafolio',
              // });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Abriendo "${item.title}" (demo)')),
              );
            },
          );
        },
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final _PortfolioItem item;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpen;

  const _PortfolioCard({
    required this.item,
    required this.onToggleFavorite,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final usage = _usageLabel(item.views);

    return Card(
      elevation: 0,
      child: ListTile(
        leading: const Icon(Icons.folder, size: 28),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(usage),
        trailing: IconButton(
          tooltip: item.isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
          icon: Icon(
            item.isFavorite ? Icons.star : Icons.star_border,
            color: item.isFavorite ? Colors.amber[700] : null,
          ),
          onPressed: onToggleFavorite,
        ),
        onTap: onOpen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  final bool showingOnlyFavs;
  final VoidCallback onShowAll;
  const _EmptyFavorites({
    required this.showingOnlyFavs,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    if (!showingOnlyFavs) {
      return const Center(
        child: Text('Aún no hay elementos en tu portafolio.'),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_border, size: 48),
            const SizedBox(height: 10),
            const Text('No tienes favoritos todavía'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: onShowAll,
              child: const Text('Ver todos'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ----------------- Modelo y helpers (visual) -----------------

class _PortfolioItem {
  final String title;
  int views;
  bool isFavorite;
  _PortfolioItem({
    required this.title,
    required this.views,
    this.isFavorite = false,
  });
}

/// Mensaje profesional en función del número de consultas
String _usageLabel(int views) {
  if (views <= 0) return 'Sin consultas aún';
  if (views == 1) return 'Consultado 1 vez';
  if (views <= 4) return 'Consultado $views veces';
  if (views <= 9) return 'Visitado frecuentemente';
  return 'Visitado constantemente';
}
