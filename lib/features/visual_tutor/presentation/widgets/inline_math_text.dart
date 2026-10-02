import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// One safe fragment of a mixed prose and inline-mathematics board line.
@immutable
class InlineMathFragment {
  const InlineMathFragment.prose(this.value) : isMath = false;
  const InlineMathFragment.math(this.value) : isMath = true;

  final String value;
  final bool isMath;
}

/// Normalizes common transport/font substitutions without changing the
/// mathematical meaning of learner-facing text.
///
/// In particular, limit targets have arrived as `x\to2`, `x->2`, and as a
/// replacement square when an upstream font could not encode the arrow.
String normalizeBoardText(String raw) {
  var value = raw.replaceAll('\u00a0', ' ');
  value = value.replaceAllMapped(
    RegExp(
      r'([A-Za-z])\s*(?:\\to|->|\u2192|\u25a1|\ufffd)\s*'
      r'(-?(?:\d+(?:\.\d+)?|\u221e|\\infty))',
    ),
    (match) => '${match[1]} → ${match[2]}',
  );
  return value;
}

/// Parses only the two inline delimiters supported by the tutor contract.
///
/// `\(...\)` is always explicit math. A `$...$` pair is accepted only when
/// its contents look mathematical; currency such as `$25` or
/// `costs $25 and saves $5` therefore remains ordinary prose. Escaped dollars
/// are displayed literally.
List<InlineMathFragment> parseInlineMath(String raw) {
  final source = normalizeBoardText(raw);
  final fragments = <InlineMathFragment>[];
  final prose = StringBuffer();

  void flushProse() {
    if (prose.isEmpty) return;
    fragments.add(InlineMathFragment.prose(prose.toString()));
    prose.clear();
  }

  var index = 0;
  while (index < source.length) {
    if (source.startsWith(r'\$', index)) {
      prose.write(r'$');
      index += 2;
      continue;
    }

    if (source.startsWith(r'\(', index)) {
      final close = source.indexOf(r'\)', index + 2);
      if (close >= 0) {
        final candidate = source.substring(index + 2, close).trim();
        if (candidate.isNotEmpty) {
          flushProse();
          fragments.add(InlineMathFragment.math(candidate));
          index = close + 2;
          continue;
        }
      }
    }

    if (source[index] == r'$' && !source.startsWith(r'$$', index)) {
      final close = _nextUnescapedDollar(source, index + 1);
      if (close >= 0) {
        final candidate = source.substring(index + 1, close).trim();
        if (_looksLikeInlineMath(candidate)) {
          flushProse();
          fragments.add(InlineMathFragment.math(candidate));
          index = close + 1;
          continue;
        }
      }
    }

    prose.write(source[index]);
    index += 1;
  }
  flushProse();
  return fragments;
}

int _nextUnescapedDollar(String value, int start) {
  for (var index = start; index < value.length; index += 1) {
    if (value[index] != r'$') continue;
    var slashes = 0;
    for (
      var cursor = index - 1;
      cursor >= 0 && value[cursor] == r'\';
      cursor -= 1
    ) {
      slashes += 1;
    }
    if (slashes.isEven) return index;
  }
  return -1;
}

bool _looksLikeInlineMath(String value) {
  if (value.isEmpty || value.contains('\n')) return false;
  // Do not pair the opening dollar of one currency amount with the next
  // amount. A complete inline expression cannot end on a binary operator.
  if (RegExp(r'[=+*/^_<>&|\-]\s*$').hasMatch(value)) return false;
  // A bare amount is currency, not an equation.
  if (RegExp(r'^[+-]?\d[\d,.]*(?:\s*(?:USD|KHR|\$))?$').hasMatch(value)) {
    return false;
  }
  if (RegExp(r'^\\[A-Za-z]+').hasMatch(value)) return true;
  if (RegExp(r'[=+*/^_<>\u2192\u221e\u00b2\u00b3]').hasMatch(value)) {
    return true;
  }
  if (RegExp(r'^[A-Za-z](?:\([^\n]*\))?$').hasMatch(value)) return true;
  if (RegExp(r'^-?[0-9]+(?:\.[0-9]+)?[A-Za-z][A-Za-z0-9]*$').hasMatch(value)) {
    return true;
  }
  if (RegExp(r'^-[A-Za-z][A-Za-z0-9]*$').hasMatch(value)) return true;
  if (RegExp(r'^\([^\n]*[A-Za-z0-9][^\n]*\)$').hasMatch(value)) return true;
  // Chemical formulae are multiple element symbols with optional counts.
  if (RegExp(r'^(?:[A-Z][a-z]?\d*){2,}$').hasMatch(value)) return true;
  if (RegExp(r'^[A-Za-z]\s*-\s*[A-Za-z0-9]').hasMatch(value)) return true;
  return false;
}

String inlineMathSemanticLabel(String raw) => parseInlineMath(raw)
    .map(
      (fragment) => fragment.isMath
          ? fragment.value
                .replaceAll(r'\to', '→')
                .replaceAll(r'\rightarrow', '→')
                .replaceAll(r'\lim', 'limit')
                .replaceAll(RegExp(r'[{}]'), '')
          : fragment.value,
    )
    .join();

bool containsInlineMath(String raw) =>
    parseInlineMath(raw).any((fragment) => fragment.isMath);

/// Selectable prose with real inline math widgets. No raw delimiters are ever
/// painted, and malformed math falls back to its delimiter-free source.
class InlineMathText extends StatelessWidget {
  const InlineMathText({
    super.key,
    required this.text,
    required this.style,
    this.textDirection,
  });

  final String text;
  final TextStyle style;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final fragments = parseInlineMath(text);
    return SelectableText.rich(
      TextSpan(
        style: style,
        children: [
          for (final fragment in fragments)
            if (!fragment.isMath)
              TextSpan(text: fragment.value)
            else
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Math.tex(
                    fragment.value,
                    mathStyle: MathStyle.text,
                    textStyle: style.copyWith(fontStyle: FontStyle.normal),
                    onErrorFallback: (_) => Text(
                      fragment.value,
                      style: style.copyWith(fontStyle: FontStyle.normal),
                    ),
                  ),
                ),
              ),
        ],
      ),
      textDirection: textDirection,
      maxLines: null,
    );
  }
}
