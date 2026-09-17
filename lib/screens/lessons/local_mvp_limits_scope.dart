/// The only curriculum context allowed by the local student MVP.
///
/// These identifiers are intentionally explicit: a new local draft must not
/// become student-accessible merely because its version starts with `local-`.
const localMvpGrade = 12;
const localMvpSubject = 'Mathematics';
const localMvpSubjectId = 'math';
const localMvpTopic = 'Limits of Functions';
const localMvpTopicId = 'math-g12-limits-of-functions';
const localMvpLessonId = 'math.g12.lesson1.limits-of-functions';
const localMvpCurriculumVersionId = 'local-g12-math-limits-2025-10-01-v1';
const localMvpTeachingMomentId =
    'math.g12.lesson1.limits-of-functions.finite-at-point.01';

bool isLocalMvpLimitsScope({
  required int grade,
  required String subject,
  required String topic,
  required String lessonId,
  required String curriculumVersionId,
  required String? teachingMomentId,
}) =>
    grade == localMvpGrade &&
    subject == localMvpSubject &&
    topic == localMvpTopic &&
    lessonId == localMvpLessonId &&
    curriculumVersionId == localMvpCurriculumVersionId &&
    teachingMomentId == localMvpTeachingMomentId;
