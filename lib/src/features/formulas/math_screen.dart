// lib/src/features/formulas/math_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../router.dart';
import '../../widgets/formula_math.dart';

class MathScreen extends StatefulWidget {
  const MathScreen({super.key});

  @override
  State<MathScreen> createState() => _MathScreenState();
}

class _MathScreenState extends State<MathScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------- Normalizadores (idénticos a Física) ----------fs
  Map<String, String> _asStringMap(dynamic v) {
    if (v == null) return const {};
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), val.toString()));
    }
    if (v is List) {
      final out = <String, String>{};
      for (final item in v) {
        if (item is Map) {
          final key = (item['symbol'] ?? item['key'] ?? item['name'] ?? '').toString();
          final val = (item['meaning'] ?? item['value'] ?? item['desc'] ?? item['fromText'] ?? '').toString();
          if (key.isNotEmpty) out[key] = val;
        } else {
          out[item.toString()] = '';
        }
      }
      return out;
    }
    // String: "x: Variable, n: Exponente"
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
  _MathItem _fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final title = (m['titulo'] ?? m['title'] ?? '').toString();
    final expr  = (m['latex_expresion'] ?? m['latex'] ?? m['expression'] ?? '').toString();
    final desc  = (m['explicacion'] ?? m['summary'] ?? '').toString();
    final topic = (m['tema'] ?? m['topic'] ?? '').toString();

    final vars  = _asStringMap(m['variables']);         // ✅ variables
    final conds = _asStringList(m['condiciones_uso']);  // ✅ condiciones

    return _MathItem(
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

  bool _isMath(String s) {
    final t = s.toLowerCase();
    // Soporta 'Matemáticas', 'Matematicas', 'Math', etc.
    return t.contains('matem') || t.contains('math');
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
      appBar: AppBar(title: const Text('Matemáticas')),
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
              .where((f) => _isMath(f.topic))
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
              // Buscador
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar fórmula (p.ej. “cuadrática”, “Pitágoras”, “derivada”…)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 12),

              // Resultados
              ...filtered.map((f) => Card(
                child: ListTile(
                  leading: const Icon(Icons.calculate_outlined),
                  title: Text(
                    f.name.isEmpty ? '(sin título)' : f.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    // Render LaTeX bonito
                    child: FormulaMath(f.expr, fontSize: 16),
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
                        'topic': 'Matemáticas',
                        'explanation': f.explanation,
                        'variables': f.variables,   // Map<String,String>
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

class _MathItem {
  final String id;
  final String name, expr, desc, explanation, topic;
  final Map<String, String> variables;
  final List<String> conditions;
  const _MathItem({
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