import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('km'), Locale('en')];

  static AppLocalizations of(BuildContext context) {
    final localization =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (localization != null) return localization;
    final locale = Localizations.maybeLocaleOf(context);
    if (locale != null) {
      return AppLocalizations(locale);
    }
    return const AppLocalizations(Locale('km'));
  }

  bool get isKhmer => locale.languageCode == 'km';

  static String _toKhmerDigits(int number) {
    const khmerDigits = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
    return number.toString().split('').map((char) {
      final digit = int.tryParse(char);
      return digit != null ? khmerDigits[digit] : char;
    }).join();
  }

  // ── Core & Shared Actions ──────────────────────────────────────────────────
  String get appName => 'Rean AI';
  String get loading => isKhmer ? 'កំពុងផ្ទុក...' : 'Loading...';
  String get retry => isKhmer ? 'សាកល្បងម្តងទៀត' : 'Retry';
  String get emptyStateTitle => isKhmer ? 'មិនទាន់មានទិន្នន័យ' : 'Nothing here yet';
  String get cancel => isKhmer ? 'បោះបង់' : 'Cancel';
  String get save => isKhmer ? 'រក្សាទុក' : 'Save';
  String get close => isKhmer ? 'បិទ' : 'Close';
  String get next => isKhmer ? 'បន្ទាប់' : 'Next';
  String get back => isKhmer ? 'ត្រឡប់ក្រោយ' : 'Back';
  String get submit => isKhmer ? 'បញ្ជូន' : 'Submit';
  String get skip => isKhmer ? 'រំលង' : 'Skip';
  String get hint => isKhmer ? 'ជំនួយ' : 'Hint';
  String get explain => isKhmer ? 'ពន្យល់' : 'Explain';
  String get done => isKhmer ? 'រួចរាល់' : 'Done';
  String get edit => isKhmer ? 'កែសម្រួល' : 'Edit';

  // ── Auth Flow ──────────────────────────────────────────────────────────────
  String get welcomeBack =>
      isKhmer ? 'ស្វាគមន៍ការត្រឡប់មកវិញ!' : 'Welcome Back!';
  String get signInToContinue => isKhmer
      ? 'ចូលគណនីដើម្បីបន្តការរៀនរបស់អ្នក'
      : 'Sign in to continue your learning journey';
  String get createAccount => isKhmer ? 'បង្កើតគណនី' : 'Create Account';
  String get signIn => isKhmer ? 'ចូលគណនី' : 'Sign In';
  String get signUp => isKhmer ? 'ចុះឈ្មោះ' : 'Sign Up';
  String get pleaseWait => isKhmer ? 'សូមរង់ចាំ...' : 'Please wait...';
  String get email => isKhmer ? 'អ៊ីមែល' : 'Email';
  String get password => isKhmer ? 'ពាក្យសម្ងាត់' : 'Password';
  String get fullName => isKhmer ? 'ឈ្មោះពេញ' : 'Full Name';
  String get forgotPassword =>
      isKhmer ? 'ភ្លេចពាក្យសម្ងាត់?' : 'Forgot password?';
  String get resetPassword =>
      isKhmer ? 'កំណត់ពាក្យសម្ងាត់ឡើងវិញ' : 'Reset Password';
  String get getStarted => isKhmer ? 'ចាប់ផ្តើម' : 'Get Started';
  String get orContinueWithGoogle =>
      isKhmer ? 'ឬបន្តជាមួយ Google' : 'Or continue with Google';
  String get logout => isKhmer ? 'ចាកចេញពីគណនី' : 'Logout';

  // ── Navigation Tabs ────────────────────────────────────────────────────────
  String get navHome => isKhmer ? 'ទំព័រដើម' : 'Home';
  String get navTutor => isKhmer ? 'គ្រូបង្រៀន' : 'Tutor';
  String get navVoice => isKhmer ? 'សំឡេង' : 'Voice';
  String get navLessons => isKhmer ? 'មេរៀន' : 'Lessons';
  String get navQuizzes => isKhmer ? 'លំហាត់' : 'Quizzes';
  String get navProfile => isKhmer ? 'គណនី' : 'Profile';

  // ── Dashboard ──────────────────────────────────────────────────────────────
  String get welcomeLearner => isKhmer ? 'ស្វាគមន៍ 👋' : 'Welcome 👋';
  String helloUser(String name) =>
      isKhmer ? 'សួស្តី $name 👋' : 'Hello, $name 👋';
  String get readyToLearn =>
      isKhmer ? 'ត្រៀមខ្លួនរៀនហើយឬនៅ?' : 'Ready to learn?';
  String get completeProfile =>
      isKhmer ? 'បំពេញព័ត៌មានការរៀនរបស់អ្នក' : 'Complete your learning profile';
  String get setUpLearningPath =>
      isKhmer ? 'ចូររៀបចំផែនការរៀនរបស់អ្នក។' : 'Let’s set up your learning path.';
  String get continueLearning => isKhmer ? 'បន្តការរៀន' : 'Continue Learning';
  String get yourProgress => isKhmer ? 'វឌ្ឍនភាពរបស់អ្នក' : 'Your progress';
  String get dailyPractice =>
      isKhmer ? 'ការអនុវត្តប្រចាំថ្ងៃ' : 'Daily Practice';
  String get startChallenge =>
      isKhmer ? 'ចាប់ផ្តើមលំហាត់' : 'Start Challenge';
  String get typeYourQuestionHint =>
      isKhmer ? 'សរសេរសំណួររបស់អ្នក…' : 'Type your question…';

  // ── Visual Tutor Landing & Header ──────────────────────────────────────────
  String get visualTutorHeader =>
      isKhmer ? 'Rean AI គ្រូបង្រៀនរូបភាព' : 'Rean AI Visual Tutor';
  String get tutorPresenceTitle =>
      isKhmer ? 'Rean AI គ្រូបង្រៀន' : 'Rean AI Tutor';
  String get typeQuestionTitle =>
      isKhmer ? 'សរសេរសំណួរ' : 'Type a Question';
  String get typeQuestionSubtitle =>
      isKhmer ? 'សរសេរសំណួររបស់អ្នក' : 'Type your question';
  String get voiceInputTitle =>
      isKhmer ? 'បញ្ចូលសំឡេង' : 'Voice Input';
  String get voiceInputSubtitle =>
      isKhmer ? 'ប្រើសំឡេងដើម្បីសួរ' : 'Voice Input';
  String get imStuckTitle =>
      isKhmer ? 'ខ្ញុំទាល់គំនិតហើយ!' : "I'm Stuck!";
  String get imStuckSubtitle => isKhmer
      ? 'ទទួលបានការពន្យល់ជំហានម្តងៗភ្លាមៗលើមេរៀនបច្ចុប្បន្នរបស់អ្នក។'
      : 'Get immediate step-by-step guidance on your current lesson.';
  String get startLiveHelp =>
      isKhmer ? 'ចាប់ផ្តើមជំនួយផ្ទាល់' : 'Start Live Help';
  String get howCanIHelpToday =>
      isKhmer ? 'តើខ្ញុំអាចជួយអ្នក\nបានយ៉ាងដូចម្តេច?' : 'How can I help you\ntoday?';
  String get howCanIHelpTodaySub =>
      isKhmer ? 'សួរសំណួរគណិតវិទ្យា រូបវិទ្យា ឬគីមីវិទ្យា' : 'Ask any maths, physics, or chemistry problem';
  String get askAnyQuestionHint =>
      isKhmer ? 'សួរសំណួរទៅកាន់ Rean...' : 'Ask Rean any question!';

  // ── Tutor Status & Actions ─────────────────────────────────────────────────
  String get statusWriting => isKhmer ? 'កំពុងសរសេរ...' : 'Writing...';
  String get statusExplaining => isKhmer ? 'កំពុងពន្យល់...' : 'Explaining...';
  String get statusThinking => isKhmer ? 'កំពុងគិត...' : 'Thinking...';
  String get statusChecking => isKhmer ? 'កំពុងពិនិត្យ...' : 'Checking...';
  String get statusListening => isKhmer ? 'កំពុងស្តាប់...' : 'Listening...';
  String get statusWaiting => isKhmer ? 'រង់ចាំអ្នក' : 'Waiting for you';
  String get reviewPrevious =>
      isKhmer ? 'ពិនិត្យជំហានមុន' : 'Review previous';
  String get jumpToLatest =>
      isKhmer ? 'ទៅកាន់ចុងក្រោយ' : 'Jump to latest';
  String get resumeTask => isKhmer ? 'បន្តកិច្ចការ' : 'Resume task';

  // ── Whiteboard Pagination ──────────────────────────────────────────────────
  String boardPageOf(int current, int total) => isKhmer
      ? 'ក្តារទី ${_toKhmerDigits(current)} នៃ ${_toKhmerDigits(total)}'
      : 'Board $current of $total';
  String get previousBoard => isKhmer ? 'ក្តារមុន' : 'Previous board';
  String get nextBoard => isKhmer ? 'ក្តារបន្ទាប់' : 'Next board';

  // ── Follow-up & Feedback ───────────────────────────────────────────────────
  String get tryAgain => isKhmer ? 'សាកល្បងម្តងទៀត' : 'Try again';
  String get showMeWhy => isKhmer ? 'បង្ហាញហេតុផល' : 'Show me why';
  String get nextPracticeProblem =>
      isKhmer ? 'លំហាត់អនុវត្តបន្ទាប់  →' : 'Next Practice Problem  →';
  String get backToHome => isKhmer ? 'ត្រឡប់ទៅទំព័រដើម' : 'Back to Home';
  String get tryAnotherProblem =>
      isKhmer ? 'សាកល្បងលំហាត់ផ្សេង' : 'Try Another Problem';
  String get contactSupport => isKhmer ? 'ទាក់ទងជំនួយ' : 'Contact Support';
  String get conversationHistory =>
      isKhmer ? 'ប្រវត្តិសន្ទនា' : 'Conversation history';
  String get tutorMenu => isKhmer ? 'ម៉ឺនុយគ្រូ' : 'Tutor menu';
  String get explainDifferently =>
      isKhmer ? 'ពន្យល់តាមរបៀបផ្សេង' : 'Explain differently';

  // ── Lessons Catalog & Subjects ─────────────────────────────────────────────
  String get allSubjects => isKhmer ? 'គ្រប់មុខវិជ្ជា' : 'All subjects';
  String get allLessons => isKhmer ? 'គ្រប់មេរៀន' : 'All lessons';
  String get searchLessonsHint =>
      isKhmer ? 'ស្វែងរកមេរៀន ឬប្រធានបទ' : 'Search lessons or topics';
  String get startWithTutor => isKhmer ? 'រៀនជាមួយគ្រូ' : 'Start with Tutor';
  String get practice => isKhmer ? 'អនុវត្ត' : 'Practice';
  String get noLessonsAvailable =>
      isKhmer ? 'មិនទាន់មានមេរៀននៅឡើយទេ' : 'No lessons are available yet';
  String get publishedLessonsSubtitle => isKhmer
      ? 'ជ្រើសរើសមេរៀនដែលបានចេញផ្សាយ រៀនជាមួយគ្រូ AI រួចអនុវត្តលំហាត់។'
      : 'Choose a published lesson, learn with the visual tutor, then practise.';
  String get subjectMath => isKhmer ? 'គណិតវិទ្យា' : 'Mathematics';
  String get subjectPhysics => isKhmer ? 'រូបវិទ្យា' : 'Physics';
  String get subjectChemistry => isKhmer ? 'គីមីវិទ្យា' : 'Chemistry';
  String gradeLevel(int grade) => isKhmer ? 'ថ្នាក់ទី $grade' : 'Grade $grade';

  String get reportExplanation =>
      isKhmer ? 'រាយការណ៍ការពន្យល់' : 'Report explanation';
  String get cancelRecording =>
      isKhmer ? 'បោះបង់ការថតសំឡេង' : 'Cancel recording';
  String get repeat => isKhmer ? 'សារឡើងវិញ' : 'Repeat';
  String get showSummary =>
      isKhmer ? 'បង្ហាញសេចក្តីសង្ខេប' : 'Show Summary';
  String get replayBoard =>
      isKhmer ? 'ចាក់ឡើងវិញផ្ទាំងក្តារ' : 'Replay board timeline';
  String get jumpToCurrentStep =>
      isKhmer ? 'ទៅកាន់ជំហានបច្ចុប្បន្ន' : 'Jump to current teaching step';
  String get resetBoardView =>
      isKhmer ? 'កំណត់ទិដ្ឋភាពក្តារឡើងវិញ' : 'Reset board view';
  String get drawOnBoard => isKhmer ? 'គូរលើក្តារ' : 'Draw on board';
  String get stopDrawing => isKhmer ? 'ឈប់គូរ' : 'Stop drawing';
  String get eraseInk => isKhmer ? 'លុបគំនូរ' : 'Erase ink stroke';
  String get stopErasing => isKhmer ? 'ឈប់លុប' : 'Stop erasing';
  String get undoInk => isKhmer ? 'មិនធ្វើវិញ' : 'Undo ink';
  String get redoInk => isKhmer ? 'ធ្វើឡើងវិញ' : 'Redo ink';
  String get clearInk => isKhmer ? 'លុបគំនូរទាំងអស់' : 'Clear student ink';
  String get playBoardTimeline =>
      isKhmer ? 'ចាក់ចលនាក្តារ' : 'Play board timeline';
  String get pauseBoardTimeline =>
      isKhmer ? 'ផ្អាកចលនាក្តារ' : 'Pause board timeline';
  String get guidedMode => isKhmer ? 'ទម្រង់ណែនាំ' : 'guided mode';
  String get answerReady => isKhmer ? 'ចម្លើយរួចរាល់' : 'answer ready';
  String get closeHistory => isKhmer ? 'បិទប្រវត្តិ' : 'Close history';
  String get noConversationYet =>
      isKhmer ? 'មិនទាន់មានការសន្ទនានៅឡើយទេ។' : 'No conversation yet.';
  String get closeKeyboard => isKhmer ? 'បិទក្តារចុច' : 'Close keyboard';
  String get openKeyboard => isKhmer ? 'បើកក្តារចុច' : 'Open keyboard';
  String get muteAudio => isKhmer ? 'បិទសំឡេង' : 'Mute tutor audio';
  String get unmuteAudio => isKhmer ? 'បើកសំឡេង' : 'Unmute tutor audio';
  String stepCurrent(int step) =>
      isKhmer ? 'ជំហាន ${_toKhmerDigits(step)} · បច្ចុប្បន្ន' : 'STEP $step · CURRENT';
  String stepNumber(int step) =>
      isKhmer ? 'ជំហាន ${_toKhmerDigits(step)}' : 'STEP $step';
  String yourTask(String task) =>
      isKhmer ? 'កិច្ចការរបស់អ្នក៖ $task' : 'Your task: $task';
  String get tutorThinkingAndDrawing =>
      isKhmer ? 'គ្រូកំពុងគិត និងសរសេរលើក្តារ...' : 'Tutor is thinking and drawing...';
  String get verifiedCorrect =>
      isKhmer ? 'ត្រឹមត្រូវហើយ' : 'Verified correct';
  String get validShowRequestedStep =>
      isKhmer ? 'ត្រឹមត្រូវ — សូមបង្ហាញជំហានដែលបានស្នើ' : 'Valid — show the requested step';
  String get stepNeedsCorrection =>
      isKhmer ? 'ជំហាននេះត្រូវកែតម្រូវ' : 'This step needs a correction';
  String get moreOfStepNeeded =>
      isKhmer ? 'ត្រូវការបន្ថែមលើជំហាននេះ' : 'More of this step is needed';
  String get mathCheckUnavailable =>
      isKhmer ? 'មិនអាចផ្ទៀងផ្ទាត់គណិតវិទ្យាបានទេ' : 'Math check unavailable';

  // ── Dashboard Metrics & Profile Setup ──────────────────────────────────────
  String get completeProfileDesc => isKhmer
      ? 'ជ្រើសរើសថ្នាក់ ភាសា និងមុខវិជ្ជាសម្រាប់មេរៀនត្រឹមត្រូវ។'
      : 'Choose your grade, language, and subjects for the right lessons.';
  String get setUp => isKhmer ? 'រៀបចំ' : 'Set up';
  String get visualTutorReady => isKhmer
      ? 'គ្រូបង្រៀនរូបភាពរបស់អ្នកត្រៀមខ្លួនដោះស្រាយគ្រប់លំហាត់ជំហានម្តងៗ។'
      : 'Your visual tutor is ready to solve any problem step-by-step.';
  String get dailyStreak => isKhmer ? 'ចំនួនថ្ងៃបន្តបន្ទាប់' : 'Daily Streak';
  String days(int n) => isKhmer ? '${_toKhmerDigits(n)} ថ្ងៃ' : '$n Days';
  String get startStreakToday => isKhmer ? 'ចាប់ផ្តើមថ្ងៃនេះ' : 'Start one today';
  String get keepMomentum =>
      isKhmer ? 'បន្តសកម្មភាពរបស់អ្នក' : 'Keep your momentum';
  String get mastered => isKhmer ? 'ស្ទាត់ជំនាញ' : 'Mastered';
  String visualTopics(int n) => isKhmer
      ? '${_toKhmerDigits(n)} ប្រធានបទរូបភាព'
      : (n == 1 ? '1 Visual topic' : '$n Visual topics');
  String get defaultPracticeReason => isKhmer
      ? 'ការអនុវត្តរូបភាពខ្លីដោយផ្អែកលើការរៀនបច្ចុប្បន្នរបស់អ្នក។'
      : 'A short visual practice based on your current learning.';

  // ── Profile & Quizzes ──────────────────────────────────────────────────────
  String get editProfile => isKhmer ? 'កែប្រែព័ត៌មាន' : 'Edit Profile';
  String get saveChanges => isKhmer ? 'រក្សាទុកការផ្លាស់ប្តូរ' : 'Save Changes';
  String get learningGoals => isKhmer ? 'គោលដៅសិក្សា' : 'Learning Goals';
  String get totalScore => isKhmer ? 'សរុបពិន្ទុ' : 'Total score';
  String get reviewDetailedAnswers =>
      isKhmer ? 'មើលចម្លើយលម្អិត' : 'Review detailed answers';
  String get retakeQuiz => isKhmer ? 'ប្រឡងម្តងទៀត' : 'Retake quiz';
  String get learnFromMistakes => isKhmer ? 'រៀនពីកំហុស' : 'Learn from mistakes';
  String get languageKhmer => 'ខ្មែរ';
  String get languageEnglish => 'English';

  String localizedSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math':
      case 'maths':
        return subjectMath;
      case 'physics':
        return subjectPhysics;
      case 'chemistry':
        return subjectChemistry;
      default:
        return subject;
    }
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
