// lib/src/features/formulas/chemistry_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../router.dart';
import '../../widgets/formula_math.dart';

class ChemistryScreen extends StatefulWidget {
  const ChemistryScreen({super.key});

  @override
  State<ChemistryScreen> createState() => _ChemistryScreenState();
}

class _ChemistryScreenState extends State<ChemistryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------- Normalizadores ----------
  Map<String, String> _asStringMap(dynamic v) {
    if (v == null) return const {};
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), val.toString()));
    }
    if (v is List) {
      final out = <String, String>{};
      for (final item in v) {
        if (item is Map) {
          final key = (item['symbol'] ?? item['key'] ?? item['name'] ?? '')
              .toString();
          final val = (item['meaning'] ??
              item['value'] ??
              item['desc'] ??
              item['fromText'] ??
              '')
              .toString();
          if (key.isNotEmpty) out[key] = val;
        } else {
          out[item.toString()] = '';
        }
      }
      return out;
    }
    // String: "pH: índice de acidez, [H+]: concentración"
    final out = <String, String>{};
    for (final part in v.toString().split(RegExp(r'[,\n]+'))) {
      final kv = part.split(':');
      if (kv.isEmpty) continue;
      final k = kv.first.trim();
      final val = kv.length > 1 ? kv.sublist(1).join(':').trim() : '';
      if (k.isNotEmpty) out[k] = val;
    }
    return out;
  }

  List<String> _asStringList(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      return v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    final s = v.toString().trim();
    if (s.isEmpty) return const [];
    final parts = s
        .split(RegExp(r'[\n•]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.isEmpty ? <String>[s] : parts;
  }

  /// Doc → modelo UI
  _Chem _fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data() ?? {};
    final title = (data['titulo'] ?? data['title'] ?? '').toString();
    final expr  = (data['latex_expresion'] ?? data['latex'] ?? data['expression'] ?? '').toString();
    final desc  = (data['explicacion'] ?? data['summary'] ?? '').toString();
    final topic = (data['tema'] ?? data['topic'] ?? '').toString();

    final vars  = _asStringMap(data['variables']);         // ✅ variables
    final conds = _asStringList(data['condiciones_uso']);  // ✅ condiciones

    return _Chem(
      id: d.id,
      name: title,
      expr: expr,
      desc: desc,
      explanation: desc,
      topic: topic,
      variables: vars,
      conditions: conds,
    );
  }

  bool _isChemistry(String s) {
    final t = s.toLowerCase();
    return t.contains('química') || t.contains('quimica');
  }

  @override
  Widget build(BuildContext context) {
    final queryRef = FirebaseFirestore.instance
        .collection('formulas')
        .where('estado', isEqualTo: 'activa')
        .withConverter<Map<String, dynamic>>(
      fromFirestore: (snap, _) => snap.data() ?? {},
      toFirestore: (map, _) => map,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Química')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: queryRef.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error al cargar: ${snap.error}'),
              ),
            );
          }

          final all = (snap.data?.docs ?? [])
              .map(_fromDoc)
              .where((f) => _isChemistry(f.topic))
              .toList();

          final filtered = all.where((f) {
            if (_query.isEmpty) return true;
            final q = _query.toLowerCase();
            return f.name.toLowerCase().contains(q) ||
                f.expr.toLowerCase().contains(q) ||
                f.desc.toLowerCase().contains(q);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar fórmula (p.ej. “pH”, “gases”, “molaridad”…)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 12),

              ...filtered.map((f) => Card(
                child: ListTile(
                  leading: const Icon(Icons.science_outlined),
                  title: Text(
                    f.name.isEmpty ? '(sin título)' : f.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: FormulaMath(f.expr, fontSize: 16), // ✅ LaTeX bonito
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRouter.formulaDetail,
                      arguments: {
                        'title': f.name,
                        'expression': f.expr,
                        'summary': f.desc,
                        'topic': 'Química',
                        'explanation': f.explanation,
                        'variables': f.variables,   // Map<String, String>
                        'conditions': f.conditions, // List<String>
                      },
                    );
                  },
                ),
              )),

              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(child: Text('Sin resultados para tu búsqueda.')),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Chem {
  final String id;
  final String name, expr, desc, explanation, topic;
  final Map<String, String> variables;
  final List<String> conditions;
  const _Chem({
    required this.id,
    required this.name,
    required this.expr,
    required this.desc,
    required this.explanation,
    required this.topic,
    required this.variables,
    required this.conditions,
  });
}