import 'package:flutter/material.dart';

import '../../core/adaptive_colors.dart';
import '../../core/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../features/visual_tutor/presentation/visual_tutor_design.dart';
import '../../features/visual_tutor/presentation/providers/step_board_provider.dart';
import '../../features/visual_tutor/presentation/widgets/rich_media_canvas.dart';
import '../../features/visual_tutor/presentation/widgets/step_interaction_widget.dart';
import '../../features/visual_tutor/presentation/widgets/step_progress_indicator.dart';
import '../../shared/language_switcher_button.dart';
import '../../shared/state_widgets/app_error_state.dart';
import '../../shared/student_design_system.dart';
import '../lessons/student_lessons_repository.dart';

/// The Tutor tab: the published curriculum, grouped by subject, where every
/// topic opens a whiteboard lesson. Asking a free-form question lives on Home;
/// this screen offers it only as a fallback when a topic is missing.
class VisualTutorHomeScreen extends StatefulWidget {
  const VisualTutorHomeScreen({
    super.key,
    required this.onOpenLesson,
    required this.onAskQuestion,
    this.repository,
    this.stepBoard,
  });

  /// Starts the whiteboard tutor on a curriculum topic.
  final ValueChanged<StudentLesson> onOpenLesson;

  /// Opens the tutor with an optional prefilled problem.
  final ValueChanged<String?> onAskQuestion;
  final StudentLessonsRepository? repository;

  /// When a confirmed expert lesson is active, this replaces the curriculum.
  final StepBoardProvider? stepBoard;

  @override
  State<VisualTutorHomeScreen> createState() => _VisualTutorHomeScreenState();
}

const _subjectOrder = ['math', 'physics', 'chemistry'];

int _subjectRank(StudentLesson lesson) {
  final key = '${lesson.subjectId} ${lesson.subject}'.toLowerCase();
  for (var i = 0; i < _subjectOrder.length; i++) {
    if (key.contains(_subjectOrder[i])) return i;
  }
  return _subjectOrder.length;
}

class _VisualTutorHomeScreenState extends State<VisualTutorHomeScreen> {
  late final StudentLessonsRepository _repository;
  late Future<List<StudentLesson>> _future;
  final _search = TextEditingController();
  int? _grade;
  String? _subjectId;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? buildDefaultStudentLessonsRepository();
    _future = _repository.loadLessons();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final next = _repository.loadLessons();
    setState(() => _future = next);
    await next;
  }

  List<StudentLesson> _filter(List<StudentLesson> lessons) {
    final query = _search.text.trim().toLowerCase();
    return lessons.where((lesson) {
      if (_grade != null && lesson.grade != _grade) return false;
      if (_subjectId != null && lesson.subjectId != _subjectId) return false;
      if (query.isEmpty) return true;
      return [
        lesson.title,
        lesson.englishTitle ?? '',
        lesson.topic,
        lesson.subject,
        lesson.description ?? '',
        ...lesson.tags,
      ].join(' ').toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stepBoard != null) return _StepTeachingHome(provider: widget.stepBoard!);
    final l10n = AppLocalizations.of(context);

    return KeyedSubtree(
      key: const Key('visual-tutor-home-screen'),
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<List<StudentLesson>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _CurriculumSkeleton();
            }
            if (snapshot.hasError) {
              // Keep the free-form tutor reachable even when the catalogue is down.
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
                children: [
                  AppErrorState(message: l10n.curriculumLoadError, onRetry: _reload),
                  const SizedBox(height: 8),
                  _AskOwnCard(onAsk: () => widget.onAskQuestion(null)),
                ],
              );
            }
            final all = snapshot.data ?? const <StudentLesson>[];
            final gradeScoped = _grade == null ? all : all.where((l) => l.grade == _grade).toList();
            final visible = _filter(all);
            return RefreshIndicator(
              onRefresh: _reload,
              color: AppColors.cyan,
              child: _CurriculumBody(
                all: all,
                gradeScoped: gradeScoped,
                visible: visible,
                search: _search,
                grade: _grade,
                subjectId: _subjectId,
                onGrade: (grade) => setState(() => _grade = grade),
                onSubject: (id) => setState(() => _subjectId = id),
                onOpenLesson: widget.onOpenLesson,
                onAskQuestion: widget.onAskQuestion,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CurriculumBody extends StatelessWidget {
  const _CurriculumBody({
    required this.all,
    required this.gradeScoped,
    required this.visible,
    required this.search,
    required this.grade,
    required this.subjectId,
    required this.onGrade,
    required this.onSubject,
    required this.onOpenLesson,
    required this.onAskQuestion,
  });
  final List<StudentLesson> all;
  final List<StudentLesson> gradeScoped;
  final List<StudentLesson> visible;
  final TextEditingController search;
  final int? grade;
  final String? subjectId;
  final ValueChanged<int?> onGrade;
  final ValueChanged<String?> onSubject;
  final ValueChanged<StudentLesson> onOpenLesson;
  final ValueChanged<String?> onAskQuestion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final grades = {for (final lesson in all) lesson.grade}.toList()..sort();

    // Subjects offered in the selected grade, in curriculum order.
    final subjects = <String, StudentLesson>{};
    for (final lesson in [...gradeScoped]..sort((a, b) => _subjectRank(a).compareTo(_subjectRank(b)))) {
      subjects.putIfAbsent(lesson.subjectId, () => lesson);
    }

    // Visible topics grouped by subject.
    final groups = <String, List<StudentLesson>>{};
    for (final lesson in [...visible]..sort((a, b) {
      final rank = _subjectRank(a).compareTo(_subjectRank(b));
      if (rank != 0) return rank;
      final byGrade = a.grade.compareTo(b.grade);
      return byGrade != 0 ? byGrade : a.displayTitle.compareTo(b.displayTitle);
    })) {
      groups.putIfAbsent(lesson.subjectId, () => []).add(lesson);
    }
    final readyCount = gradeScoped.where((lesson) => lesson.isAvailable).length;

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
          key: const Key('curriculum-scroll-view'),
          physics: const AlwaysScrollableScrollPhysics(),
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
                            Text(l10n.curriculumTitle, style: StudentStyle.title(context, 24)),
                            const SizedBox(height: 4),
                            Text(l10n.curriculumSubtitle, style: StudentStyle.body(context, size: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const LanguageSwitcherButton(compact: true),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SearchField(controller: search),
                  if (grades.length > 1) ...[
                    const SizedBox(height: 12),
                    _ChipRow(
                      children: [
                        StudentFilterChip(
                          key: const Key('curriculum-grade-all'),
                          label: l10n.allGrades,
                          selected: grade == null,
                          onTap: () => onGrade(null),
                        ),
                        for (final value in grades)
                          StudentFilterChip(
                            key: Key('curriculum-grade-$value'),
                            label: l10n.gradeLevel(value),
                            selected: grade == value,
                            onTap: () => onGrade(value),
                          ),
                      ],
                    ),
                  ],
                  if (subjects.length > 1) ...[
                    const SizedBox(height: 10),
                    _ChipRow(
                      children: [
                        StudentFilterChip(
                          key: const Key('curriculum-subject-all'),
                          label: l10n.allFilter,
                          count: gradeScoped.length,
                          selected: subjectId == null,
                          onTap: () => onSubject(null),
                        ),
                        for (final entry in subjects.entries)
                          StudentFilterChip(
                            key: Key('curriculum-subject-${entry.key}'),
                            label: localizedSubjectName(l10n, entry.value.subject),
                            icon: subjectVisual(entry.value.subject).icon,
                            color: subjectVisual(entry.value.subject).color,
                            count: gradeScoped.where((l) => l.subjectId == entry.key).length,
                            selected: subjectId == entry.key,
                            onTap: () => onSubject(subjectId == entry.key ? null : entry.key),
                          ),
                      ],
                    ),
                  ],
                  if (gradeScoped.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      '${l10n.topicsCount(gradeScoped.length)} · ${l10n.readyTopicsCount(readyCount)}',
                      style: StudentStyle.body(context, size: 12),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (all.isEmpty)
                    _EmptyNote(icon: Icons.menu_book_rounded, text: l10n.noLessonsAvailable)
                  else if (groups.isEmpty)
                    _EmptyNote(icon: Icons.search_off_rounded, text: l10n.noTopicsFound)
                  else
                    for (final entry in groups.entries) ...[
                      const SizedBox(height: 16),
                      _SubjectHeader(lesson: entry.value.first, count: entry.value.length),
                      const SizedBox(height: 10),
                      _TopicGrid(
                        columns: columns,
                        children: [
                          for (final lesson in entry.value)
                            _TopicCard(
                              lesson: lesson,
                              showGrade: grade == null && grades.length > 1,
                              fillHeight: columns > 1,
                              onTap: () => onOpenLesson(lesson),
                            ),
                        ],
                      ),
                    ],
                  const SizedBox(height: 28),
                  _AskOwnCard(onAsk: () => onAskQuestion(null)),
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
  const _SearchField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      key: const Key('curriculum-search-field'),
      controller: controller,
      textInputAction: TextInputAction.search,
      style: TextStyle(
        color: AdaptiveColors.text(context),
        fontSize: 15,
        fontFamilyFallback: AppTheme.fontFallback,
      ),
      decoration: InputDecoration(
        hintText: l10n.searchTopicsHint,
        hintStyle: StudentStyle.body(context, size: 14),
        prefixIcon: Icon(Icons.search_rounded, color: AdaptiveColors.muted(context)),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: l10n.close,
                icon: const Icon(Icons.close_rounded),
                onPressed: controller.clear,
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

/* ─── Topics ─────────────────────────────────────────────────────────────── */

class _SubjectHeader extends StatelessWidget {
  const _SubjectHeader({required this.lesson, required this.count});
  final StudentLesson lesson;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visual = subjectVisual(lesson.subject);
    return Semantics(
      header: true,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(visual.icon, color: visual.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(localizedSubjectName(l10n, lesson.subject), style: StudentStyle.title(context, 17)),
          ),
          Text(l10n.topicsCount(count), style: StudentStyle.body(context, size: 12)),
        ],
      ),
    );
  }
}

class _TopicGrid extends StatelessWidget {
  const _TopicGrid({required this.columns, required this.children});
  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            children[i],
          ],
        ],
      );
    }
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      final slice = children.sublist(start, (start + columns).clamp(0, children.length));
      rows.add(
        IntrinsicHeight(
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

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.lesson,
    required this.showGrade,
    required this.fillHeight,
    required this.onTap,
  });
  final StudentLesson lesson;
  final bool showGrade;

  /// In a multi-column row, push the footer down so cards line up.
  final bool fillHeight;
  final VoidCallback onTap;

  String _difficulty(AppLocalizations l10n) => switch (lesson.difficulty.toLowerCase()) {
    'beginner' || 'easy' => l10n.difficultyBeginner,
    'intermediate' || 'medium' => l10n.difficultyIntermediate,
    'advanced' || 'hard' => l10n.difficultyAdvanced,
    final other => other,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visual = subjectVisual(lesson.subject);
    final ready = lesson.isAvailable;
    final title = l10n.isKhmer || (lesson.englishTitle ?? '').isEmpty
        ? lesson.title
        : lesson.englishTitle!;
    final description = l10n.isKhmer
        ? (lesson.khmerDescription ?? lesson.description)
        : (lesson.description ?? lesson.khmerDescription);
    final starter = lesson.starterProblem?.trim();
    final statusColor = ready ? const Color(0xFF10B981) : AdaptiveColors.muted(context);

    return Semantics(
      button: true,
      label: '$title, ${ready ? l10n.topicReady : l10n.lessonComingSoon}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('curriculum-topic-${lesson.lessonId}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: StudentStyle.card(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StudentPill(
                      icon: ready ? Icons.check_circle_rounded : Icons.schedule_rounded,
                      label: ready ? l10n.topicReady : l10n.lessonComingSoon,
                      color: statusColor,
                    ),
                    StudentPill(label: _difficulty(l10n), color: visual.color),
                    if (showGrade)
                      StudentPill(label: l10n.gradeLevel(lesson.grade), color: AdaptiveColors.muted(context)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: StudentStyle.title(context, 16),
                ),
                if (description != null && description.trim().isNotEmpty && description != title) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: StudentStyle.body(context),
                  ),
                ],
                if (starter != null && starter.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AdaptiveColors.controlFill(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${l10n.starterProblemLabel}: $starter',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: StudentStyle.body(context, size: 12, color: AdaptiveColors.subtle(context)),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                if (fillHeight) const Spacer(),
                Row(
                  children: [
                    if (lesson.problemCount > 0)
                      Expanded(
                        child: Text(
                          l10n.problemsCount(lesson.problemCount),
                          style: StudentStyle.body(context, size: 12),
                        ),
                      )
                    else
                      const Spacer(),
                    Text(
                      l10n.learnThisTopic,
                      style: TextStyle(
                        color: visual.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFamilyFallback: AppTheme.fontFallback,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: visual.color),
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

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
    decoration: StudentStyle.card(context),
    child: Column(
      children: [
        Icon(icon, size: 32, color: AdaptiveColors.muted(context)),
        const SizedBox(height: 10),
        Text(text, textAlign: TextAlign.center, style: StudentStyle.body(context, size: 14)),
      ],
    ),
  );
}

class _AskOwnCard extends StatelessWidget {
  const _AskOwnCard({required this.onAsk});
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const Key('curriculum-ask-own-card'),
      padding: const EdgeInsets.all(16),
      decoration: StudentStyle.card(context, accent: AppColors.cyan),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.cantFindTopic, style: StudentStyle.title(context, 15)),
              const SizedBox(height: 2),
              Text(l10n.cantFindTopicDesc, style: StudentStyle.body(context, size: 12)),
            ],
          );
          final button = FilledButton.icon(
            key: const Key('curriculum-ask-own-button'),
            onPressed: onAsk,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: Text(l10n.askOwnProblem),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: const Color(0xFF071222),
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontFamilyFallback: AppTheme.fontFallback,
              ),
            ),
          );
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [text, const SizedBox(height: 12), button],
            );
          }
          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 16),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _CurriculumSkeleton extends StatelessWidget {
  const _CurriculumSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double height, {double? width, double radius = 16}) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AdaptiveColors.line(context).withValues(alpha: .45),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    return Semantics(
      label: AppLocalizations.of(context).loading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            block(26, width: 180, radius: 8),
            const SizedBox(height: 8),
            block(14, width: 280, radius: 6),
            const SizedBox(height: 18),
            block(50, radius: 14),
            const SizedBox(height: 12),
            block(40, width: 260, radius: 20),
            const SizedBox(height: 24),
            for (var i = 0; i < 3; i++) ...[block(150, radius: 20), const SizedBox(height: 10)],
          ],
        ),
      ),
    );
  }
}

class _StepTeachingHome extends StatelessWidget {
  const _StepTeachingHome({required this.provider});
  final StepBoardProvider provider;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: provider,
    builder: (context, _) {
      final step = provider.currentStep;
      if (step == null) return const Center(child: CircularProgressIndicator());
      final objective =
          step.content['learning_objective'] as String? ??
          step.visualizationType.replaceAll('_', ' ');
      final feedback =
          provider.response?.evaluation?['feedback_message'] as String?;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StepProgressIndicator(
                currentStep: provider.currentStepNumber,
                totalSteps: provider.totalSteps,
                learningObjective: objective,
              ),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: SizedBox(
                  key: ValueKey(step.stepId),
                  height: 350,
                  child: RichMediaCanvas(
                    mediaChildren: [
                      Center(
                        child: _VisualizationCaption(
                          stepType: step.visualizationType,
                          content: step.content,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              StepInteractionWidget(
                responseType: step.expectedResponseType,
                question:
                    '${step.studentQuestion}\n${step.studentQuestionKhmer}',
                choices: _choices(step.content),
                isLoading: provider.isLoading,
                feedback: feedback ?? provider.error,
                onSubmit: provider.submit,
                onHint: provider.requestHint,
                onSkip: provider.skip,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _VisualizationCaption extends StatelessWidget {
  const _VisualizationCaption({required this.stepType, required this.content});
  final String stepType;
  final Map<String, dynamic> content;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_iconFor(stepType), size: 56, color: VisualTutorColors.cyan),
        const SizedBox(height: 12),
        Text(
          stepType.replaceAll('_', ' '),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (content['equation'] is String) Text(content['equation'] as String),
      ],
    ),
  );
}

IconData _iconFor(String type) => switch (type) {
  'free_body_diagram' || 'vector_analysis' => Icons.arrow_outward_rounded,
  'motion_graphs' || 'graph' => Icons.show_chart_rounded,
  'molecule' || 'molecular_structure' => Icons.hub_rounded,
  'geometry' => Icons.change_history_rounded,
  _ => Icons.auto_awesome_rounded,
};

List<String> _choices(Map<String, dynamic> content) =>
    (content['choices'] as List? ?? const []).whereType<String>().toList(
      growable: false,
    );

