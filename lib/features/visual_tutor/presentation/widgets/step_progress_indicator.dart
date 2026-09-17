import 'package:flutter/material.dart';

class StepProgressIndicator extends StatelessWidget {
  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.learningObjective,
  });

  final int currentStep;
  final int totalSteps;
  final String learningObjective;

  @override
  Widget build(BuildContext context) {
    final safeTotal = totalSteps < 1 ? 1 : totalSteps;
    final progress = (currentStep.clamp(1, safeTotal) / safeTotal).toDouble();
    return Semantics(
      label: 'Step $currentStep of $safeTotal. $learningObjective',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step $currentStep of $safeTotal',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            learningObjective,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: const Duration(milliseconds: 260),
            builder: (context, value, _) =>
                LinearProgressIndicator(value: value, minHeight: 8),
          ),
        ],
      ),
    );
  }
}
