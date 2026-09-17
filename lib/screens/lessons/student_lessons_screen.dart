import 'package:flutter/material.dart';

import '../../core/adaptive_colors.dart';
import '../../core/app_colors.dart';
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
  });
  final ValueChanged<StudentLesson> onOpenLesson;
  final ValueChanged<StudentLesson> onPractice;
  final StudentLessonsRepository? repository;
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
            const StudentSectionTitle('Lessons'),
            const SizedBox(height: StudentSpace.xs),
            Text(
              _repository is LocalDemoStudentLessonsRepository
                  ? 'Choose the local curriculum demo and learn with the visual tutor.'
                  : 'Choose a published lesson, learn with the visual tutor, then practise.',
              style: TextStyle(color: Color(0xFFB4BEF2), fontSize: 16),
            ),
            const SizedBox(height: StudentSpace.lg),
            TextField(
              key: const Key('lessons-search-field'),
              controller: _search,
              onSubmitted: (_) => _reload(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search lessons or topics',
                suffixIcon: IconButton(
                  tooltip: 'Search lessons',
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
                    label: const Text('All subjects'),
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
                message: _repository is LocalDemoStudentLessonsRepository
                    ? localMvpUnsupportedRecoveryMessage
                    : null,
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 820 ? 2 : 1;
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
  const _NoPublishedLessons({required this.onRetry, this.message});
  final VoidCallback onRetry;
  final String? message;
  @override
  Widget build(BuildContext context) => StudentCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.menu_book_outlined, color: AppColors.cyan, size: 40),
        const SizedBox(height: 12),
        Text(
          'No lessons are available yet',
          style: TextStyle(
            color: AdaptiveColors.text(context),
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message ??
              'Your school has not published a lesson for this selection. Try again later or ask your tutor a question.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
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
          label: const Text('All lessons'),
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
                        label: const Text('Start with Tutor'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onPractice,
                        icon: const Icon(Icons.quiz_outlined),
                        label: const Text('Practice'),
                      ),
                    ),
                  ],
                )
              else
                FilledButton.icon(
                  key: const Key('lesson-start-button'),
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start with Tutor'),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
