import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../core/adaptive_colors.dart';
import '../../core/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/student_design_system.dart';
import 'student_lessons_repository.dart';

/// Full pedagogical detail screen for a student lesson.
/// Shows:
/// 1. Header with topic, subject, grade, and difficulty.
/// 2. Tab 1: Concepts & Formulas (មេរៀន និងរូបមន្ត) with KaTeX math rendering.
/// 3. Tab 2: Step-by-Step Example (ឧទាហរណ៍គំរូ) + "Watch on Whiteboard" button.
/// 4. Tab 3: Practice (លំហាត់អនុវត្ត) + targeted quiz launcher.
class StudentLessonDetailScreen extends StatefulWidget {
  const StudentLessonDetailScreen({
    super.key,
    required this.lesson,
    required this.onBack,
    required this.onWatchOnWhiteboard,
    required this.onPractice,
    this.repository,
    this.initialTab = 0,
    this.onAskTutor,
  });

  final StudentLesson lesson;
  final VoidCallback onBack;
  final ValueChanged<String?> onWatchOnWhiteboard;
  final ValueChanged<StudentLesson> onPractice;
  final StudentLessonsRepository? repository;
  final int initialTab;
  final ValueChanged<String?>? onAskTutor;

  @override
  State<StudentLessonDetailScreen> createState() =>
      _StudentLessonDetailScreenState();
}

class _StudentLessonDetailScreenState extends State<StudentLessonDetailScreen>
    with SingleTickerProviderStateMixin {
  late final StudentLessonsRepository _repository;
  late final TabController _tabController;
  late Future<LessonDetailedContent> _contentFuture;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? buildDefaultStudentLessonsRepository();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    _loadContent();
  }

  void _loadContent() {
    _contentFuture = _repository.loadLessonContent(widget.lesson.lessonId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _difficultyLabel(AppLocalizations l10n, String difficulty) =>
      switch (difficulty.toLowerCase()) {
        'intermediate' || 'medium' => l10n.difficultyIntermediate,
        'advanced' || 'hard' => l10n.difficultyAdvanced,
        _ => l10n.difficultyBeginner,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visual = subjectVisual(widget.lesson.subject);
    final ready = widget.lesson.isAvailable;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 600 ? 28.0 : 16.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('lesson-detail-back-button'),
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(l10n.allLessons),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Header Card ───────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: StudentStyle.card(
                      context,
                      accent: visual.color,
                    ).copyWith(
                      color: Color.alphaBlend(
                        visual.color.withValues(alpha: .06),
                        AdaptiveColors.card(context),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: visual.color.withValues(alpha: .16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(visual.icon, color: visual.color, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${l10n.gradeLevel(widget.lesson.grade)} · ${localizedSubjectName(l10n, widget.lesson.subject)}',
                                    style: StudentStyle.body(
                                      context,
                                      size: 13,
                                      color: visual.color,
                                    ).copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Topic: ${widget.lesson.topic}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AdaptiveColors.subtle(context),
                                      fontFamilyFallback: AppTheme.fontFallback,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StudentPill(
                              icon: ready
                                  ? Icons.check_circle_rounded
                                  : Icons.schedule_rounded,
                              label: ready
                                  ? l10n.topicReady
                                  : l10n.lessonComingSoon,
                              color: ready
                                  ? const Color(0xFF10B981)
                                  : AdaptiveColors.muted(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.lesson.displayTitle,
                          style: StudentStyle.title(context, 26),
                        ),
                        if (widget.lesson.khmerDescription != null &&
                            widget.lesson.khmerDescription!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.lesson.khmerDescription!,
                            style: StudentStyle.body(
                              context,
                              size: 15,
                              color: AdaptiveColors.text(context),
                            ),
                          ),
                        ],
                        if (widget.lesson.description != null &&
                            widget.lesson.description!.isNotEmpty &&
                            widget.lesson.description !=
                                widget.lesson.khmerDescription) ...[
                          const SizedBox(height: 6),
                          Text(
                            widget.lesson.description!,
                            style: StudentStyle.body(context, size: 14),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            StudentPill(
                              label: _difficultyLabel(
                                l10n,
                                widget.lesson.difficulty,
                              ),
                              color: visual.color,
                            ),
                            StudentPill(
                              icon: Icons.calculate_outlined,
                              label: l10n.problemsCount(
                                widget.lesson.problemCount,
                              ),
                              color: AdaptiveColors.muted(context),
                            ),
                            for (final tag in widget.lesson.tags)
                              StudentPill(
                                label: tag.startsWith('#') ? tag : '#$tag',
                                color: AppColors.cyan,
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (ready)
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: FilledButton.icon(
                                  key: const Key('lesson-start-button'),
                                  onPressed: () => widget.onWatchOnWhiteboard(
                                    widget.lesson.starterProblem,
                                  ),
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: Text(l10n.startWithTutor),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: visual.color,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(0, 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontFamilyFallback: AppTheme.fontFallback,
                                    ),
                                  ),
                                ),
                              ),
                              if (widget.lesson.practiceAvailable) ...[
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: OutlinedButton.icon(
                                    key: const Key('lesson-header-practice-button'),
                                    onPressed: () => widget.onPractice(widget.lesson),
                                    icon: const Icon(Icons.quiz_outlined),
                                    label: Text(l10n.practice),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AdaptiveColors.text(context),
                                      minimumSize: const Size(0, 48),
                                      side: BorderSide(color: AdaptiveColors.line(context)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          )
                        else
                          _ComingSoonPanel(
                            onAsk: () => widget.onAskTutor != null
                                ? widget.onAskTutor!(widget.lesson.topic)
                                : widget.onWatchOnWhiteboard(widget.lesson.starterProblem),
                          ),
                      ],
                    ),
                  ),

                  if (ready) ...[
                    const SizedBox(height: 20),

                    // ── Segmented Tabs ────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: AdaptiveColors.card(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AdaptiveColors.line(context)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: visual.color.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: visual.color.withValues(alpha: .4)),
                        ),
                        dividerColor: Colors.transparent,
                        labelColor: AdaptiveColors.text(context),
                        unselectedLabelColor: AdaptiveColors.subtle(context),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          fontFamilyFallback: AppTheme.fontFallback,
                        ),
                        tabs: [
                          Tab(
                            key: const Key('tab-concepts'),
                            icon: const Icon(Icons.menu_book_rounded, size: 18),
                            text: l10n.isKhmer
                                ? 'មេរៀន និងរូបមន្ត'
                                : 'Concepts & Formulas',
                          ),
                          Tab(
                            key: const Key('tab-examples'),
                            icon: const Icon(Icons.school_rounded, size: 18),
                            text: l10n.isKhmer
                                ? 'ឧទាហរណ៍គំរូ'
                                : 'Step-by-Step Example',
                          ),
                          Tab(
                            key: const Key('tab-practice'),
                            icon: const Icon(Icons.quiz_rounded, size: 18),
                            text: l10n.isKhmer ? 'លំហាត់អនុវត្ត' : 'Practice',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Tab Content ───────────────────────────────────────────
                    FutureBuilder<LessonDetailedContent>(
                      future: _contentFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return _ContentSkeleton();
                        }
                        final content = snapshot.data ??
                            fallbackLessonDetailedContent(widget.lesson.lessonId);

                        return AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, _) {
                            return switch (_tabController.index) {
                              1 => _WorkedExampleTab(
                                  content: content,
                                  lesson: widget.lesson,
                                  color: visual.color,
                                  onWatch: widget.onWatchOnWhiteboard,
                                ),
                              2 => _PracticeTab(
                                  content: content,
                                  lesson: widget.lesson,
                                  color: visual.color,
                                  onPractice: widget.onPractice,
                                ),
                              _ => _ConceptsAndFormulasTab(
                                  content: content,
                                  color: visual.color,
                                  onWatch: widget.onWatchOnWhiteboard,
                                ),
                            };
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Tab 1: Concepts & Formulas ───────────────────────────────────────────────
class _ConceptsAndFormulasTab extends StatelessWidget {
  const _ConceptsAndFormulasTab({
    required this.content,
    required this.color,
    required this.onWatch,
  });
  final LessonDetailedContent content;
  final Color color;
  final ValueChanged<String?> onWatch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Concepts
        for (final concept in content.concepts) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: StudentStyle.card(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.lightbulb_outline_rounded, color: color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        concept.title,
                        style: StudentStyle.title(context, 16),
                      ),
                    ),
                  ],
                ),
                if (concept.summary.isNotEmpty &&
                    concept.summary != concept.title) ...[
                  const SizedBox(height: 8),
                  Text(
                    concept.summary,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AdaptiveColors.text(context),
                      fontFamilyFallback: AppTheme.fontFallback,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  concept.body,
                  style: StudentStyle.body(context, size: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Key Formulas
        if (content.formulas.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.functions_rounded, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                l10n.isKhmer ? 'រូបមន្តសំខាន់ៗ' : 'Key Formulas',
                style: StudentStyle.title(context, 17),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final formula in content.formulas) ...[
            _FormulaCard(formula: formula, color: color),
            const SizedBox(height: 10),
          ],
        ],

        // Common Misconceptions
        if (content.commonMisconceptions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Text(
                l10n.isKhmer ? 'ចំណុចងាយភាន់ច្រឡំ' : 'Common Misconceptions',
                style: StudentStyle.title(context, 17),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: .3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < content.commonMisconceptions.length; i++) ...[
                  if (i > 0) const Divider(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          content.commonMisconceptions[i],
                          style: StudentStyle.body(
                            context,
                            size: 14,
                            color: AdaptiveColors.text(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],

        // Khmer Terminology
        if (content.khmerTerms.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.translate_rounded, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                l10n.isKhmer ? 'វាក្យសព្ទខ្មែរ' : 'Khmer Terminology',
                style: StudentStyle.title(context, 17),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in content.khmerTerms.entries)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AdaptiveColors.card(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdaptiveColors.line(context)),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        color: AdaptiveColors.text(context),
                        fontFamilyFallback: AppTheme.fontFallback,
                      ),
                      children: [
                        TextSpan(
                          text: '${entry.key}: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AdaptiveColors.subtle(context),
                          ),
                        ),
                        TextSpan(
                          text: entry.value,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],

        const SizedBox(height: 20),
        FilledButton.icon(
          key: const Key('lesson-bottom-watch-button'),
          onPressed: () => onWatch(content.starterProblem),
          icon: const Icon(Icons.draw_rounded, size: 20),
          label: Text(
            l10n.isKhmer ? 'មើលការបង្រៀនលើក្តារខៀន' : 'Watch on Whiteboard',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontFamilyFallback: AppTheme.fontFallback,
            ),
          ),
        ),
      ],
    );
  }
}

class _FormulaCard extends StatelessWidget {
  const _FormulaCard({required this.formula, required this.color});
  final LessonFormulaItem formula;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudentStyle.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formula.name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AdaptiveColors.subtle(context),
              fontFamilyFallback: AppTheme.fontFallback,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AdaptiveColors.controlFill(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                formula.expression,
                textStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                onErrorFallback: (_) => Text(
                  formula.expression,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFamilyFallback: AppTheme.fontFallback,
                  ),
                ),
              ),
            ),
          ),
          if (formula.explanation != null &&
              formula.explanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              formula.explanation!,
              style: StudentStyle.body(context, size: 13),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tab 2: Step-by-Step Example ──────────────────────────────────────────────
class _WorkedExampleTab extends StatelessWidget {
  const _WorkedExampleTab({
    required this.content,
    required this.lesson,
    required this.color,
    required this.onWatch,
  });

  final LessonDetailedContent content;
  final StudentLesson lesson;
  final Color color;
  final ValueChanged<String?> onWatch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final examples = content.examples.isNotEmpty
        ? content.examples
        : [
            LessonExampleItem(
              problem: lesson.starterProblem ?? r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}',
              solution: 'Worked solution',
              steps: [
                'Substitute initial values to check behavior',
                'Apply fundamental principles and simplify',
                'Evaluate the final result',
              ],
            ),
          ];

    final primaryExample = examples.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var exIdx = 0; exIdx < examples.length; exIdx++) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: StudentStyle.card(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.mode_standby_rounded, color: color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${l10n.isKhmer ? 'ឧទាហរណ៍' : 'Worked Example'} ${exIdx + 1}',
                      style: StudentStyle.title(context, 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AdaptiveColors.controlFill(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.isKhmer ? 'ប្រធានលំហាត់៖' : 'Problem:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AdaptiveColors.subtle(context),
                          fontFamilyFallback: AppTheme.fontFallback,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: examples[exIdx].problem.contains('\\')
                            ? Math.tex(
                                examples[exIdx].problem,
                                textStyle: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AdaptiveColors.text(context),
                                ),
                                onErrorFallback: (_) => Text(
                                  examples[exIdx].problem,
                                  style: StudentStyle.body(
                                    context,
                                    size: 15,
                                    color: AdaptiveColors.text(context),
                                  ),
                                ),
                              )
                            : Text(
                                examples[exIdx].problem,
                                style: StudentStyle.body(
                                  context,
                                  size: 15,
                                  color: AdaptiveColors.text(context),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.isKhmer ? 'ដំណោះស្រាយជាជំហានៗ៖' : 'Step-by-Step Logic:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AdaptiveColors.subtle(context),
                    fontFamilyFallback: AppTheme.fontFallback,
                  ),
                ),
                const SizedBox(height: 10),
                for (var sIdx = 0; sIdx < examples[exIdx].steps.length; sIdx++) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${sIdx + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            examples[exIdx].steps[sIdx],
                            style: StudentStyle.body(context, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (examples[exIdx].solution.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: .3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${l10n.isKhmer ? 'ចម្លើយចុងក្រោយ៖' : 'Final Answer:'} ${examples[exIdx].solution}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ── Primary Action Button: Watch on Whiteboard ───────────────────────
        FilledButton.icon(
          key: const Key('lesson-watch-whiteboard-button'),
          onPressed: () => onWatch(primaryExample.problem),
          icon: const Icon(Icons.draw_rounded, size: 22),
          label: Text(
            l10n.isKhmer
                ? 'មើលការបង្រៀនលើក្តារខៀន'
                : 'Watch on Whiteboard',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamilyFallback: AppTheme.fontFallback,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tab 3: Practice ──────────────────────────────────────────────────────────
class _PracticeTab extends StatelessWidget {
  const _PracticeTab({
    required this.content,
    required this.lesson,
    required this.color,
    required this.onPractice,
  });

  final LessonDetailedContent content;
  final StudentLesson lesson;
  final Color color;
  final ValueChanged<StudentLesson> onPractice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: StudentStyle.card(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.quiz_rounded, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.isKhmer
                              ? 'លំហាត់អនុវត្តតាមមេរៀន'
                              : 'Curriculum Practice Quiz',
                          style: StudentStyle.title(context, 17),
                        ),
                        Text(
                          '${l10n.problemsCount(lesson.problemCount)} · ${lesson.topic}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AdaptiveColors.subtle(context),
                            fontFamilyFallback: AppTheme.fontFallback,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.isKhmer
                    ? 'ពង្រឹងចំណេះដឹងរបស់អ្នកជាមួយសំណួរ និងលំហាត់ជាក់ស្តែងដែលត្រូវនឹងកម្មវិធីសិក្សាជាតិ។'
                    : 'Reinforce what you have learned with curriculum-aligned practice questions designed for this lesson.',
                style: StudentStyle.body(context, size: 14),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('lesson-practice-button'),
                onPressed: () => onPractice(lesson),
                icon: const Icon(Icons.play_circle_filled_rounded, size: 22),
                label: Text(
                  l10n.isKhmer ? 'ចាប់ផ្តើមអនុវត្ត' : 'Start Practice',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFamilyFallback: AppTheme.fontFallback,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContentSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget block(double height) => Container(
          height: height,
          decoration: BoxDecoration(
            color: AdaptiveColors.line(context).withValues(alpha: .45),
            borderRadius: BorderRadius.circular(16),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        block(120),
        const SizedBox(height: 12),
        block(90),
        const SizedBox(height: 12),
        block(140),
      ],
    );
  }
}

class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel({required this.onAsk});
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdaptiveColors.controlFill(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdaptiveColors.line(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: AppColors.cyan, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(loc.lessonComingSoonTitle, style: StudentStyle.title(context, 15))),
            ],
          ),
          const SizedBox(height: 6),
          Text(loc.lessonComingSoonDesc, style: StudentStyle.body(context, size: 13)),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const Key('lesson-ask-tutor-button'),
            onPressed: onAsk,
            icon: const Icon(Icons.psychology_rounded, size: 18),
            label: Text(loc.askTutorAboutTopic),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: const Color(0xFF070B14),
              minimumSize: const Size(0, 44),
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontFamilyFallback: AppTheme.fontFallback),
            ),
          ),
        ],
      ),
    );
  }
}
