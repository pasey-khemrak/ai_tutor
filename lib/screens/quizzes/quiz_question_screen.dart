import 'package:flutter/material.dart';
import '../../core/adaptive_colors.dart';
import '../../core/app_colors.dart';
import '../../features/quizzes/quiz_models.dart';

class QuizQuestionScreen extends StatelessWidget {
  const QuizQuestionScreen({
    super.key,
    required this.quiz,
    required this.questionIndex,
    required this.selectedAnswer,
    required this.onAnswerChanged,
    required this.onNext,
    required this.onResults,
    required this.onBack,
  });

  final QuizEntity quiz;
  final int questionIndex;
  final QuizAnswerSubmissionEntity? selectedAnswer;
  final ValueChanged<QuizAnswerSubmissionEntity> onAnswerChanged;
  final VoidCallback onNext;
  final VoidCallback onResults;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textColor = AdaptiveColors.text(context);
    final borderColor = AdaptiveColors.line(context);
    final question = quiz.questions[questionIndex];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QuizProgressHeader(
                  questionNumber: questionIndex + 1,
                  totalQuestions: quiz.questions.length,
                ),
                const SizedBox(height: 18),
                QuestionCard(
                  question: question,
                  selectedAnswer: selectedAnswer,
                  onAnswerChanged: onAnswerChanged,
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: onResults,
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: const Text('ពិនិត្យលទ្ធផលរហ័ស'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        QuizQuestionFooter(onNext: onNext, onBack: onBack),
      ],
    );
  }
}

class QuizProgressHeader extends StatelessWidget {
  const QuizProgressHeader({
    super.key,
    required this.questionNumber,
    required this.totalQuestions,
  });

  final int questionNumber;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    final textColor = AdaptiveColors.text(context);
    final mutedColor = AdaptiveColors.muted(context);
    final lineColor = AdaptiveColors.line(context);

    return Column(
      children: [
        Row(
          children: [
            Text(
              'សំណួរ ',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
            ),
            Text(
              '$questionNumber',
              style: TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              ' នៃ $totalQuestions',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
            ),
            Spacer(),
            Text(
              '${((questionNumber / totalQuestions) * 100).round()}% Complete',
              style: TextStyle(color: mutedColor, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: questionNumber / totalQuestions,
            minHeight: 6,
            backgroundColor: lineColor,
            valueColor: const AlwaysStoppedAnimation(AppColors.blue),
          ),
        ),
      ],
    );
  }
}

class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.onAnswerChanged,
  });

  final QuizQuestionEntity question;
  final QuizAnswerSubmissionEntity? selectedAnswer;
  final ValueChanged<QuizAnswerSubmissionEntity> onAnswerChanged;

  @override
  Widget build(BuildContext context) {
    final panelColor = AdaptiveColors.panel(context);
    final lineColor = AdaptiveColors.line(context);
    final textColor = AdaptiveColors.text(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${question.order}. ${question.questionText}',
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (question.visualizationData?['equation'] is String) ...[
            const SizedBox(height: 8),
            Text(
              question.visualizationData!['equation'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (question.isMultipleChoice)
            for (final option in question.options)
              QuizChoice(
                key: Key('quiz-choice-${option.optionId}'),
                letter: option.label,
                text: option.text,
                selected: selectedAnswer?.selectedOptionId == option.optionId,
                onTap: () => onAnswerChanged(
                  QuizAnswerSubmissionEntity(
                    questionId: question.questionId,
                    selectedOptionId: option.optionId,
                    answer: option.text,
                  ),
                ),
              )
          else
            QuizFreeResponseInput(
              key: Key('quiz-free-response-${question.questionId}'),
              initialValue: selectedAnswer?.answer ?? '',
              onChanged: (value) => onAnswerChanged(
                QuizAnswerSubmissionEntity(
                  questionId: question.questionId,
                  answer: value,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class QuizChoice extends StatelessWidget {
  const QuizChoice({
    super.key,
    required this.letter,
    required this.text,
    this.selected = false,
    this.correct = false,
    this.wrong = false,
    this.onTap,
  });

  final String letter;
  final String text;
  final bool selected;
  final bool correct;
  final bool wrong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lineColor = AdaptiveColors.line(context);
    final cardColor = AdaptiveColors.card(context);
    final defaultTextColor = AdaptiveColors.text(context);
    final letterBackground = AdaptiveColors.isLight(context)
        ? const Color(0xFFEAF0FF)
        : Colors.white.withValues(alpha: .07);

    final borderColor = correct
        ? Colors.greenAccent.withValues(alpha: .45)
        : wrong
        ? AppColors.peach.withValues(alpha: .45)
        : selected
        ? AppColors.blue
        : lineColor;
    final textColor = correct
        ? Colors.greenAccent
        : wrong
        ? AppColors.peach
        : defaultTextColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue.withValues(alpha: .14) : cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.blue : letterBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                letter,
                style: TextStyle(
                  color: selected ? Colors.white : defaultTextColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (selected || correct)
              const Icon(Icons.check_circle, color: AppColors.cyan, size: 18),
          ],
        ),
      ),
    );
  }
}

class QuizFreeResponseInput extends StatefulWidget {
  const QuizFreeResponseInput({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<QuizFreeResponseInput> createState() => _QuizFreeResponseInputState();
}

class _QuizFreeResponseInputState extends State<QuizFreeResponseInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant QuizFreeResponseInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      key: const Key('quiz-free-response-input'),
      keyboardType: TextInputType.text,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: 'Type your answer...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class QuizQuestionFooter extends StatelessWidget {
  const QuizQuestionFooter({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final panelColor = AdaptiveColors.panel(context);
    final lineColor = AdaptiveColors.line(context);
    final mutedColor = AdaptiveColors.muted(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: panelColor,
        border: Border(top: BorderSide(color: lineColor)),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('មុន'),
            style: TextButton.styleFrom(foregroundColor: mutedColor),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              fixedSize: const Size(132, 52),
              backgroundColor: AppColors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'បន្ទាប់ ›',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
