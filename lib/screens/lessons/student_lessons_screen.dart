import 'package:flutter/material.dart';

import '../../core/adaptive_colors.dart';
import '../../core/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/language_switcher_button.dart';
import '../../shared/state_widgets/app_error_state.dart';
import '../../shared/student_design_system.dart';
import 'student_lessons_repository.dart';

/// The Lessons tab: the published lesson library with a detail page for each
/// lesson, where the student starts the whiteboard tutor or practises.
class StudentLessonsScreen extends StatefulWidget {
  const StudentLessonsScreen({
    super.key,
    required this.onOpenLesson,
    required this.onPractice,
    this.repository,
    this.onAskTutor,
  });
  final ValueChanged<StudentLesson> onOpenLesson;
  final ValueChanged<StudentLesson> onPractice;
  final StudentLessonsRepository? repository;
  final ValueChanged<String?>? onAskTutor;
  @override
  State<StudentLessonsScreen> createState() => _StudentLessonsScreenState();
}

class _StudentLessonsScreenState extends State<StudentLessonsScreen> {
  late final StudentLessonsRepository _repository;
  late Future<List<StudentLesson>> _future;
  final _search = TextEditingController();
  String? _subjectId;
  int? _grade;
  StudentLesson? _selected;
  final Map<String, String> _knownSubjects = {
    'math': 'Mathematics',
    'physics': 'Physics',
    'chemistry': 'Chemistry',
  };

  bool get _isDemo => _repository is LocalDemoStudentLessonsRepository;
  bool get _hasFilters =>
      _grade != null || _subjectId != null || _search.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? buildDefaultStudentLessonsRepository();
    _future = _repository.loadLessons(grade: _grade);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // Filtering happens on the server; only the list reloads, so the search box
  // keeps focus and the filters stay put.
  void _reload() {
    setState(() {
      _future = _repository.loadLessons(
        search: _search.text,
        subjectId: _subjectId,
        grade: _grade,
      );
    });
  }

  void _clearFilters() {
    _search.clear();
    _grade = null;
    _subjectId = null;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    if (selected != null) {
      return _LessonDetail(
        lesson: selected,
        onBack: () => setState(() => _selected = null),
        onStart: () => widget.onOpenLesson(selected),
        onPractice: () => widget.onPractice(selected),
        onAskTutor: widget.onAskTutor,
      );
    }
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 1100
            ? 40.0
            : constraints.maxWidth >= 600
            ? 28.0
            : 16.0;
        final width = (constraints.maxWidth - horizontal * 2).clamp(0.0, 1180.0);
        final columns = width >= 1000 ? 3 : width >= 620 ? 2 : 1;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 32),
          child: Center(
            child: SizedBox(
              width: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.navLessons, style: StudentStyle.title(context, 24)),
                            const SizedBox(height: 4),
                            Text(
                              _isDemo
                                  ? 'Choose the local curriculum demo and learn with the visual tutor.'
                                  : l10n.publishedLessonsSubtitle,
                              style: StudentStyle.body(context, size: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const LanguageSwitcherButton(compact: true),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SearchField(controller: _search, onSubmit: _reload),
                  const SizedBox(height: 12),
                  _ChipRow(
                    children: [
                      StudentFilterChip(
                        key: const Key('filter-grade-all'),
                        label: l10n.allGrades,
                        selected: _grade == null,
                        onTap: () {
                          _grade = null;
                          _reload();
                        },
                      ),
                      for (final grade in const [10, 11, 12])
                        StudentFilterChip(
                          key: Key('filter-grade-$grade'),
                          label: l10n.gradeLevel(grade),
                          selected: _grade == grade,
                          onTap: () {
                            _grade = grade;
                            _reload();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ChipRow(
                    children: [
                      StudentFilterChip(
                        label: l10n.allSubjects,
                        selected: _subjectId == null,
                        onTap: () {
                          _subjectId = null;
                          _reload();
                        },
                      ),
                      for (final entry in _knownSubjects.entries)
                        StudentFilterChip(
                          key: Key('filter-subject-${entry.key}'),
                          label: localizedSubjectName(l10n, entry.value),
                          icon: subjectVisual(entry.value).icon,
                          color: subjectVisual(entry.value).color,
                          selected: _subjectId == entry.key,
                          onTap: () {
                            _subjectId = entry.key;
                            _reload();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<StudentLesson>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return _ListSkeleton(columns: columns);
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: AppErrorState(message: l10n.lessonsLoadError, onRetry: _reload),
                        );
                      }
                      final lessons = snapshot.data ?? const <StudentLesson>[];
                      for (final lesson in lessons) {
                        _knownSubjects[lesson.subjectId] = lesson.subject;
                      }
                      if (lessons.isEmpty) {
                        if (_hasFilters && !_isDemo) {
                          return _NoMatches(onClear: _clearFilters);
                        }
                        return _NoPublishedLessons(
                          onRetry: _reload,
                          onAskTutor: widget.onAskTutor,
                          message: _isDemo ? localMvpUnsupportedRecoveryMessage : null,
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.lessonsCount(lessons.length),
                            style: StudentStyle.body(context, size: 12),
                          ),
                          const SizedBox(height: 10),
                          _LessonGrid(
                            columns: columns,
                            children: [
                              for (final lesson in lessons)
                                _LessonCard(
                                  lesson: lesson,
                                  fillHeight: columns > 1,
                                  onTap: () => setState(() => _selected = lesson),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/* ─── Controls ──────────────────────────────────────────────────────────── */

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onSubmit});
  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      key: const Key('lessons-search-field'),
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSubmit(),
      style: TextStyle(
        color: AdaptiveColors.text(context),
        fontSize: 15,
        fontFamilyFallback: AppTheme.fontFallback,
      ),
      decoration: InputDecoration(
        hintText: l10n.searchLessonsHint,
        hintStyle: StudentStyle.body(context, size: 14),
        prefixIcon: Icon(Icons.search_rounded, color: AdaptiveColors.muted(context)),
        suffixIcon: IconButton(
          tooltip: l10n.searchLessonsHint,
          onPressed: onSubmit,
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
        filled: true,
        fillColor: AdaptiveColors.card(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AdaptiveColors.line(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          children[i],
        ],
      ],
    ),
  );
}

String _difficultyLabel(AppLocalizations l10n, String difficulty) =>
    switch (difficulty.toLowerCase()) {
      'intermediate' || 'medium' => l10n.difficultyIntermediate,
      'advanced' || 'hard' => l10n.difficultyAdvanced,
      _ => l10n.difficultyBeginner,
    };

String _tagLabel(String tag) => tag.startsWith('#') ? tag : '#$tag';

/* ─── Library ───────────────────────────────────────────────────────────── */

class _LessonGrid extends StatelessWidget {
  const _LessonGrid({required this.columns, required this.children});
  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      final slice = children.sublist(start, (start + columns).clamp(0, children.length));
      rows.add(
        columns == 1
            ? slice.first
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < columns; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: i < slice.length ? slice[i] : const SizedBox.shrink()),
                    ],
                  ],
                ),
              ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          rows[i],
        ],
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.fillHeight, required this.onTap});
  final StudentLesson lesson;
  final bool fillHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visual = subjectVisual(lesson.subject);
    final ready = lesson.isAvailable;
    final description = lesson.displayDescription;

    return Semantics(
      button: true,
      label: lesson.displayTitle,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('lesson-card-${lesson.lessonId}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: StudentStyle.card(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: visual.color.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(visual.icon, color: visual.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.displayTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: StudentStyle.title(context, 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${l10n.gradeLevel(lesson.grade)} · ${localizedSubjectName(l10n, lesson.subject)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: StudentStyle.body(context, size: 12, color: visual.color),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (description != null &&
                    description.trim().isNotEmpty &&
                    description != lesson.displayTitle) ...[
                  const SizedBox(height: 10),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: StudentStyle.body(context),
                  ),
                ],
                const SizedBox(height: 12),
                if (fillHeight) const Spacer(),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StudentPill(
                      icon: ready ? Icons.check_circle_rounded : Icons.schedule_rounded,
                      label: ready ? l10n.topicReady : l10n.lessonComingSoon,
                      color: ready ? const Color(0xFF10B981) : AdaptiveColors.muted(context),
                    ),
                    StudentPill(label: _difficultyLabel(l10n, lesson.difficulty), color: visual.color),
                    StudentPill(
                      icon: Icons.calculate_outlined,
                      label: l10n.problemsCount(lesson.problemCount),
                      color: AdaptiveColors.muted(context),
                    ),
                    for (final tag in lesson.tags.take(2))
                      StudentPill(label: _tagLabel(tag), color: AppColors.cyan),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton({required this.columns});
  final int columns;

  @override
  Widget build(BuildContext context) {
    Widget block() => Container(
      height: 150,
      decoration: BoxDecoration(
        color: AdaptiveColors.line(context).withValues(alpha: .45),
        borderRadius: BorderRadius.circular(20),
      ),
    );
    return Semantics(
      label: AppLocalizations.of(context).loading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: _LessonGrid(
          columns: columns,
          children: [for (var i = 0; i < columns * 2; i++) block()],
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: StudentStyle.card(context),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 32, color: AdaptiveColors.muted(context)),
          const SizedBox(height: 10),
          Text(l10n.noLessonsMatch, textAlign: TextAlign.center, style: StudentStyle.body(context, size: 14)),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('lessons-clear-filters-button'),
            onPressed: onClear,
            child: Text(l10n.clearFilters),
          ),
        ],
      ),
    );
  }
}

class _NoPublishedLessons extends StatelessWidget {
  const _NoPublishedLessons({required this.onRetry, this.message, this.onAskTutor});
  final VoidCallback onRetry;
  final String? message;
  final ValueChanged<String?>? onAskTutor;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    Widget starter(String key, IconData icon, Color color, String label, String prompt) => ActionChip(
      key: Key(key),
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      onPressed: () => onAskTutor?.call(prompt),
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: StudentStyle.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.school_rounded, color: AppColors.cyan, size: 26),
          ),
          const SizedBox(height: 12),
          Text(loc.noLessonsAvailable, style: StudentStyle.title(context, 18)),
          const SizedBox(height: 6),
          Text(message ?? loc.emptyCatalogDescription, style: StudentStyle.body(context, size: 14)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const Key('empty-catalog-ask-tutor-button'),
                onPressed: () => onAskTutor?.call(''),
                icon: const Icon(Icons.psychology_rounded, size: 18),
                label: Text(loc.askTutorAQuestion),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: const Color(0xFF070B14),
                  minimumSize: const Size(0, 44),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              OutlinedButton(
                key: const Key('empty-catalog-retry-button'),
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                child: Text(loc.retry),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(loc.trySampleProblem, style: StudentStyle.body(context, size: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              starter('empty-starter-limits', Icons.functions_rounded, subjectVisual('math').color,
                  r'lim x→3 (x²-9)/(x-3)', r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}'),
              starter('empty-starter-physics', Icons.speed_rounded, subjectVisual('physics').color,
                  'v = u + at, u=0, a=2, t=5', 'v = u + at, u=0, a=2, t=5'),
              starter('empty-starter-chemistry', Icons.science_rounded, subjectVisual('chemistry').color,
                  '2H₂ + O₂ → 2H₂O', r'2H_2 + O_2 \to 2H_2O'),
            ],
          ),
        ],
      ),
    );
  }
}

/* ─── Detail ────────────────────────────────────────────────────────────── */

class _LessonDetail extends StatelessWidget {
  const _LessonDetail({
    required this.lesson,
    required this.onBack,
    required this.onStart,
    required this.onPractice,
    this.onAskTutor,
  });
  final StudentLesson lesson;
  final VoidCallback onBack;
  final VoidCallback onStart;
  final VoidCallback onPractice;
  final ValueChanged<String?>? onAskTutor;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final visual = subjectVisual(lesson.subject);
    final ready = lesson.isAvailable;
    final starter = lesson.starterProblem?.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 600 ? 28.0 : 16.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(loc.allLessons),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: StudentStyle.card(context, accent: visual.color).copyWith(
                      color: Color.alphaBlend(visual.color.withValues(alpha: .06), AdaptiveColors.card(context)),
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
                              child: Text(
                                '${loc.gradeLevel(lesson.grade)} · ${localizedSubjectName(loc, lesson.subject)}',
                                style: StudentStyle.body(context, size: 13, color: visual.color).copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            StudentPill(
                              icon: ready ? Icons.check_circle_rounded : Icons.schedule_rounded,
                              label: ready ? loc.topicReady : loc.lessonComingSoon,
                              color: ready ? const Color(0xFF10B981) : AdaptiveColors.muted(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(lesson.displayTitle, style: StudentStyle.title(context, 26)),
                        const SizedBox(height: 10),
                        if (lesson.khmerDescription != null && lesson.khmerDescription!.isNotEmpty) ...[
                          Text(
                            lesson.khmerDescription!,
                            style: StudentStyle.body(context, size: 15, color: AdaptiveColors.text(context)),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (lesson.description != null &&
                            lesson.description!.isNotEmpty &&
                            lesson.description != lesson.khmerDescription) ...[
                          Text(lesson.description!, style: StudentStyle.body(context, size: 14)),
                          const SizedBox(height: 6),
                        ],
                        if (lesson.languageMode != 'khmer') ...[
                          const SizedBox(height: 4),
                          Text(
                            '${loc.topicLabel}: ${lesson.topic}',
                            style: TextStyle(
                              color: AdaptiveColors.subtle(context),
                              fontWeight: FontWeight.w700,
                              fontFamilyFallback: AppTheme.fontFallback,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            StudentPill(label: _difficultyLabel(loc, lesson.difficulty), color: visual.color),
                            StudentPill(
                              icon: Icons.calculate_outlined,
                              label: loc.problemsCount(lesson.problemCount),
                              color: AdaptiveColors.muted(context),
                            ),
                            for (final tag in lesson.tags)
                              StudentPill(label: _tagLabel(tag), color: AppColors.cyan),
                          ],
                        ),
                        if (starter != null && starter.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AdaptiveColors.controlFill(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(loc.starterProblemLabel, style: StudentStyle.body(context, size: 11)),
                                const SizedBox(height: 4),
                                Text(
                                  starter,
                                  style: StudentStyle.body(context, size: 14, color: AdaptiveColors.text(context)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (ready)
                          _DetailActions(
                            practiceAvailable: lesson.practiceAvailable,
                            color: visual.color,
                            onStart: onStart,
                            onPractice: onPractice,
                          )
                        else
                          _ComingSoonPanel(
                            onAsk: () => onAskTutor != null ? onAskTutor!(lesson.topic) : onStart(),
                          ),
                      ],
                    ),
                  ),
                  if (ready) ...[
                    const SizedBox(height: 20),
                    Text(loc.howThisLessonWorks, style: StudentStyle.title(context, 17)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: StudentStyle.card(context),
                      child: Column(
                        children: [
                          _HowStep(number: 1, icon: Icons.draw_rounded, text: loc.lessonStepWatch, color: visual.color),
                          const SizedBox(height: 12),
                          _HowStep(number: 2, icon: Icons.forum_rounded, text: loc.lessonStepAsk, color: visual.color),
                          if (lesson.practiceAvailable) ...[
                            const SizedBox(height: 12),
                            _HowStep(number: 3, icon: Icons.task_alt_rounded, text: loc.lessonStepPractice, color: visual.color),
                          ],
                        ],
                      ),
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

class _DetailActions extends StatelessWidget {
  const _DetailActions({
    required this.practiceAvailable,
    required this.color,
    required this.onStart,
    required this.onPractice,
  });
  final bool practiceAvailable;
  final Color color;
  final VoidCallback onStart;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final start = FilledButton.icon(
      key: const Key('lesson-start-button'),
      onPressed: onStart,
      icon: const Icon(Icons.play_arrow_rounded),
      label: Text(loc.startWithTutor),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontFamilyFallback: AppTheme.fontFallback),
      ),
    );
    if (!practiceAvailable) return start;
    return Row(
      children: [
        Expanded(flex: 3, child: start),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            key: const Key('lesson-practice-button'),
            onPressed: onPractice,
            icon: const Icon(Icons.quiz_outlined),
            label: Text(loc.practice),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdaptiveColors.text(context),
              minimumSize: const Size(0, 48),
              side: BorderSide(color: AdaptiveColors.line(context)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
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

class _HowStep extends StatelessWidget {
  const _HowStep({required this.number, required this.icon, required this.text, required this.color});
  final int number;
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color.withValues(alpha: .14), shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: StudentStyle.body(context, size: 14, color: AdaptiveColors.text(context)))),
    ],
  );
}
