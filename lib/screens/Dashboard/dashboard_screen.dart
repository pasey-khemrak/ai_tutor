import 'package:flutter/material.dart';

import '../../core/adaptive_colors.dart';
import '../../core/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/language_switcher_button.dart';
import '../../shared/state_widgets/app_empty_state.dart';
import '../../shared/state_widgets/app_error_state.dart';
import '../../shared/state_widgets/app_loading_state.dart';
import 'dashboard_repository.dart';

/// The student home. It renders persisted progress only; it never invents
/// learning statistics or writes progress on the device.
class DashboardScreen extends StatelessWidget {
  DashboardScreen({
    super.key,
    DashboardRepository? repository,
    required this.onResumeLearning,
    this.onResumeLearningWithData,
    this.onAskQuestion,
    this.onVoiceQuestion,
    this.onStartDailyPractice,
    this.onCompleteProfile,
  }) : repository = repository ?? buildDefaultDashboardRepository();

  final DashboardRepository repository;
  final VoidCallback onResumeLearning;
  final ValueChanged<StudentDashboardData>? onResumeLearningWithData;
  final ValueChanged<String>? onAskQuestion;
  final VoidCallback? onVoiceQuestion;
  final ValueChanged<StudentDashboardData>? onStartDailyPractice;
  final VoidCallback? onCompleteProfile;

  @override
  Widget build(BuildContext context) => _DashboardLoader(
    repository: repository,
    onResumeLearning: onResumeLearning,
    onResumeLearningWithData: onResumeLearningWithData,
    onAskQuestion: onAskQuestion,
    onVoiceQuestion: onVoiceQuestion,
    onStartDailyPractice: onStartDailyPractice,
    onCompleteProfile: onCompleteProfile,
  );
}

class _DashboardLoader extends StatefulWidget {
  const _DashboardLoader({
    required this.repository,
    required this.onResumeLearning,
    required this.onResumeLearningWithData,
    required this.onAskQuestion,
    required this.onVoiceQuestion,
    required this.onStartDailyPractice,
    required this.onCompleteProfile,
  });
  final DashboardRepository repository;
  final VoidCallback onResumeLearning;
  final ValueChanged<StudentDashboardData>? onResumeLearningWithData;
  final ValueChanged<String>? onAskQuestion;
  final VoidCallback? onVoiceQuestion;
  final ValueChanged<StudentDashboardData>? onStartDailyPractice;
  final VoidCallback? onCompleteProfile;

  @override
  State<_DashboardLoader> createState() => _DashboardLoaderState();
}

class _DashboardLoaderState extends State<_DashboardLoader> {
  late Future<StudentDashboardData?> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.repository.loadDashboard();
  }

  Future<void> _refresh() async {
    final next = widget.repository.loadDashboard();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<StudentDashboardData?>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const AppLoadingState(
          message: 'Preparing your learning space...',
        );
      }
      if (snapshot.hasError) {
        return AppErrorState(
          message: 'Could not load your dashboard.',
          onRetry: _refresh,
        );
      }
      final data = snapshot.data;
      if (data == null || data.isEmpty) {
        return const AppEmptyState(
          title: 'Your learning space is ready',
          message: 'Start a tutor session to see your progress here.',
          icon: Icons.school_outlined,
        );
      }
      return RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.cyan,
        child: _DashboardContent(
          data: data,
          onResume: () {
            final resume = widget.onResumeLearningWithData;
            resume == null ? widget.onResumeLearning() : resume(data);
          },
          onAskQuestion: widget.onAskQuestion,
          onVoiceQuestion: widget.onVoiceQuestion,
          onStartDailyPractice: widget.onStartDailyPractice,
          onCompleteProfile: widget.onCompleteProfile,
        ),
      );
    },
  );
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent({
    required this.data,
    required this.onResume,
    required this.onAskQuestion,
    required this.onVoiceQuestion,
    required this.onStartDailyPractice,
    required this.onCompleteProfile,
  });
  final StudentDashboardData data;
  final VoidCallback onResume;
  final ValueChanged<String>? onAskQuestion;
  final VoidCallback? onVoiceQuestion;
  final ValueChanged<StudentDashboardData>? onStartDailyPractice;
  final VoidCallback? onCompleteProfile;

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  final _question = TextEditingController();
  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  void _ask() {
    final value = _question.text.trim();
    if (value.isNotEmpty) widget.onAskQuestion?.call(value);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      final padding = wide ? 36.0 : 22.0;
      return SingleChildScrollView(
        key: const Key('dashboard-scroll-view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(padding, 26, padding, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Greeting(data: widget.data),
                const SizedBox(height: 26),
                if (_needsLearningProfile(widget.data)) ...[
                  _ProfileCompletionCard(onComplete: widget.onCompleteProfile),
                  const SizedBox(height: 20),
                ],
                _AskAnythingCard(
                  controller: _question,
                  onAsk: widget.onAskQuestion == null ? null : _ask,
                  onVoice: widget.onVoiceQuestion,
                ),
                const SizedBox(height: 30),
                _Heading(AppLocalizations.of(context).continueLearning),
                const SizedBox(height: 14),
                _ContinueCard(data: widget.data, onTap: widget.onResume),
                const SizedBox(height: 22),
                _Metrics(data: widget.data),
                const SizedBox(height: 30),
                _DailyPractice(
                  data: widget.data,
                  onStart: () {
                    final start = widget.onStartDailyPractice;
                    if (start != null) {
                      start(widget.data);
                    } else {
                      widget.onResume();
                    }
                  },
                ),
                if (widget.data.subjectProgress.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  _Heading(AppLocalizations.of(context).yourProgress),
                  const SizedBox(height: 12),
                  _ProgressPreview(progress: widget.data.subjectProgress),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

bool _needsLearningProfile(StudentDashboardData data) =>
    data.gradeLabel.trim().isEmpty ||
    data.gradeLabel == 'Not selected' ||
    data.subjects.isEmpty;

class _ProfileCompletionCard extends StatelessWidget {
  const _ProfileCompletionCard({required this.onComplete});
  final VoidCallback? onComplete;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Complete your learning profile',
    child: Container(
      key: const Key('dashboard-profile-completion-card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171333),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF8A52FF).withValues(alpha: .6),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_rounded, color: Color(0xFF9C69FF), size: 30),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).completeProfile,
                  style: TextStyle(
                    color: AdaptiveColors.text(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppLocalizations.of(context).completeProfileDesc,
                  style: const TextStyle(color: Color(0xFFB4BEF2), fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton(
            key: const Key('dashboard-complete-profile-button'),
            onPressed: onComplete,
            child: Text(AppLocalizations.of(context).setUp),
          ),
        ],
      ),
    ),
  );
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.data});
  final StudentDashboardData data;
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final needsProfile = _needsLearningProfile(data);
    final greeting = needsProfile || data.studentName == 'Learner'
        ? localizations.welcomeLearner
        : localizations.helloUser(data.studentName);
    final subtitle = needsProfile
        ? localizations.setUpLearningPath
        : '${data.gradeLabel} • ${localizations.readyToLearn}';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                key: const Key('dashboard-greeting'),
                style: TextStyle(
                  color: AdaptiveColors.text(context),
                  fontSize: 31,
                  height: 1.35,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                  fontFamilyFallback: AppTheme.fontFallback,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFB4BEF2),
                  fontSize: 18,
                  height: 1.40,
                  fontWeight: FontWeight.w600,
                  fontFamilyFallback: AppTheme.fontFallback,
                ),
              ),
            ],
          ),
        ),
        const LanguageSwitcherButton(compact: true),
        const SizedBox(width: 12),
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            color: const Color(0xFF11182A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cyan.withValues(alpha: .22)),
          ),
          child: const Icon(
            Icons.calculate_rounded,
            color: Color(0xFFFFC33D),
            size: 36,
          ),
        ),
      ],
    );
  }
}

class _AskAnythingCard extends StatelessWidget {
  const _AskAnythingCard({
    required this.controller,
    required this.onAsk,
    required this.onVoice,
  });
  final TextEditingController controller;
  final VoidCallback? onAsk;
  final VoidCallback? onVoice;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF073F4A), Color(0xFF121C45)],
      ),
      borderRadius: BorderRadius.circular(42),
      border: Border.all(
        color: AppColors.cyan.withValues(alpha: .37),
        width: 1.4,
      ),
      boxShadow: [
        BoxShadow(color: AppColors.cyan.withValues(alpha: .08), blurRadius: 28),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Ask anything',
                style: TextStyle(
                  color: AdaptiveColors.text(context),
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),
            ),
            const Icon(
              Icons.functions_rounded,
              color: Color(0xFFFFBE37),
              size: 42,
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          AppLocalizations.of(context).visualTutorReady,
          style: const TextStyle(
            color: AppColors.cyan,
            fontSize: 18,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          key: const Key('dashboard-question-field'),
          controller: controller,
          enabled: onAsk != null,
          onSubmitted: (_) => onAsk?.call(),
          style: TextStyle(color: AdaptiveColors.text(context), fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Type your question…',
            hintStyle: const TextStyle(color: Color(0xFFB9C0EC)),
            prefixIcon: const Icon(
              Icons.chat_bubble_rounded,
              color: Color(0xFF526DFF),
            ),
            filled: true,
            fillColor: const Color(0xCC050A17),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(27),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final ask = _EntryButton(
              key: const Key('dashboard-ask-button'),
              icon: Icons.arrow_forward_rounded,
              label: 'Ask',
              primary: true,
              onPressed: onAsk,
            );
            final voice = _EntryButton(
              key: const Key('dashboard-voice-button'),
              icon: Icons.mic_rounded,
              label: 'Voice',
              onPressed: onVoice,
            );
            return constraints.maxWidth < 400
                ? Column(children: [ask, const SizedBox(height: 12), voice])
                : Row(
                    children: [
                      Expanded(child: ask),
                      const SizedBox(width: 16),
                      Expanded(child: voice),
                    ],
                  );
          },
        ),
      ],
    ),
  );
}

class _EntryButton extends StatelessWidget {
  const _EntryButton({
    super.key,
    required this.icon,
    required this.label,
    this.primary = false,
    this.onPressed,
  });
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 76,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 27),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: primary ? AppColors.cyan : const Color(0xFF19283D),
        foregroundColor: primary
            ? const Color(0xFF071222)
            : AdaptiveColors.text(context),
        disabledBackgroundColor: primary
            ? AppColors.cyan.withValues(alpha: .35)
            : const Color(0xFF19283D),
        disabledForegroundColor: AdaptiveColors.muted(context),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: primary ? Colors.transparent : const Color(0xFF3A4960),
          ),
        ),
      ),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: AdaptiveColors.text(context),
      fontSize: 27,
      fontWeight: FontWeight.w900,
      letterSpacing: -.5,
    ),
  );
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.data, required this.onTap});
  final StudentDashboardData data;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Continue learning ${data.resumeTitle}',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('dashboard-resume-learning-button'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(33),
        child: Ink(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF15182B),
            borderRadius: BorderRadius.circular(33),
            border: Border.all(color: const Color(0xFF2B3048)),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: AppColors.cyan,
                  size: 37,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.resumeTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AdaptiveColors.text(context),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data.resumeSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFADB6E8),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF7784BA),
                size: 35,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.data});
  final StudentDashboardData data;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mastered = data.subjectProgress
        .where((item) => item.progress >= .8)
        .length;
    final cards = [
      _Metric(
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFFF6B39),
        title: l10n.dailyStreak,
        value: l10n.days(data.learningStreakDays),
        caption: data.learningStreakDays == 0
            ? l10n.startStreakToday
            : l10n.keepMomentum,
      ),
      _Metric(
        icon: Icons.bar_chart_rounded,
        color: AppColors.cyan,
        title: l10n.mastered,
        value: '$mastered',
        caption: l10n.visualTopics(mastered),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 430
          ? Column(
              children: [cards.first, const SizedBox(height: 14), cards.last],
            )
          : Row(
              children: [
                Expanded(child: cards.first),
                const SizedBox(width: 18),
                Expanded(child: cards.last),
              ],
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.caption,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String caption;
  @override
  Widget build(BuildContext context) => Container(
    height: 190,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xFF15182A),
      borderRadius: BorderRadius.circular(31),
      border: Border.all(color: color.withValues(alpha: .3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 27),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: AdaptiveColors.text(context),
            fontSize: 36,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: const TextStyle(
            color: Color(0xFFADB6E8),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _DailyPractice extends StatelessWidget {
  const _DailyPractice({required this.data, required this.onStart});
  final StudentDashboardData data;
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) {
    final weak = data.weakTopic;
    final recommendation = data.practiceRecommendations.isNotEmpty
        ? data.practiceRecommendations.first
        : null;
    final title = weak?.title ?? recommendation?.topic ?? data.resumeTitle;
    final reason =
        weak?.reason ??
        recommendation?.reason ??
        AppLocalizations.of(context).defaultPracticeReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(AppLocalizations.of(context).dailyPractice),
        const SizedBox(height: 13),
        Container(
          key: const Key('dashboard-daily-practice-card'),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: const Color(0xFF100E29),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: const Color(0xFF5533BD).withValues(alpha: .62),
              width: 1.25,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '“$title”',
                style: TextStyle(
                  color: AdaptiveColors.text(context),
                  fontSize: 21,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF9C69FF),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton(
                  key: const Key('dashboard-start-daily-practice-button'),
                  onPressed: onStart,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8A52FF),
                    side: const BorderSide(color: Color(0xFF4C2A9D)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: Text(AppLocalizations.of(context).startChallenge),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressPreview extends StatelessWidget {
  const _ProgressPreview({required this.progress});
  final List<SubjectProgress> progress;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF15182B),
      borderRadius: BorderRadius.circular(27),
      border: Border.all(color: const Color(0xFF2B3048)),
    ),
    child: Column(
      children: [
        for (var i = 0; i < progress.length.clamp(0, 3); i++) ...[
          if (i > 0) const SizedBox(height: 18),
          _ProgressRow(progress: progress[i]),
        ],
      ],
    ),
  );
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.progress});
  final SubjectProgress progress;
  @override
  Widget build(BuildContext context) {
    final percent = (progress.progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${progress.subject} • ${progress.topic}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AdaptiveColors.text(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress.progress,
            minHeight: 9,
            backgroundColor: const Color(0xFF262B42),
            color: AppColors.cyan,
          ),
        ),
      ],
    );
  }
}
