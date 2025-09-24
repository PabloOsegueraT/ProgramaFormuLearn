import 'package:flutter/material.dart';

class StudentClassesScreen extends StatefulWidget {
  const StudentClassesScreen({super.key});

  @override
  State<StudentClassesScreen> createState() => _StudentClassesScreenState();
}

class _StudentClassesScreenState extends State<StudentClassesScreen> {
  final _codeCtrl = TextEditingController();

  // Lista visual de clases del alumno
  final List<_StudentClass> _myClasses = [
    _StudentClass(title: 'Física — 3°B', code: 'FIS-3B-4821'),
    _StudentClass(title: 'Matemáticas — 2°A', code: 'MAT-2A-8342'),
  ];

  // Lista visual “explorable” (para el buscador demo)
  final List<_StudentClass> _catalog = [
    _StudentClass(title: 'Química — 1°C', code: 'QUI-1C-9901'),
    _StudentClass(title: 'Biología — 1°A', code: 'BIO-1A-7712'),
    _StudentClass(title: 'Historia — 2°B', code: 'HIS-2B-5520'),
  ];

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _joinByCode() {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un código de clase')),
      );
      return;
    }

    // Solo visual: si ya existe en mis clases, avisamos
    final exists = _myClasses.any((c) => c.code == code);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ya estás en la clase ($code)')),
      );
      return;
    }

    // Visual: crear una tarjeta “genérica” a partir del código
    setState(() {
      _myClasses.insert(
        0,
        _StudentClass(title: 'Clase unida ($code)', code: code),
      );
      _codeCtrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Te uniste a la clase ($code)')),
    );
  }

  void _openSearch() async {
    final result = await showSearch<_StudentClass?>(
      context: context,
      delegate: _ClassSearchDelegate(_catalog),
    );
    if (result != null) {
      // Visual: al “unir” desde búsqueda, agrega a mis clases si no estaba
      final exists = _myClasses.any((c) => c.code == result.code);
      if (!exists) {
        setState(() => _myClasses.insert(0, result));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Te uniste a ${result.title}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esa clase ya está en tu lista')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clases'),
        actions: [
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Unirse por código
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Unirse a una clase',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Código de clase',
                    hintText: 'p.ej. FIS-3B-4821',
                    prefixIcon: const Icon(Icons.vpn_key),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.login_rounded),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Unirse'),
                    ),
                    onPressed: _joinByCode,
                  ),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 16),

          // Mis clases (con botón buscar también arriba)
          Row(
            children: [
              Expanded(
                child: Text('Mis clases',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700)),
              ),
              TextButton.icon(
                onPressed: _openSearch,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_myClasses.isEmpty)
            _EmptyState(
              title: 'Aún no te has unido a ninguna clase',
              subtitle: 'Ingresa un código o utiliza el buscador para encontrar clases.',
            )
          else
            ..._myClasses.map((c) => _ClassCard(item: c)).toList(),
        ],
      ),
    );
  }
}

/// ----------------- MODELO Y WIDGETS DE APOYO -----------------

class _StudentClass {
  final String title;
  final String code;
  _StudentClass({required this.title, required this.code});
}

class _ClassCard extends StatelessWidget {
  final _StudentClass item;
  const _ClassCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.class_outlined),
        ),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('Código: ${item.code}'),
        trailing: IconButton(
          tooltip: 'Más (visual)',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Acciones de clase (demo)')),
            );
          },
          icon: const Icon(Icons.more_horiz),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Abriendo "${item.title}" (demo)')),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.class_outlined, size: 42),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// ----------------- BUSCADOR VISUAL -----------------

class _ClassSearchDelegate extends SearchDelegate<_StudentClass?> {
  final List<_StudentClass> catalog;
  _ClassSearchDelegate(this.catalog);

  @override
  String? get searchFieldLabel => 'Buscar clases (demo)';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(onPressed: () => close(context, null), icon: const Icon(Icons.arrow_back));
  }

  @override
  Widget buildResults(BuildContext context) {
    final q = query.trim().toLowerCase();
    final results = catalog.where((c) =>
    c.title.toLowerCase().contains(q) || c.code.toLowerCase().contains(q)).toList();

    if (results.isEmpty) {
      return const Center(child: Text('Sin resultados'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final c = results[i];
        return ListTile(
          leading: const Icon(Icons.class_),
          title: Text(c.title),
          subtitle: Text(c.code),
          trailing: FilledButton(
            onPressed: () => close(context, c), // devolver clase seleccionada
            child: const Text('Unirme'),
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: catalog.take(5).map((c) => ListTile(
          leading: const Icon(Icons.class_outlined),
          title: Text(c.title),
          subtitle: Text(c.code),
          onTap: () => query = c.title,
        )).toList(),
      );
    }
    return buildResults(context);
  }
}
