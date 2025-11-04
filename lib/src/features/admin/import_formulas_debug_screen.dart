// lib/src/features/admin/import_formulas_debug_screen.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class ImportFormulasDebugScreen extends StatefulWidget {
  const ImportFormulasDebugScreen({super.key});

  @override
  State<ImportFormulasDebugScreen> createState() =>
      _ImportFormulasDebugScreenState();
}

class _ImportFormulasDebugScreenState extends State<ImportFormulasDebugScreen> {
  final _ctrl = TextEditingController();
  final _jsonFocus = FocusNode();

  String _status = 'Pega aquí tu JSON y pulsa "Validar + Subir".';

  @override
  void dispose() {
    _ctrl.dispose();
    _jsonFocus.dispose();
    super.dispose();
  }

  // -------- Normalizador robusto de variables --------
  Map<String, String> _normVarsPlus(dynamic raw) {
    // Admite: Map, List<Map>, String (con :, -, •), y alias
    dynamic v = raw;
    if (v == null) return const {};

    // Si te mandan el campo con otro nombre, prueba alias
    if (v is Map && v.isEmpty) return const {};
    if (v is! Map && v is! List && v is! String) return const {};

    // Si llega string, parsea "v: Velocidad (m/s), d: Distancia (m)"
    Map<String, String> fromString(String s) {
      final out = <String, String>{};
      final cleaned = s.replaceAll('•', '\n');
      for (final part in cleaned.split(RegExp(r'[\n,]+'))) {
        final p = part.trim();
        if (p.isEmpty) continue;

        // soporta "v: Velocidad..." o "v - Velocidad..."
        final sep = p.contains(':') ? ':' : (p.contains('-') ? '-' : null);
        if (sep == null) {
          out[p] = '';
          continue;
        }
        final idx = p.indexOf(sep);
        final key = p.substring(0, idx).trim();
        final val = p.substring(idx + 1).trim();
        if (key.isNotEmpty) out[key] = val;
      }
      return out;
    }

    // Aplana valores del estilo {"v":{"label":"Velocidad","unit":"m/s"}}
    String _flattenVal(dynamic val) {
      if (val is Map) {
        final label = (val['label'] ?? val['value'] ?? val['desc'] ?? val['text'] ?? '').toString().trim();
        final unit  = (val['unit'] ?? val['units'] ?? '').toString().trim();
        if (label.isEmpty && unit.isEmpty) return val.toString();
        return unit.isEmpty ? label : '$label ($unit)';
      }
      return val?.toString() ?? '';
    }

    if (v is String) return fromString(v);

    if (v is Map) {
      final out = <String, String>{};
      v.forEach((k, val) {
        final key = k.toString().trim();
        final flat = _flattenVal(val);
        if (key.isNotEmpty) out[key] = flat;
      });
      return out;
    }

    if (v is List) {
      final out = <String, String>{};
      for (final it in v) {
        if (it is Map) {
          final key = (it['symbol'] ?? it['key'] ?? it['name'] ?? '').toString().trim();
          final val = _flattenVal(it['meaning'] ?? it['value'] ?? it['desc'] ?? it['fromText'] ?? it['label']);
          if (key.isNotEmpty) out[key] = val;
        } else {
          out[it.toString()] = '';
        }
      }
      return out;
    }

    return const {};
  }

  // Lee variables desde varias claves posibles
  Map<String, String> _extractVariables(Map item) {
    final candidates = [
      item['variables'],
      item['vars'],
      item['variables_map'],
      item['variablesText'],
    ];
    for (final c in candidates) {
      final m = _normVarsPlus(c);
      if (m.isNotEmpty) return m;
      // si estaba presente pero vacío, aún así devuélvelo vacío
      if (c != null) return m;
    }
    return const {};
  }

  // ---- Barra sobre el teclado (keyboard_actions) ----
  KeyboardActionsConfig _kConfig(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return KeyboardActionsConfig(
      nextFocus: false,
      keyboardBarColor: cs.surface,
      actions: [
        KeyboardActionsItem(
          focusNode: _jsonFocus,
          displayArrows: false,
          toolbarButtons: [
                (node) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FilledButton.icon(
                icon: const Icon(Icons.keyboard_hide),
                label: const Text('Ocultar'),
                onPressed: () => node.unfocus(),
              ),
            ),
                (node) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Validar'),
                onPressed: () async {
                  node.unfocus();
                  await _import();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _import() async {
    if (!kDebugMode) {
      setState(() => _status = 'Esta pantalla solo funciona en DEBUG.');
      return;
    }

    final raw = _ctrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _status = 'El área está vacía.');
      return;
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (e) {
      setState(() => _status = 'JSON inválido: $e');
      return;
    }

    final List<dynamic> list = decoded is List ? decoded : [decoded];

    int ok = 0, fail = 0;
    final batch = FirebaseFirestore.instance.batch();
    final col = FirebaseFirestore.instance.collection('formulas');

    for (final item in list) {
      try {
        if (item is! Map) { fail++; continue; }

        String titulo = (item['titulo'] ?? item['title'] ?? '').toString().trim();
        String latex  = (item['latex_expresion'] ?? item['latex'] ?? item['expression'] ?? '').toString().trim();
        String explic = (item['explicacion'] ?? item['summary'] ?? '').toString().trim();
        String tema   = (item['tema'] ?? item['topic'] ?? '').toString().trim();
        String estado = (item['estado'] ?? 'activa').toString().trim();

        if (titulo.isEmpty || latex.isEmpty || explic.isEmpty) { fail++; continue; }

        // Normaliza tema básico (para filtros)
        final t = tema.toLowerCase().trim();
        if (t == 'fisica' || t == 'física') tema = 'Física';
        if (t == 'matematicas' || t == 'matemáticas') tema = 'Matemáticas';
        if (t == 'quimica' || t == 'química') tema = 'Química';

        // condiciones_uso: admite string o lista; lo guardamos como string con viñetas
        String condicionesUso = '';
        final cu = item['condiciones_uso'];
        if (cu is String) {
          condicionesUso = cu;
        } else if (cu is List) {
          condicionesUso = cu.map((e) => '• ${e.toString()}').join('\n');
        }

        // Variables (acepta alias y aplanado)
        final variables = _extractVariables(item);

        // ID preferente del JSON o slug del título
        final id = (item['id'] ?? _slug(titulo)).toString();
        final docRef = col.doc(id);

        final payload = <String, dynamic>{
          'titulo': titulo,
          'latex_expresion': latex,
          'explicacion': explic,
          'tema': tema,
          'condiciones_uso': condicionesUso,
          'estado': estado, // activa | borrador | archivada
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Escribe 'variables' SI el JSON traía alguna variante, incluso vacía,
        // para sobreescribir formatos antiguos.
        if (item.containsKey('variables') ||
            item.containsKey('vars') ||
            item.containsKey('variables_map') ||
            item.containsKey('variablesText')) {
          payload['variables'] = variables;
        }

        if (item['etiquetas'] != null) payload['etiquetas'] = item['etiquetas'];

        batch.set(docRef, payload, SetOptions(merge: true));
        ok++;
      } catch (e) {
        fail++;
      }
    }

    try {
      await batch.commit();
      setState(() => _status = '✅ Importación terminada. OK: $ok  •  Fallos: $fail');
    } catch (e) {
      setState(() => _status = '❌ Error al subir a Firestore: $e');
    }
  }

  String _slug(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Importar fórmulas (DEBUG)')),
      body: KeyboardActions(
        config: _kConfig(context),
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _jsonFocus,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      minLines: 12,
                      maxLines: null,
                      scrollPadding: const EdgeInsets.only(bottom: 200),
                      decoration: const InputDecoration(
                        hintText: 'Pega aquí tu JSON (objeto o lista de objetos)',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Validar + Subir'),
                  ),
                  onPressed: _import,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant.withOpacity(.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_status),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Solo visible/usable en DEBUG.\n'
                      'En producción, usa un importador backend o el emulador de Firestore.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}