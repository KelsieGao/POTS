import 'package:flutter/material.dart';

class CountdownDisplay extends StatelessWidget {
  const CountdownDisplay({super.key, required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    final formatted =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Text(
      formatted,
      style: Theme.of(
        context,
      ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }
}
