import 'package:flutter/material.dart';

import '../theme/pp_theme.dart';

/// A deliberately small Markdown renderer — enough for the in-app Privacy and
/// Help documents (headings, paragraphs, bullet lists, `**bold**`). No
/// package dependency; the app's Flutter SDK can't resolve most plugins.
class SimpleMarkdown extends StatelessWidget {
  const SimpleMarkdown(this.data, {super.key});

  final String data;

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];
    final lines = data.trim().split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trimRight();
      if (line.isEmpty) {
        blocks.add(const SizedBox(height: 12));
      } else if (line.startsWith('# ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 8),
          child: Text(line.substring(2),
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: PP.track(24, -0.035))),
        ));
      } else if (line.startsWith('## ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(line.substring(3),
              style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: PP.track(16.5, -0.02))),
        ));
      } else if (line.startsWith('- ')) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 10),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                      color: PP.forest, shape: BoxShape.circle),
                ),
              ),
              Expanded(child: _rich(line.substring(2), 13.5)),
            ],
          ),
        ));
      } else {
        blocks.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _rich(line, 13.5),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  Widget _rich(String text, double size) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          fontWeight: i.isOdd ? FontWeight.w700 : FontWeight.w500,
        ),
      ));
    }
    return Text.rich(
      TextSpan(children: spans),
      style: TextStyle(
          fontSize: size,
          height: 1.6,
          color: PP.inkA(0.75),
          fontWeight: FontWeight.w500),
    );
  }
}
