import '../../core/config/app_config.dart';

class LearningContext {
  const LearningContext({
    required this.grade,
    required this.subject,
    required this.topic,
  });

  final int grade;
  final String subject;
  final String topic;

  String get gradeLabel => 'Grade $grade';
}

class LearningSubject {
  const LearningSubject({required this.name, required this.topics});

  final String name;
  final List<String> topics;
}

class LearningSelectionData {
  const LearningSelectionData({required this.grades, required this.subjects});

  final List<int> grades;
  final List<LearningSubject> subjects;

  bool get isEmpty => grades.isEmpty || subjects.isEmpty;
}

abstract class LearningSelectionRepository {
  Future<LearningSelectionData> loadSelectionData();
}

class MockLearningSelectionRepository implements LearningSelectionRepository {
  const MockLearningSelectionRepository({
    this.delay = const Duration(milliseconds: 180),
    this.data = demoLearningSelectionData,
  });

  final Duration delay;
  final LearningSelectionData data;

  @override
  Future<LearningSelectionData> loadSelectionData() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return data;
  }
}

class EmptyLearningSelectionRepository implements LearningSelectionRepository {
  const EmptyLearningSelectionRepository();

  @override
  Future<LearningSelectionData> loadSelectionData() async =>
      const LearningSelectionData(grades: [], subjects: []);
}

LearningSelectionRepository buildDefaultLearningSelectionRepository() {
  // There is no production remote source for this legacy screen yet. Do not
  // silently show a Grade-10 Mathematics demo outside explicit local demo mode.
  return AppConfig.current.shouldUseDemoTutorData
      ? const MockLearningSelectionRepository()
      : const EmptyLearningSelectionRepository();
}

class ErrorLearningSelectionRepository implements LearningSelectionRepository {
  const ErrorLearningSelectionRepository();

  @override
  Future<LearningSelectionData> loadSelectionData() async {
    throw StateError('Learning selection unavailable');
  }
}

const demoLearningSelectionData = LearningSelectionData(
  grades: [10, 11, 12],
  subjects: [
    LearningSubject(
      name: 'Mathematics',
      topics: [
        'Linear Equations',
        'Coordinate Plane',
        'Slope',
        'Equation of a Line',
        'Functions',
        'Quadratic Functions',
      ],
    ),
  ],
);
