import 'package:flutter/material.dart';

import '../../core/adaptive_colors.dart';
import '../../core/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/language_switcher_button.dart';
import '../../shared/state_widgets/app_error_state.dart';
import '../../shared/student_design_system.dart';
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
    this.onBrowseCurriculum,
  }) : repository = repository ?? buildDefaultDashboardRepository();

  final DashboardRepository repository;
  final VoidCallback onResumeLearning;
  final ValueChanged<StudentDashboardData>? onResumeLearningWithData;
  final ValueChanged<String>? onAskQuestion;
  final VoidCallback? onVoiceQuestion;
  final ValueChanged<StudentDashboardData>? onStartDailyPractice;
  final VoidCallback? onCompleteProfile;

  /// Opens the curriculum (Tutor tab) from the Continue Learning section.
  final VoidCallback? onBrowseCurriculum;

  @override
  Widget build(BuildContext context) => _DashboardLoader(
    repository: repository,
    onResumeLearning: onResumeLearning,
    onResumeLearningWithData: onResumeLearningWithData,
    onAskQuestion: onAskQuestion,
    onVoiceQuestion: onVoiceQuestion,
    onStartDailyPractice: onStartDailyPractice,
    onCompleteProfile: onCompleteProfile,
    onBrowseCurriculum: onBrowseCurriculum,
  );
}

/// Content wider than this splits into a main column and a side column.
const double _twoColumnMinWidth = 960;
const double _sideColumnWidth = 360;
const double _pageMaxWidth = 1180;

class _DashboardLoader extends StatefulWidget {
  const _DashboardLoader({
    required this.repository,
    required this.onResumeLearning,
    required this.onResumeLearningWithData,
    required this.onAskQuestion,
    required this.onVoiceQuestion,
    required this.onStartDailyPractice,
    required this.onCompleteProfile,
    required this.onBrowseCurriculum,
  });
  final DashboardRepository repository;
  final VoidCallback onResumeLearning;
  final ValueChanged<StudentDashboardData>? onResumeLearningWithData;
  final ValueChanged<String>? onAskQuestion;
  final VoidCallback? onVoiceQuestion;
  final ValueChanged<StudentDashboardData>? onStartDailyPractice;
  final VoidCallback? onCompleteProfile;
  final VoidCallback? onBrowseCurriculum;

  @override
  State<_DashboardLoader> createState() => _DashboardLoaderState();
}

class _DashboardLoaderState extends State<_DashboardLoader> {
  late Future<StudentDashboardData?> _future;
  final _question = TextEditingController();
  final _questionFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _future = widget.repository.loadDashboard();
  }

  @override
  void dispose() {
    _question.dispose();
    _questionFocus.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final next = widget.repository.loadDashboard();
    setState(() => _future = next);
    await next;
  }

  void _ask() {
    final value = _question.text.trim();
    if (value.isNotEmpty) widget.onAskQuestion?.call(value);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<StudentDashboardData?>(
    future: _future,
    builder: (context, snapshot) {
      final l10n = AppLocalizations.of(context);
      if (snapshot.connectionState != ConnectionState.done) {
        return _DashboardSkeleton(label: l10n.dashboardLoading);
      }
      if (snapshot.hasError) {
        return AppErrorState(message: l10n.dashboardLoadError, onRetry: _refresh);
      }

      final ask = _AskAnythingCard(
        controller: _question,
        focusNode: _questionFocus,
        onAsk: widget.onAskQuestion == null ? null : _ask,
        onVoice: widget.onVoiceQuestion,
      );
      final data = snapshot.data;

      return RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.cyan,
        child: data == null || data.isEmpty
            ? _EmptyDashboard(ask: ask)
            : _DashboardContent(
                data: data,
                ask: ask,
                onResume: () {
                  final resume = widget.onResumeLearningWithData;
                  resume == null ? widget.onResumeLearning() : resume(data);
                },
                onStartDailyPractice: () {
                  final start = widget.onStartDailyPractice;
                  start == null ? widget.onResumeLearning() : start(data);
                },
                onCompleteProfile: widget.onCompleteProfile,
                onBrowseCurriculum: widget.onBrowseCurriculum,
              ),
      );
    },
  );
}

/* ─── Layout ──────────────────────────────────────────────────────────────── */

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({required this.builder});
  final Widget Function(BuildContext context, double width) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontal = constraints.maxWidth >= 1100
          ? 40.0
          : constraints.maxWidth >= 600
          ? 28.0
          : 16.0;
      final width = (constraints.maxWidth - horizontal * 2).clamp(0.0, _pageMaxWidth);
      return SingleChildScrollView(
        key: const Key('dashboard-scroll-view'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 32),
        child: Center(
          child: SizedBox(width: width, child: builder(context, width)),
        ),
      );
    },
  );
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.data,
    required this.ask,
    required this.onResume,
    required this.onStartDailyPractice,
    required this.onCompleteProfile,
    required this.onBrowseCurriculum,
  });
  final StudentDashboardData data;
  final Widget ask;
  final VoidCallback onResume;
  final VoidCallback onStartDailyPractice;
  final VoidCallback? onCompleteProfile;
  final VoidCallback? onBrowseCurriculum;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _DashboardPage(
      builder: (context, width) {
        final twoColumns = width >= _twoColumnMinWidth;
        final main = <Widget>[
          ask,
          const SizedBox(height: 24),
          StudentSectionHeader(
            l10n.continueLearning,
            icon: Icons.play_circle_outline_rounded,
            action: onBrowseCurriculum == null
                ? null
                : TextButton.icon(
                    key: const Key('dashboard-browse-curriculum'),
                    onPressed: onBrowseCurriculum,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(l10n.browseTopics),
                  ),
          ),
          _ContinueCard(data: data, onTap: onResume),
          if (data.recentActivity.isNotEmpty) ...[
            const SizedBox(height: 24),
            StudentSectionHeader(l10n.recentActivity, icon: Icons.history_rounded),
            _RecentActivity(items: data.recentActivity),
          ],
        ];
        final side = <Widget>[
          if (!twoColumns) const SizedBox(height: 24),
          StudentSectionHeader(l10n.yourStats, icon: Icons.insights_rounded),
          _Stats(data: data),
          const SizedBox(height: 24),
          StudentSectionHeader(l10n.dailyPractice, icon: Icons.bolt_rounded),
          _DailyPractice(data: data, onStart: onStartDailyPractice),
          const SizedBox(height: 24),
          StudentSectionHeader(l10n.yourProgress, icon: Icons.trending_up_rounded),
          _ProgressCard(progress: data.subjectProgress),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Greeting(data: data),
            const SizedBox(height: 20),
            if (_needsLearningProfile(data)) ...[
              _ProfileCompletionCard(onComplete: onCompleteProfile),
              const SizedBox(height: 16),
            ],
            if (twoColumns)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: main,
                    ),
                  ),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: _sideColumnWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: side,
                    ),
                  ),
                ],
              )
            else ...[
              ...main,
              ...side,
            ],
          ],
        );
      },
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({required this.ask});
  final Widget ask;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _DashboardPage(
      builder: (context, width) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: LanguageSwitcherButton(compact: true),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.school_rounded, color: AppColors.cyan, size: 32),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.learningSpaceReady,
                textAlign: TextAlign.center,
                style: StudentStyle.title(context, 22),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.learningSpaceReadyDesc,
                textAlign: TextAlign.center,
                style: StudentStyle.body(context),
              ),
              const SizedBox(height: 24),
              ask,
            ],
          ),
        ),
      ),
    );
  }
}

/* ─── Shared styling ─────────────────────────────────────────────────────── */

/// The backend sends a few fixed English resume phrases and grade labels;
/// show the student's language for the ones we know.
String _gradeName(AppLocalizations l10n, String gradeLabel) {
  final match = RegExp(r'^Grade\s+(\d+)$').firstMatch(gradeLabel.trim());
  return match == null ? gradeLabel : l10n.gradeLevel(int.parse(match.group(1)!));
}

String _resumeText(AppLocalizations l10n, String text) => switch (text) {
  'Start learning' => l10n.startLearningTitle,
  'Resume your latest tutor activity' => l10n.resumeLatestActivity,
  'Choose a learning goal to begin.' => l10n.chooseGoalToBegin,
  _ => text,
};

String _timeText(AppLocalizations l10n, String label) {
  if (label == 'Today') return l10n.today;
  if (label == 'Yesterday') return l10n.yesterday;
  if (label == 'Recent') return l10n.recently;
  final days = RegExp(r'^(\d+) days ago$').firstMatch(label);
  return days == null ? label : l10n.daysAgo(int.parse(days.group(1)!));
}

bool _needsLearningProfile(StudentDashboardData data) =>
    data.gradeLabel.trim().isEmpty ||
    data.gradeLabel == 'Not selected' ||
    data.subjects.isEmpty;

/* ─── Greeting & profile ─────────────────────────────────────────────────── */

class _Greeting extends StatelessWidget {
  const _Greeting({required this.data});
  final StudentDashboardData data;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final needsProfile = _needsLearningProfile(data);
    final greeting = needsProfile || data.studentName == 'Learner'
        ? l10n.welcomeLearner
        : l10n.helloUser(data.studentName);
    final subtitle = needsProfile
        ? l10n.setUpLearningPath
        : '${_gradeName(l10n, data.gradeLabel)} • ${l10n.readyToLearn}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                key: const Key('dashboard-greeting'),
                style: StudentStyle.title(context, 24),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: StudentStyle.body(context, size: 14)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const LanguageSwitcherButton(compact: true),
      ],
    );
  }
}

class _ProfileCompletionCard extends StatelessWidget {
  const _ProfileCompletionCard({required this.onComplete});
  final VoidCallback? onComplete;
  static const _accent = Color(0xFF8A52FF);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: l10n.completeProfile,
      child: Container(
        key: const Key('dashboard-profile-completion-card'),
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        decoration: StudentStyle.card(context, accent: _accent).copyWith(
          color: Color.alphaBlend(
            _accent.withValues(alpha: .08),
            AdaptiveColors.card(context),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school_rounded, color: _accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.completeProfile, style: StudentStyle.title(context, 15)),
                  const SizedBox(height: 2),
                  Text(l10n.completeProfileDesc, style: StudentStyle.body(context, size: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const Key('dashboard-complete-profile-button'),
              onPressed: onComplete,
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                minimumSize: const Size(64, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l10n.setUp),
            ),
          ],
        ),
      ),
    );
  }
}

/* ─── Ask anything ───────────────────────────────────────────────────────── */

class _AskAnythingCard extends StatelessWidget {
  const _AskAnythingCard({
    required this.controller,
    required this.focusNode,
    required this.onAsk,
    required this.onVoice,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onAsk;
  final VoidCallback? onVoice;

  void _useExample(String text) {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final light = AdaptiveColors.isLight(context);
    final examples = [
      (label: l10n.subjectMath, text: l10n.exampleMath),
      (label: l10n.subjectPhysics, text: l10n.examplePhysics),
      (label: l10n.subjectChemistry, text: l10n.exampleChemistry),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: light
              ? const [Color(0xFFE3F8FC), Color(0xFFEAEBFF)]
              : const [Color(0xFF0A3544), Color(0xFF161E4A)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cyan.withValues(alpha: light ? .45 : .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: light ? const Color(0xFF0B8FA3) : AppColors.cyan,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.askAnything, style: StudentStyle.title(context, 20)),
                    Text(
                      l10n.visualTutorReady,
                      style: StudentStyle.body(
                        context,
                        color: light ? const Color(0xFF0B7285) : const Color(0xFF8FE9F5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('dashboard-question-field'),
            controller: controller,
            focusNode: focusNode,
            enabled: onAsk != null,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onAsk?.call(),
            style: TextStyle(
              color: AdaptiveColors.text(context),
              fontSize: 15,
              height: 1.4,
              fontFamilyFallback: AppTheme.fontFallback,
            ),
            decoration: InputDecoration(
              hintText: l10n.typeYourQuestionHint,
              hintStyle: StudentStyle.body(context, size: 14),
              prefixIcon: Icon(
                Icons.edit_note_rounded,
                color: AdaptiveColors.muted(context),
              ),
              filled: true,
              fillColor: light ? Colors.white : const Color(0xCC050A17),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.tryAnExample, style: StudentStyle.body(context, size: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final example in examples)
                _ExampleChip(
                  label: example.label,
                  example: example.text,
                  onTap: onAsk == null ? null : () => _useExample(example.text),
                ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final askButton = _EntryButton(
                key: const Key('dashboard-ask-button'),
                icon: Icons.arrow_forward_rounded,
                label: l10n.askAction,
                primary: true,
                onPressed: onAsk,
              );
              final voiceButton = _EntryButton(
                key: const Key('dashboard-voice-button'),
                icon: Icons.mic_rounded,
                label: l10n.voiceAction,
                onPressed: onVoice,
              );
              return constraints.maxWidth < 270
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [askButton, const SizedBox(height: 10), voiceButton],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 3, child: askButton),
                        const SizedBox(width: 10),
                        Expanded(flex: 2, child: voiceButton),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip({required this.label, required this.example, required this.onTap});
  final String label;
  final String example;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = subjectVisual(label);
    final light = AdaptiveColors.isLight(context);
    return Tooltip(
      message: example,
      child: Material(
        color: light ? Colors.white.withValues(alpha: .85) : Colors.white.withValues(alpha: .06),
        shape: StadiumBorder(side: BorderSide(color: style.color.withValues(alpha: .35))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(style.icon, size: 16, color: style.color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: AdaptiveColors.text(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: AppTheme.fontFallback,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final light = AdaptiveColors.isLight(context);
    final secondaryFill = light ? Colors.white : const Color(0xFF19283D);
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        iconAlignment: primary ? IconAlignment.end : IconAlignment.start,
        style: FilledButton.styleFrom(
          backgroundColor: primary ? AppColors.cyan : secondaryFill,
          foregroundColor: primary ? const Color(0xFF071222) : AdaptiveColors.text(context),
          disabledBackgroundColor: primary ? AppColors.cyan.withValues(alpha: .35) : secondaryFill,
          disabledForegroundColor: AdaptiveColors.muted(context),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            fontFamilyFallback: AppTheme.fontFallback,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: primary ? Colors.transparent : AdaptiveColors.line(context),
            ),
          ),
        ),
      ),
    );
  }
}

/* ─── Continue learning ─────────────────────────────────────────────────── */

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.data, required this.onTap});
  final StudentDashboardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasSession = data.resumeSessionId != null;
    final style = subjectVisual(data.resumeSubject);
    SubjectProgress? progress;
    for (final item in data.subjectProgress) {
      if (item.topic == data.resumeTopic || item.topic == data.resumeTitle) {
        progress = item;
        break;
      }
    }
    final percent = progress == null ? null : (progress.progress * 100).round();

    return Semantics(
      button: true,
      label: '${l10n.continueLearning}: ${data.resumeTitle}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('dashboard-resume-learning-button'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: StudentStyle.card(context),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: style.color.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(style.icon, color: style.color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.resumeSubject.isNotEmpty && data.resumeSubject != 'Subject')
                        Text(
                          l10n.isKhmer
                              ? localizedSubjectName(l10n, data.resumeSubject)
                              : localizedSubjectName(l10n, data.resumeSubject).toUpperCase(),
                          style: TextStyle(
                            color: style.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .8,
                          ),
                        ),
                      Text(
                        _resumeText(l10n, data.resumeTitle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StudentStyle.title(context, 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _resumeText(l10n, data.resumeSubtitle),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: StudentStyle.body(context),
                      ),
                      if (percent != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _ProgressBar(value: progress!.progress, color: style.color)),
                            const SizedBox(width: 10),
                            Text(
                              l10n.percent(percent),
                              style: TextStyle(
                                color: AdaptiveColors.muted(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: style.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasSession ? l10n.resumeAction : l10n.startLearningAction,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          fontFamilyFallback: AppTheme.fontFallback,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.items});
  final List<DashboardActivity> items;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(4).toList();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: StudentStyle.card(context),
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: i == 0 ? AppColors.cyan : AdaptiveColors.line(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visible[i].title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AdaptiveColors.text(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamilyFallback: AppTheme.fontFallback,
                          ),
                        ),
                        Text(
                          visible[i].subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StudentStyle.body(context, size: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_timeText(AppLocalizations.of(context), visible[i].timeLabel), style: StudentStyle.body(context, size: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/* ─── Stats, practice, progress ─────────────────────────────────────────── */

class _Stats extends StatelessWidget {
  const _Stats({required this.data});
  final StudentDashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mastered = data.subjectProgress.where((item) => item.progress >= .8).length;
    return StudentStatRow(
      tiles: [
        StudentStatTile(
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFF6B39),
          label: l10n.dailyStreak,
          value: l10n.days(data.learningStreakDays),
          caption: data.learningStreakDays == 0 ? l10n.startStreakToday : l10n.keepMomentum,
        ),
        StudentStatTile(
          icon: Icons.workspace_premium_rounded,
          color: const Color(0xFF12B5CB),
          label: l10n.mastered,
          value: l10n.number(mastered),
          caption: l10n.visualTopics(mastered),
        ),
        StudentStatTile(
          icon: Icons.task_alt_rounded,
          color: const Color(0xFF8A52FF),
          label: l10n.practiceDone,
          value: l10n.number(data.completedPractice),
          caption: l10n.exercises(data.completedPractice),
        ),
      ],
    );
  }
}

class _DailyPractice extends StatelessWidget {
  const _DailyPractice({required this.data, required this.onStart});
  final StudentDashboardData data;
  final VoidCallback onStart;
  static const _accent = Color(0xFF8A52FF);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final weak = data.weakTopic;
    final recommendation = data.practiceRecommendations.isNotEmpty
        ? data.practiceRecommendations.first
        : null;
    final title = weak?.title ?? recommendation?.topic ?? data.resumeTitle;
    final reason = weak?.reason ?? recommendation?.reason ?? l10n.defaultPracticeReason;

    return Container(
      key: const Key('dashboard-daily-practice-card'),
      padding: const EdgeInsets.all(18),
      decoration: StudentStyle.card(context, accent: _accent).copyWith(
        color: Color.alphaBlend(_accent.withValues(alpha: .07), AdaptiveColors.card(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudentPill(icon: Icons.bolt_rounded, label: l10n.focusNext, color: _accent),
          const SizedBox(height: 10),
          Text(title, style: StudentStyle.title(context, 17)),
          const SizedBox(height: 4),
          Text(reason, maxLines: 3, overflow: TextOverflow.ellipsis, style: StudentStyle.body(context)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              key: const Key('dashboard-start-daily-practice-button'),
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(l10n.startChallenge),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFamilyFallback: AppTheme.fontFallback,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});
  final List<SubjectProgress> progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudentStyle.card(context),
      child: progress.isEmpty
          ? Row(
              children: [
                Icon(Icons.insights_rounded, color: AdaptiveColors.muted(context)),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.noProgressYet, style: StudentStyle.body(context))),
              ],
            )
          : Column(
              children: [
                for (var i = 0; i < progress.length.clamp(0, 4); i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  _ProgressRow(progress: progress[i]),
                ],
              ],
            ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.progress});
  final SubjectProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = (progress.progress * 100).round();
    final style = subjectVisual(progress.subject);
    return Semantics(
      label: '${localizedSubjectName(l10n, progress.subject)}, ${progress.topic}, ${l10n.percent(percent)}',
      excludeSemantics: true,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(style.icon, color: style.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        progress.topic,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AdaptiveColors.text(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamilyFallback: AppTheme.fontFallback,
                        ),
                      ),
                    ),
                    Text(
                      l10n.percent(percent),
                      style: TextStyle(
                        color: style.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Text(localizedSubjectName(l10n, progress.subject), style: StudentStyle.body(context, size: 11)),
                const SizedBox(height: 6),
                _ProgressBar(value: progress.progress, color: style.color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => LinearProgressIndicator(
        value: animated,
        minHeight: 7,
        backgroundColor: AdaptiveColors.line(context).withValues(alpha: .6),
        color: color,
      ),
    ),
  );
}

/* ─── Loading ───────────────────────────────────────────────────────────── */

/// A calm placeholder in the shape of the page, so the layout does not jump
/// when data arrives.
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    Widget block(double height, {double? width, double radius = 20}) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AdaptiveColors.line(context).withValues(alpha: .45),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    return Semantics(
      label: label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: _DashboardPage(
          builder: (context, width) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              block(26, width: 220, radius: 8),
              const SizedBox(height: 8),
              block(14, width: 160, radius: 6),
              const SizedBox(height: 24),
              block(230, radius: 24),
              const SizedBox(height: 24),
              block(18, width: 150, radius: 6),
              const SizedBox(height: 12),
              block(84),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: block(120)),
                  const SizedBox(width: 10),
                  Expanded(child: block(120)),
                  const SizedBox(width: 10),
                  Expanded(child: block(120)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
