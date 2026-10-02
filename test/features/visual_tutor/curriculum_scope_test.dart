import 'package:flutter_test/flutter_test.dart';
import 'package:ai_tutor/screens/lessons/local_mvp_limits_scope.dart';

void main() {
  group('Grade 12 STEM Scope (Client)', () {
    test('Grade 12 Mathematics, Physics, and Chemistry are in scope', () {
      expect(isGrade12StemScope(grade: 12, subject: 'Mathematics'), isTrue);
      expect(isGrade12StemScope(grade: 12, subject: 'math'), isTrue);
      expect(isGrade12StemScope(grade: 12, subject: 'គណិតវិទ្យា'), isTrue);

      expect(isGrade12StemScope(grade: 12, subject: 'Physics'), isTrue);
      expect(isGrade12StemScope(grade: 12, subject: 'physics'), isTrue);
      expect(isGrade12StemScope(grade: 12, subject: 'រូបវិទ្យា'), isTrue);

      expect(isGrade12StemScope(grade: 12, subject: 'Chemistry'), isTrue);
      expect(isGrade12StemScope(grade: 12, subject: 'chemistry'), isTrue);
      expect(isGrade12StemScope(grade: 12, subject: 'គីមីវិទ្យា'), isTrue);
    });

    test('Other grades or non-STEM subjects are rejected', () {
      expect(isGrade12StemScope(grade: 10, subject: 'Mathematics'), isFalse);
      expect(isGrade12StemScope(grade: 11, subject: 'Physics'), isFalse);
      expect(isGrade12StemScope(grade: 10, subject: 'Chemistry'), isFalse);

      expect(isGrade12StemScope(grade: 12, subject: 'Biology'), isFalse);
      expect(isGrade12StemScope(grade: 12, subject: 'History'), isFalse);
      expect(isGrade12StemScope(grade: 12, subject: 'English'), isFalse);
    });

    test('Supported languages include English, Khmer, Bilingual', () {
      expect(supportedLanguageModes.contains('english'), isTrue);
      expect(supportedLanguageModes.contains('khmer'), isTrue);
      expect(supportedLanguageModes.contains('bilingual'), isTrue);
    });
  });
}
