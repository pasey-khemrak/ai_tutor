import '../../core/auth/auth_service.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';

class StudentProfileSetup {
  const StudentProfileSetup({
    required this.gradeLevelId,
    required this.subjectIds,
    required this.preferredLanguage,
    this.displayName,
  });
  final String gradeLevelId;
  final List<String> subjectIds;
  final String preferredLanguage;
  final String? displayName;
}

class CatalogGrade {
  const CatalogGrade({required this.gradeLevelId, required this.gradeName});
  final String gradeLevelId;
  final String gradeName;
}

class CatalogSubject {
  const CatalogSubject({required this.subjectId, required this.subjectName});
  final String subjectId;
  final String subjectName;
}

class StudentProfileRepository {
  StudentProfileRepository({ApiClient? apiClient})
    : _client =
          apiClient ??
          ApiClient(
            config: AppConfig.current,
            tokenProvider: appAuthService.getAccessToken,
          );
  final ApiClient _client;

  /// The full set of grades/subjects Rean supports, independent of which
  /// grades currently have a published lesson -- the scope-locked dynamic
  /// tutor (e.g. Grade 12 Limits of Functions) is never published as a
  /// catalog lesson by design, so this must not be derived from lessons.
  Future<List<CatalogGrade>> loadGrades() async {
    final response = await _client.get('/catalog/grades');
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => CatalogGrade(
            gradeLevelId: (item['grade_level_id'] as String? ?? '').trim(),
            gradeName: (item['grade_name'] as String? ?? '').trim(),
          ),
        )
        .where((grade) => grade.gradeLevelId.isNotEmpty)
        .toList();
  }

  Future<List<CatalogSubject>> loadSubjects() async {
    final response = await _client.get('/catalog/subjects');
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => CatalogSubject(
            subjectId: (item['subject_id'] as String? ?? '').trim(),
            subjectName: (item['subject_name'] as String? ?? '').trim(),
          ),
        )
        .where((subject) => subject.subjectId.isNotEmpty)
        .toList();
  }

  Future<StudentProfileView> loadProfile() async {
    final response = await _client.get('/profile');
    final data = response['data'];
    final object = data is Map<String, dynamic> ? data : response;
    final profile = object['student_profile'] is Map<String, dynamic>
        ? object['student_profile'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final user = object['user'] is Map<String, dynamic>
        ? object['user'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final selected = object['student_subjects'];
    final subjects = selected is List
        ? selected
              .whereType<Map<String, dynamic>>()
              .map((item) {
                final subject = item['subject'];
                return subject is Map<String, dynamic>
                    ? (subject['subject_name'] as String? ?? '').trim()
                    : '';
              })
              .where((value) => value.isNotEmpty)
              .toList()
        : const <String>[];
    return StudentProfileView(
      displayName:
          (profile['display_name'] as String?)?.trim().isNotEmpty == true
          ? (profile['display_name'] as String).trim()
          : ((user['full_name'] as String?)?.trim() ?? ''),
      gradeLevelId: (profile['grade_level_id'] as String?)?.trim() ?? '',
      preferredLanguage:
          (user['preferred_language'] as String?)?.trim() ?? 'en',
      subjects: subjects,
    );
  }

  /// First-time setup is one authenticated, backend-validated profile write.
  /// It never writes a user id from the client or stores a local fake profile.
  Future<void> completeSetup(StudentProfileSetup setup) async {
    await _client.post(
      '/profile',
      body: {
        'grade_level_id': setup.gradeLevelId,
        'subject_ids': setup.subjectIds,
        'preferred_language': setup.preferredLanguage,
        if (setup.displayName != null && setup.displayName!.trim().isNotEmpty)
          'display_name': setup.displayName!.trim(),
        'explanation_level': 'intermediate',
        'learning_goal':
            'Build confidence through visual, step-by-step practice.',
      },
    );
  }
}

class StudentProfileView {
  const StudentProfileView({
    required this.displayName,
    required this.gradeLevelId,
    required this.preferredLanguage,
    required this.subjects,
  });
  final String displayName;
  final String gradeLevelId;
  final String preferredLanguage;
  final List<String> subjects;
  bool get isComplete => gradeLevelId.isNotEmpty && subjects.isNotEmpty;
}
