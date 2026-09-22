import 'package:flutter/material.dart';

import '../../core/adaptive_colors.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme_controller.dart';
import '../../core/localization/app_language_controller.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/language_switcher_button.dart';
import '../../shared/state_widgets/app_error_state.dart';
import '../../shared/student_design_system.dart';
import '../dashboard/dashboard_repository.dart';
import 'student_profile_repository.dart';

/// The Profile tab: who the student is, their learning setup and stats, app
/// preferences, and sign-out.
class StudentProfileSummaryScreen extends StatefulWidget {
  const StudentProfileSummaryScreen({
    super.key,
    required this.onSetup,
    required this.onLogout,
    this.repository,
    this.statsRepository,
  });
  final VoidCallback onSetup;
  final VoidCallback onLogout;
  final StudentProfileRepository? repository;

  /// Streak and practice stats come from the same summary as Home. When they
  /// cannot load, the stats row is simply left out.
  final DashboardRepository? statsRepository;

  @override
  State<StudentProfileSummaryScreen> createState() => _StudentProfileSummaryScreenState();
}

class _StudentProfileSummaryScreenState extends State<StudentProfileSummaryScreen> {
  late final StudentProfileRepository _repository;
  late final DashboardRepository _statsRepository;
  late Future<StudentProfileView> _future;
  late Future<StudentDashboardData?> _stats;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? StudentProfileRepository();
    _statsRepository = widget.statsRepository ?? buildDefaultDashboardRepository();
    _load();
  }

  void _load() {
    _future = _repository.loadProfile();
    _stats = _statsRepository.loadDashboard().then<StudentDashboardData?>(
      (value) => value,
      onError: (Object _) => null,
    );
  }

  Future<void> _reload() async {
    setState(_load);
    await _future;
  }

  Future<void> _confirmSignOut() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOutConfirmTitle),
        content: Text(l10n.signOutConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(
            key: const Key('profile-sign-out-confirm'),
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE5484D)),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<StudentProfileView>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _ProfileSkeleton();
        }
        if (snapshot.hasError) {
          return AppErrorState(message: l10n.profileLoadError, onRetry: _reload);
        }
        final profile = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _reload,
          color: AppColors.cyan,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth >= 600 ? 28.0 : 16.0;
              final twoColumns = constraints.maxWidth - horizontal * 2 >= 900;
              final setup = _LearningSetupCard(profile: profile, onSetup: widget.onSetup);
              final preferences = const _PreferencesCard();
              final account = _AccountCard(onSignOut: _confirmSignOut);
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: twoColumns ? 1080 : 760),
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
                                  Text(l10n.navProfile, style: StudentStyle.title(context, 24)),
                                  const SizedBox(height: 4),
                                  Text(l10n.profileSubtitle, style: StudentStyle.body(context, size: 14)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const LanguageSwitcherButton(compact: true),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _IdentityCard(profile: profile),
                        FutureBuilder<StudentDashboardData?>(
                          future: _stats,
                          builder: (context, stats) => stats.data == null
                              ? const SizedBox.shrink()
                              : Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: _StatsRow(data: stats.data!),
                                ),
                        ),
                        const SizedBox(height: 24),
                        if (twoColumns)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: setup),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [preferences, const SizedBox(height: 20), account],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          setup,
                          const SizedBox(height: 20),
                          preferences,
                          const SizedBox(height: 20),
                          account,
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

String _gradeText(AppLocalizations l10n, String gradeLevelId) {
  final match = RegExp(r'(\d+)').firstMatch(gradeLevelId);
  return match == null ? gradeLevelId : l10n.gradeLevel(int.parse(match.group(1)!));
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
  final letters = parts.take(2).map((part) => part.characters.first.toUpperCase()).join();
  return letters.isEmpty ? '?' : letters;
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});
  final StudentProfileView profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = profile.displayName.isEmpty ? l10n.studentFallbackName : profile.displayName;
    final complete = profile.isComplete;
    return Container(
      key: const Key('profile-identity-card'),
      padding: const EdgeInsets.all(20),
      decoration: StudentStyle.card(context, accent: AppColors.cyan).copyWith(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AdaptiveColors.isLight(context)
              ? const [Color(0xFFE3F8FC), Color(0xFFEAEBFF)]
              : const [Color(0xFF0A3544), Color(0xFF161E4A)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF12DDF5), Color(0xFF5B6CFF)]),
            ),
            child: Text(
              _initials(name),
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: StudentStyle.title(context, 21)),
                if (profile.email.isNotEmpty)
                  Text(
                    profile.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StudentStyle.body(context, size: 13),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StudentPill(
                      icon: complete ? Icons.verified_rounded : Icons.error_outline_rounded,
                      label: complete ? l10n.profileReady : l10n.profileIncomplete,
                      color: complete ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                    if (profile.gradeLevelId.isNotEmpty)
                      StudentPill(
                        icon: Icons.school_rounded,
                        label: _gradeText(l10n, profile.gradeLevelId),
                        color: AppColors.cyan,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.data});
  final StudentDashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mastered = data.subjectProgress.where((item) => item.progress >= .8).length;
    return StudentStatRow(
      key: const Key('profile-stats-row'),
      tiles: [
        StudentStatTile(
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFFF6B39),
          value: l10n.days(data.learningStreakDays),
          label: l10n.dailyStreak,
        ),
        StudentStatTile(
          icon: Icons.workspace_premium_rounded,
          color: const Color(0xFF12B5CB),
          value: l10n.number(mastered),
          label: l10n.mastered,
        ),
        StudentStatTile(
          icon: Icons.task_alt_rounded,
          color: const Color(0xFF8A52FF),
          value: l10n.number(data.completedPractice),
          label: l10n.practiceDone,
        ),
      ],
    );
  }
}

class _LearningSetupCard extends StatelessWidget {
  const _LearningSetupCard({required this.profile, required this.onSetup});
  final StudentProfileView profile;
  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Label beside value on roomy screens; label above value on phones.
    Widget row(IconData icon, String label, Widget value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelText = Text(label, style: StudentStyle.body(context, size: 14));
          final stacked = constraints.maxWidth < 380;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: AdaptiveColors.muted(context)),
              const SizedBox(width: 12),
              if (stacked)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [labelText, const SizedBox(height: 6), value],
                  ),
                )
              else ...[
                SizedBox(width: 130, child: labelText),
                Expanded(child: value),
              ],
            ],
          );
        },
      ),
    );
    Text valueText(String text) => Text(
      text,
      style: StudentStyle.body(context, size: 14, color: AdaptiveColors.text(context)).copyWith(
        fontWeight: FontWeight.w700,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudentSectionHeader(l10n.learningSetup, icon: Icons.tune_rounded),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          decoration: StudentStyle.card(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              row(
                Icons.school_outlined,
                l10n.gradeField,
                valueText(profile.gradeLevelId.isEmpty ? l10n.notSetYet : _gradeText(l10n, profile.gradeLevelId)),
              ),
              Divider(height: 1, color: AdaptiveColors.line(context)),
              row(
                Icons.menu_book_outlined,
                l10n.subjectsField,
                profile.subjects.isEmpty
                    ? valueText(l10n.notSetYet)
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final subject in profile.subjects)
                            StudentPill(
                              icon: subjectVisual(subject).icon,
                              label: localizedSubjectName(l10n, subject),
                              color: subjectVisual(subject).color,
                            ),
                        ],
                      ),
              ),
              Divider(height: 1, color: AdaptiveColors.line(context)),
              row(
                Icons.translate_rounded,
                l10n.languageField,
                valueText(profile.preferredLanguage == 'km' ? 'ខ្មែរ' : 'English'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const Key('profile-complete-learning-profile'),
                onPressed: onSetup,
                icon: const Icon(Icons.tune_rounded),
                label: Text(profile.isComplete ? l10n.updateLearningSetup : l10n.completeProfile),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: const Color(0xFF071222),
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontFamilyFallback: AppTheme.fontFallback),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudentSectionHeader(l10n.preferencesTitle, icon: Icons.settings_outlined),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: StudentStyle.card(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.appLanguage, style: StudentStyle.body(context, size: 13)),
              const SizedBox(height: 8),
              ValueListenableBuilder<Locale>(
                valueListenable: AppLanguageController.currentLocale,
                builder: (context, locale, _) => _Segmented(
                  key: const Key('profile-language-toggle'),
                  options: const ['English', 'ខ្មែរ'],
                  selected: locale.languageCode == 'km' ? 1 : 0,
                  onChanged: (index) => AppLanguageController.setLanguage(index == 1 ? 'km' : 'en'),
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.appearance, style: StudentStyle.body(context, size: 13)),
              const SizedBox(height: 8),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: AppThemeController.themeMode,
                builder: (context, mode, _) => _Segmented(
                  key: const Key('profile-theme-toggle'),
                  options: [l10n.themeLight, l10n.themeDark],
                  icons: const [Icons.light_mode_rounded, Icons.dark_mode_rounded],
                  selected: mode == ThemeMode.light ? 0 : 1,
                  onChanged: (index) => AppThemeController.setDarkMode(index == 1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.icons,
  });
  final List<String> options;
  final List<IconData>? icons;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AdaptiveColors.controlFill(context),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AdaptiveColors.line(context)),
    ),
    child: Row(
      children: [
        for (var i = 0; i < options.length; i++)
          Expanded(
            child: Semantics(
              selected: i == selected,
              button: true,
              child: Material(
                color: i == selected ? AdaptiveColors.card(context) : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: i == selected ? AdaptiveColors.line(context) : Colors.transparent,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onChanged(i),
                  child: SizedBox(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icons != null) ...[
                          Icon(
                            icons![i],
                            size: 16,
                            color: i == selected ? AppColors.cyan : AdaptiveColors.muted(context),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          options[i],
                          style: TextStyle(
                            color: i == selected ? AdaptiveColors.text(context) : AdaptiveColors.muted(context),
                            fontWeight: i == selected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 13,
                            fontFamilyFallback: AppTheme.fontFallback,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.onSignOut});
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudentSectionHeader(l10n.accountTitle, icon: Icons.person_outline_rounded),
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('profile-sign-out-button'),
            onTap: onSignOut,
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: StudentStyle.card(context),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5484D).withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout_rounded, color: Color(0xFFE5484D), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.logout,
                      style: const TextStyle(
                        color: Color(0xFFE5484D),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        fontFamilyFallback: AppTheme.fontFallback,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AdaptiveColors.muted(context)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

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
      label: AppLocalizations.of(context).loading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            block(26, width: 140, radius: 8),
            const SizedBox(height: 8),
            block(14, width: 260, radius: 6),
            const SizedBox(height: 20),
            block(110),
            const SizedBox(height: 16),
            block(90),
            const SizedBox(height: 24),
            block(220),
          ],
        ),
      ),
    );
  }
}
