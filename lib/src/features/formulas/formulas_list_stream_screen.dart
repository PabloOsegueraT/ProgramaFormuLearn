import 'package:flutter/material.dart';
import 'package:formulearn/src/data/formulas/formulas_repository.dart';
import 'package:formulearn/src/data/formulas/formula_model.dart';
import 'package:formulearn/src/router.dart';

class FormulasListStreamScreen extends StatelessWidget {
  const FormulasListStreamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = FormulaRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Fórmulas (stream)')),
      body: StreamBuilder<List<FormulaModel>>(
        stream: repo.streamAll(), // o repo.streamAll(tema: 'Física')
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No hay fórmulas'));
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final f = items[i];
              return ListTile(
                title: Text(f.titulo),
                subtitle: Text(f.tema.isEmpty ? '—' : f.tema),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRouter.formulaDetail,
                    arguments: {
                      'title': f.titulo,
                      'expression': f.latex,
                      'summary': f.explicacion,
                      'topic': f.tema,
                      'conditions': f.condicionesUso,
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}