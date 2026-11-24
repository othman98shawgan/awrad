// lib/features/progress/view/progress_page.dart

import 'package:flutter/material.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement weekly/monthly heatmap or charts
    return Center(
      child: Text(
        'Progress View\n(coming soon)',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
