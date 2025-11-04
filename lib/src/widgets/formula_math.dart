// lib/src/widgets/formula_math.dart
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class FormulaMath extends StatelessWidget {
  const FormulaMath(this.expr, {super.key, this.fontSize = 20});
  final String expr;
  final double fontSize;

  String _normalizeLatex(String s) {
    var x = s.trim();

    // símbolos comunes
    x = x.replaceAll('·', r'\cdot ');
    x = x.replaceAll('×', r'\cdot ');
    x = x.replaceAll('Δ', r'\Delta ');
    x = x.replaceAll('Σ', r'\Sigma ');
    x = x.replaceAll('π', r'\pi ');
    x = x.replaceAll('∞', r'\infty ');

    // Heurística simple: "= a / b" -> "= \frac{a}{b}"
    x = x.replaceAllMapped(
      RegExp(r'=\s*([A-Za-z0-9\)\]]+)\s*/\s*([A-Za-z0-9\(\[]+)'),
          (m) => '= \\frac{${m[1]}}{${m[2]}}',
    );

    return x;
  }

  @override
  Widget build(BuildContext context) {
    final latex = _normalizeLatex(expr);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Math.tex(
        latex,
        textStyle: TextStyle(fontSize: fontSize),
        // Si algo falla en el parser, muestra el texto plano
        onErrorFallback: (err) => Text(
          expr,
          style: TextStyle(fontSize: fontSize, fontFamily: 'monospace'),
        ),
      ),
    );
  }
}