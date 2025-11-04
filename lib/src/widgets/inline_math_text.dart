import 'package:flutter/material.dart';
import 'formula_math.dart'; // tu widget que ya renderiza LaTeX

/// Muestra texto con soporte LaTeX inline entre $...$ o $$...$$.
/// También acepta \(..\) y \[..\] (los normaliza).
class InlineMathText extends StatelessWidget {
  const InlineMathText(
      this.text, {
        this.fontSize = 16,
        this.style,
        super.key,
      });

  final String text;
  final double fontSize;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;

    final pieces = _splitInlineMath(text);
    final spans = <InlineSpan>[];

    for (final p in pieces) {
      if (p.isMath) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FormulaMath(p.text, fontSize: fontSize),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: p.text, style: baseStyle));
      }
    }

    return RichText(text: TextSpan(style: baseStyle, children: spans));
  }

  /// Tokeniza por $...$ y $$...$$. Normaliza \(..\) → $..$ y \[..\] → $$..$$.
  List<_Seg> _splitInlineMath(String src) {
    var s = src
        .replaceAll(r'\(', r'$')
        .replaceAll(r'\)', r'$')
        .replaceAll(r'\[', r'$$')
        .replaceAll(r'\]', r'$$');

    final reg = RegExp(r'(\${1,2})(.+?)\1'); // $...$ o $$...$$ (no codicioso)
    final out = <_Seg>[];
    var last = 0;

    for (final m in reg.allMatches(s)) {
      if (m.start > last) {
        out.add(_Seg(false, s.substring(last, m.start)));
      }
      final content = m.group(2) ?? '';
      out.add(_Seg(true, content.trim()));
      last = m.end;
    }
    if (last < s.length) {
      out.add(_Seg(false, s.substring(last)));
    }
    return out;
  }
}

class _Seg {
  final bool isMath;
  final String text;
  _Seg(this.isMath, this.text);
}