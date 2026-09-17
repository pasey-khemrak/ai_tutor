import 'package:flutter/material.dart';

import '../../core/adaptive_colors.dart';
import '../../core/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/responsive/app_breakpoints.dart';
import '../../shared/state_widgets/app_error_state.dart';
import '../../shared/state_widgets/app_loading_state.dart';
import '../../shared/student_design_system.dart';
import 'student_lessons_repository.dart';

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
  StudentLesson? _selected;
  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? buildDefaultStudentLessonsRepository();
    _future = _repository.loadLessons();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _repository.loadLessons(
        search: _search.text,
        subjectId: _subjectId,
      );
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<StudentLesson>>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const AppLoadingState(message: 'Loading published lessons...');
      }
      if (snapshot.hasError) {
        return AppErrorState(
          message:
              'Could not load lessons. Check your connection and try again.',
          onRetry: _reload,
        );
      }
      final lessons = snapshot.data ?? const <StudentLesson>[];
      if (_selected != null) {
        return _LessonDetail(
          lesson: _selected!,
          onBack: () => setState(() => _selected = null),
          onStart: () => widget.onOpenLesson(_selected!),
          onPractice: () => widget.onPractice(_selected!),
        );
      }
      final subjects = <String, String>{
        for (final lesson in lessons) lesson.subjectId: lesson.subject,
      };
      return StudentPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StudentSectionTitle(AppLocalizations.of(context).navLessons),
            const SizedBox(height: StudentSpace.xs),
            Text(
              _repository is LocalDemoStudentLessonsRepository
                  ? 'Choose the local curriculum demo and learn with the visual tutor.'
                  : AppLocalizations.of(context).publishedLessonsSubtitle,
              style: const TextStyle(color: Color(0xFFB4BEF2), fontSize: 16),
            ),
            const SizedBox(height: StudentSpace.lg),
            TextField(
              key: const Key('lessons-search-field'),
              controller: _search,
              onSubmitted: (_) => _reload(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: AppLocalizations.of(context).searchLessonsHint,
                suffixIcon: IconButton(
                  tooltip: AppLocalizations.of(context).searchLessonsHint,
                  onPressed: _reload,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
            const SizedBox(height: StudentSpace.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(AppLocalizations.of(context).allSubjects),
                    selected: _subjectId == null,
                    onSelected: (_) {
                      setState(() => _subjectId = null);
                      _reload();
                    },
                  ),
                  ...subjects.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: _subjectId == entry.key,
                        onSelected: (_) {
                          setState(() => _subjectId = entry.key);
                          _reload();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: StudentSpace.lg),
            if (lessons.isEmpty)
              _NoPublishedLessons(
                onRetry: _reload,
                onAskTutor: widget.onAskTutor,
                message: _repository is LocalDemoStudentLessonsRepository
                    ? localMvpUnsupportedRecoveryMessage
                    : null,
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      AppBreakpoints.isPhoneWidth(constraints.maxWidth) ? 1 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      childAspectRatio: columns == 1 ? 2.75 : 2.15,
                      crossAxisSpacing: StudentSpace.md,
                      mainAxisSpacing: StudentSpace.md,
                    ),
                    itemCount: lessons.length,
                    itemBuilder: (_, index) => _LessonCard(
                      lesson: lessons[index],
                      onTap: () => setState(() => _selected = lessons[index]),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    },
  );
}

class _NoPublishedLessons extends StatelessWidget {
  const _NoPublishedLessons({
    required this.onRetry,
    this.message,
    this.onAskTutor,
  });
  final VoidCallback onRetry;
  final String? message;
  final ValueChanged<String?>? onAskTutor;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return StudentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.school_rounded, color: AppColors.cyan, size: 40),
          const SizedBox(height: 12),
          Text(
            loc.noLessonsAvailable,
            style: TextStyle(
              color: AdaptiveColors.text(context),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message ?? loc.emptyCatalogDescription,
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              OutlinedButton(
                key: const Key('empty-catalog-retry-button'),
                onPressed: onRetry,
                child: Text(loc.retry),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            loc.trySampleProblem,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                key: const Key('empty-starter-limits'),
                avatar: const Text('📐'),
                label: const Text(r'lim x→3 (x²-9)/(x-3)'),
                onPressed: () => onAskTutor?.call(r'\lim_{x \to 3} \frac{x^2 - 9}{x - 3}'),
              ),
              ActionChip(
                key: const Key('empty-starter-physics'),
                avatar: const Text('⚡'),
                label: const Text('v = u + at, u=0, a=2, t=5'),
                onPressed: () => onAskTutor?.call('v = u + at, u=0, a=2, t=5'),
              ),
              ActionChip(
                key: const Key('empty-starter-chemistry'),
                avatar: const Text('🧪'),
                label: const Text('2H₂ + O₂ → 2H₂O'),
                onPressed: () => onAskTutor?.call(r'2H_2 + O_2 \to 2H_2O'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.onTap});
  final StudentLesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Open ${lesson.title}',
    child: StudentCard(
      child: InkWell(
        key: Key('lesson-card-${lesson.lessonId}'),
        onTap: onTap,
        borderRadius: StudentRadius.card,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: .12),
                  borderRadius: StudentRadius.control,
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: AppColors.cyan,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AdaptiveColors.text(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.languageMode == 'khmer'
                          ? 'Grade ${lesson.grade} • ${lesson.subject}'
                          : 'Grade ${lesson.grade} • ${lesson.subject} • ${lesson.topic}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFB4BEF2),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LessonDetail extends StatelessWidget {
  const _LessonDetail({
    required this.lesson,
    required this.onBack,
    required this.onStart,
    required this.onPractice,
  });
  final StudentLesson lesson;
  final VoidCallback onBack;
  final VoidCallback onStart;
  final VoidCallback onPractice;
  @override
  Widget build(BuildContext context) => StudentPage(
    maxWidth: StudentSpace.readableWidth,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          label: Text(AppLocalizations.of(context).allLessons),
        ),
        const SizedBox(height: StudentSpace.md),
        StudentCard(
          accent: AppColors.cyan,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Grade ${lesson.grade} • ${lesson.subject}',
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                lesson.displayTitle,
                style: TextStyle(
                  color: AdaptiveColors.text(context),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              if (lesson.displayDescription case final description?) ...[
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFB4BEF2),
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (lesson.languageMode != 'khmer') ...[
                Text(
                  'Topic: ${lesson.topic}',
                  style: TextStyle(
                    color: AdaptiveColors.text(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 20),
              if (lesson.practiceAvailable)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('lesson-start-button'),
                        onPressed: onStart,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(AppLocalizations.of(context).startWithTutor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onPractice,
                        icon: const Icon(Icons.quiz_outlined),
                        label: Text(AppLocalizations.of(context).practice),
                      ),
                    ),
                  ],
                )
              else
                FilledButton.icon(
                  key: const Key('lesson-start-button'),
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(AppLocalizations.of(context).startWithTutor),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
