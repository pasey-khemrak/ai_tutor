import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.isLoading = false, this.onOpenTab});

  final bool isLoading;
  final ValueChanged<int>? onOpenTab;

  void _openTab(BuildContext context, int index) {
    final onOpenTab = this.onOpenTab;
    if (onOpenTab == null) {
      _showDashboardMessage(context, 'This action is ready to connect.');
      return;
    }

    onOpenTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF080D19),
            Color(0xFF09101E),
            Color(0xFF10112A),
            Color(0xFF171342),
          ],
          stops: [0, .46, .74, 1],
        ),
      ),
      child: isLoading
          ? const _DashboardLoadingState()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 30, 26, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _GreetingHeader(),
                  const SizedBox(height: 24),
                  const _StreakCard(),
                  const SizedBox(height: 2),
                  _StartLearningCard(
                    onStartLearning: () => _openTab(context, 1),
                    onScanProblem: () =>
                        _showDashboardMessage(context, 'Scan problem preview'),
                    onSpeakToTutor: () => _openTab(context, 2),
                  ),
                  const SizedBox(height: 18),
                  _QuickActions(
                    onAsk: () => _openTab(context, 1),
                    onScan: () =>
                        _showDashboardMessage(context, 'Camera scan preview'),
                    onVoice: () => _openTab(context, 2),
                    onQuiz: () => _openTab(context, 3),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Continue Learning',
                    action: 'View all',
                    onActionTap: () =>
                        _showDashboardMessage(context, 'All lessons preview'),
                  ),
                  const SizedBox(height: 14),
                  _ContinueLessonCard(onContinue: () => _openTab(context, 1)),
                  const SizedBox(height: 24),
                  const _LearningPlan(),
                  const SizedBox(height: 26),
                  const _SubjectProgress(),
                  const SizedBox(height: 28),
                  const _StrengthenCard(),
                  const SizedBox(height: 28),
                  const _SectionHeader(title: 'Recommended for You'),
                  const SizedBox(height: 14),
                  _RecommendationCard(
                    onStartLesson: () => _openTab(context, 1),
                  ),
                  const SizedBox(height: 30),
                  const _RecentActivity(),
                  const SizedBox(height: 24),
                  const _DashboardEmptyState(),
                ],
              ),
            ),
    );
  }
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(26, 42, 26, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _LoadingHeader(),
          SizedBox(height: 28),
          _LoadingStreakCard(),
          SizedBox(height: 2),
          _LoadingExploreCard(),
          SizedBox(height: 18),
          _LoadingQuickActions(),
        ],
      ),
    );
  }
}

class _LoadingHeader extends StatelessWidget {
  const _LoadingHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _SkeletonCircle(size: 54),
        const SizedBox(width: 18),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(width: 132, height: 18, radius: 5),
              SizedBox(height: 12),
              _SkeletonBox(width: 92, height: 12, radius: 5),
            ],
          ),
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF12182A),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: .05)),
          ),
          child: Icon(
            Icons.notifications_rounded,
            color: const Color(0xFF2A3154).withValues(alpha: .6),
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _LoadingStreakCard extends StatelessWidget {
  const _LoadingStreakCard();

  @override
  Widget build(BuildContext context) {
    return _LoadingPanel(
      height: 88,
      borderRadius: 27,
      child: Row(
        children: [
          const _RoundIcon(
            icon: Icons.local_fire_department_rounded,
            background: Color(0xFF2A2E48),
            color: Color(0xFF8A4F4A),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: 150, height: 16, radius: 5),
                SizedBox(height: 12),
                _SkeletonBox(width: 118, height: 13, radius: 5),
              ],
            ),
          ),
          Row(
            children: List.generate(5, (index) {
              return Container(
                width: 11,
                height: 11,
                margin: const EdgeInsets.only(left: 9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < 3
                      ? const Color(0xFF8A4F4A)
                      : const Color(0xFF20263B),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _LoadingExploreCard extends StatelessWidget {
  const _LoadingExploreCard();

  @override
  Widget build(BuildContext context) {
    return _LoadingPanel(
      minHeight: 406,
      borderRadius: 28,
      padding: const EdgeInsets.fromLTRB(28, 52, 28, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 220, height: 32, radius: 5),
                    SizedBox(height: 15),
                    _SkeletonBox(width: 164, height: 32, radius: 5),
                    SizedBox(height: 28),
                    _SkeletonBox(width: 188, height: 18, radius: 5),
                  ],
                ),
              ),
              _MathTiles(),
            ],
          ),
          const SizedBox(height: 42),
          const _SkeletonBox(width: double.infinity, height: 62, radius: 18),
          const SizedBox(height: 18),
          Row(
            children: const [
              Expanded(
                child: _SkeletonBox(
                  width: double.infinity,
                  height: 56,
                  radius: 17,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: _SkeletonBox(
                  width: double.infinity,
                  height: 56,
                  radius: 17,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingQuickActions extends StatelessWidget {
  const _LoadingQuickActions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF090D19).withValues(alpha: .7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          _LoadingAction(),
          _LoadingAction(),
          _LoadingAction(),
          _LoadingAction(),
        ],
      ),
    );
  }
}

class _LoadingAction extends StatelessWidget {
  const _LoadingAction();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SkeletonBox(width: 56, height: 56, radius: 17),
        SizedBox(height: 10),
        _SkeletonBox(width: 38, height: 8, radius: 4),
      ],
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({
    required this.child,
    this.height,
    this.minHeight,
    this.borderRadius = 22,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final double? height;
  final double? minHeight;
  final double borderRadius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      constraints: minHeight == null
          ? null
          : BoxConstraints(minHeight: minHeight!),
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF121725).withValues(alpha: .88),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: child,
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return _SkeletonBox(width: size, height: size, radius: size / 2);
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFF20263A).withValues(alpha: .55),
            const Color(0xFF2C3248).withValues(alpha: .65),
            const Color(0xFF20263A).withValues(alpha: .55),
          ],
          stops: const [0, .55, 1],
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _AvatarMark(),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning, Brathna',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Grade 11 - Let\'s continue learning',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF96A0CF),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox.square(
          dimension: 38,
          child: IconButton.filled(
            onPressed: () =>
                _showDashboardMessage(context, 'No new notifications'),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF090D19),
              side: BorderSide(color: AppColors.blue.withValues(alpha: .55)),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(
              Icons.notifications_rounded,
              color: Color(0xFFDDE4FF),
              size: 17,
            ),
          ),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.fromLTRB(20, 17, 17, 17),
      borderColor: AppColors.blue.withValues(alpha: .52),
      child: Row(
        children: [
          const _RoundIcon(
            icon: Icons.local_fire_department_rounded,
            background: Color(0xFF17235C),
            color: Color(0xFF8BA0FF),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '5-day streak',
                  style: TextStyle(
                    color: Color(0xFFDDE4FF),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'You\'re on fire! Keep it up.',
                  style: TextStyle(
                    color: Color(0xFF96A0CF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: List.generate(8, (index) {
              return Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < 6 ? AppColors.blue : const Color(0xFF2A3154),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StartLearningCard extends StatelessWidget {
  const _StartLearningCard({
    required this.onStartLearning,
    required this.onScanProblem,
    required this.onSpeakToTutor,
  });

  final VoidCallback onStartLearning;
  final VoidCallback onScanProblem;
  final VoidCallback onSpeakToTutor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF090D19), Color(0xFF10112A), Color(0xFF171342)],
        ),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: AppColors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What would\nyou like to\nexplore today?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'I\'m ready to help you with\nyour lessons.',
                      style: TextStyle(
                        color: Color(0xFF8BA0FF),
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _MathTiles(),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 58,
            child: FilledButton.icon(
              onPressed: onStartLearning,
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text('Start Learning'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _TinyAction(
                  icon: Icons.center_focus_strong_rounded,
                  label: 'Scan Problem',
                  onTap: onScanProblem,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _TinyAction(
                  icon: Icons.mic_rounded,
                  label: 'Speak to Tutor',
                  onTap: onSpeakToTutor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onAsk,
    required this.onScan,
    required this.onVoice,
    required this.onQuiz,
  });

  final VoidCallback onAsk;
  final VoidCallback onScan;
  final VoidCallback onVoice;
  final VoidCallback onQuiz;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        Icons.chat_bubble_rounded,
        'ASK',
        Color(0xFF2940D5),
        Color(0xFF8A78FF),
        onAsk,
      ),
      (
        Icons.camera_alt_rounded,
        'SCAN',
        Color(0xFF17235C),
        Color(0xFF8BA0FF),
        onScan,
      ),
      (
        Icons.mic_rounded,
        'VOICE',
        Color(0xFF211C65),
        Color(0xFF8A78FF),
        onVoice,
      ),
      (
        Icons.local_fire_department_rounded,
        'QUIZ',
        Color(0xFF432035),
        Color(0xFFFF7046),
        onQuiz,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF090D19).withValues(alpha: .92),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final item in actions)
            InkWell(
              onTap: item.$5,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: Column(
                  children: [
                    _RoundIcon(
                      icon: item.$1,
                      background: item.$3,
                      color: item.$4,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.$2,
                      style: const TextStyle(
                        color: Color(0xFFC6CAE9),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onActionTap});

  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onActionTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                action!,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ContinueLessonCard extends StatelessWidget {
  const _ContinueLessonCard({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: const [
              _MiniChart(size: 54),
              SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Linear Equations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Mathematics - Step 3\nof 5',
                      style: TextStyle(
                        color: Color(0xFF96A0CF),
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '60%',
                style: TextStyle(
                  color: Color(0xFF8BA0FF),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _ProgressBar(value: .6),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Continue Lesson',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningPlan extends StatelessWidget {
  const _LearningPlan();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Text(
          'Today\'s Learning Plan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 14),
        _PlanTile(
          icon: Icons.assignment_rounded,
          title: 'Review Physics Quiz',
          subtitle: 'Laws of Thermodynamics',
          color: Color(0xFF6E43E5),
        ),
        SizedBox(height: 10),
        _PlanTile(
          icon: Icons.menu_book_rounded,
          title: 'English Grammar',
          subtitle: 'Complex Sentences',
          color: Color(0xFF02B7D3),
        ),
      ],
    );
  }
}

class _SubjectProgress extends StatelessWidget {
  const _SubjectProgress();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Text(
          'Subject Progress',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SubjectCard(
                title: 'Mathematics',
                subtitle: 'Calculus',
                percent: '78%',
                value: .78,
                color: AppColors.blue,
                child: _MiniChart(size: 44),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: _SubjectCard(
                title: 'Physics',
                subtitle: 'Optics',
                percent: '45%',
                value: .45,
                color: Color(0xFF8BA0FF),
                child: _AtomMark(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StrengthenCard extends StatelessWidget {
  const _StrengthenCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      borderColor: const Color(0xFF31245B),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Text(
            'Let\'s strengthen this',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 18),
          _FocusTile(
            title: 'Finding the y-intercept',
            subtitle: 'Mathematics - 42% accuracy',
            chip: 'Study',
          ),
          SizedBox(height: 12),
          _FocusTile(
            title: 'Newton\'s Second Law',
            subtitle: 'Physics - Practice needed',
            chip: 'Practice',
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.onStartLesson});

  final VoidCallback onStartLesson;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: EdgeInsets.zero,
      borderColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 178,
              child: CustomPaint(painter: _SlopePainter()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          'Understanding Slope\nVisually',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            height: 1.18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withValues(alpha: .22),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Color(0xFF8BA0FF),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'A deep dive into how changing m affects\nlinear graphs.',
                    style: TextStyle(
                      color: Color(0xFF96A0CF),
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onStartLesson,
                      icon: const Icon(
                        Icons.play_circle_fill_rounded,
                        color: Color(0xFF8BA0FF),
                        size: 18,
                      ),
                      label: const Text('Start Lesson'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: .1),
                        ),
                        backgroundColor: const Color(0xFF11172E),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Text(
          'Recent Activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 18),
        _ActivityItem(
          color: AppColors.blue,
          title: 'Completed Linear Equation lesson',
          time: '2 hours ago',
        ),
        SizedBox(height: 16),
        _ActivityItem(
          color: Color(0xFF7C5BFF),
          title: 'Mastered Verb Conjugations',
          time: 'Yesterday',
        ),
        SizedBox(height: 16),
        _ActivityItem(
          color: Color(0xFFFF7046),
          title: 'Achieved Perfect Quiz Score in Physics',
          time: '2 days ago',
        ),
      ],
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      borderColor: Colors.white.withValues(alpha: .08),
      child: const Row(
        children: [
          _RoundIcon(
            icon: Icons.inbox_outlined,
            background: Color(0xFF11172E),
            color: Color(0xFF8BA0FF),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Empty state ready',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'When there is no activity, lessons, or progress, this card can be shown.',
                  style: TextStyle(
                    color: Color(0xFF96A0CF),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MathTiles extends StatelessWidget {
  const _MathTiles();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Color(0xFFFFCA45), Icons.remove_rounded),
      (Color(0xFF2AB9F5), Icons.add_rounded),
      (Color(0xFFFF7046), Icons.close_rounded),
      (Color(0xFF74D957), Icons.remove_rounded),
    ];

    return SizedBox(
      width: 65,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items)
            Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: item.$1,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(item.$2, size: 20, color: const Color(0xFF0F1930)),
            ),
        ],
      ),
    );
  }
}

class _TinyAction extends StatelessWidget {
  const _TinyAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF090D19).withValues(alpha: .9),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withValues(alpha: .1)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF8BA0FF), size: 16),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFDDE4FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showDashboardMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.blue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      borderColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          _RoundIcon(
            icon: icon,
            background: color.withValues(alpha: .18),
            color: color,
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFDDE4FF),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF96A0CF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF7680A6)),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.title,
    required this.subtitle,
    required this.percent,
    required this.value,
    required this.color,
    required this.child,
  });

  final String title;
  final String subtitle;
  final String percent;
  final double value;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      borderColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFDDE4FF),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF96A0CF),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                percent,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _ProgressBar(
                  value: value,
                  color: color,
                  height: 4,
                  background: const Color(0xFF242A42),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FocusTile extends StatelessWidget {
  const _FocusTile({
    required this.title,
    required this.subtitle,
    required this.chip,
  });

  final String title;
  final String subtitle;
  final String chip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1323),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFDDE4FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF735CFF),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF211545),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              chip,
              style: const TextStyle(
                color: Color(0xFF8E78FF),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.color,
    required this.title,
    required this.time,
  });

  final Color color;
  final String title;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Icon(Icons.circle, color: color, size: 8),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFDDE4FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: const TextStyle(
                  color: Color(0xFF747A9B),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF090D19).withValues(alpha: .88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: .05),
        ),
      ),
      child: child,
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.background,
    required this.color,
  });

  final IconData icon;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    this.color = AppColors.blue,
    this.background = const Color(0xFF111627),
    this.height = 7,
  });

  final double value;
  final Color color;
  final Color background;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        color: color,
        backgroundColor: background,
      ),
    );
  }
}

class _AvatarMark extends StatelessWidget {
  const _AvatarMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFF080D19),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.blue, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: .28),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/ai_tutor_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _MiniChart extends StatelessWidget {
  const _MiniChart({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MiniChartPainter()),
    );
  }
}

class _AtomMark extends StatelessWidget {
  const _AtomMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: CustomPaint(painter: _AtomPainter()),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF090D19);
    final grid = Paint()
      ..color = AppColors.blue.withValues(alpha: .14)
      ..strokeWidth = 1;
    final axis = Paint()
      ..color = Colors.white.withValues(alpha: .18)
      ..strokeWidth = 1.2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(5)),
      bg,
    );
    for (var i = 1; i < 4; i++) {
      final p = size.width * i / 4;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), grid);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), grid);
    }
    canvas.drawLine(
      Offset(4, size.height - 9),
      Offset(size.width - 4, size.height - 9),
      axis,
    );
    canvas.drawLine(Offset(9, 4), Offset(9, size.height - 4), axis);

    final path = Path()
      ..moveTo(10, size.height - 12)
      ..quadraticBezierTo(
        size.width * .45,
        size.height * .34,
        size.width - 8,
        size.height * .58,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF8BA0FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(size.width * .38, size.height * .45),
      size.width * .1,
      Paint()..color = const Color(0xFFFF7046),
    );
    canvas.drawCircle(
      Offset(size.width * .67, size.height * .56),
      size.width * .055,
      Paint()..color = const Color(0xFF8BA0FF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AtomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFA091FF);

    for (final angle in [0.0, math.pi / 3, -math.pi / 3]) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * .95,
          height: size.height * .34,
        ),
        paint,
      );
      canvas.restore();
    }
    canvas.drawCircle(center, 5, Paint()..color = const Color(0xFF8BA0FF));
    canvas.drawCircle(
      Offset(size.width * .76, size.height * .27),
      4,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(size.width * .25, size.height * .7),
      4,
      Paint()..color = const Color(0xFF8F78FF),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SlopePainter extends CustomPainter {
  const _SlopePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black, Color(0xFF02130C)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final grid = Paint()
      ..color = const Color(0xFF0BE658).withValues(alpha: .13)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final baseY = size.height * .68;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    Path curve(double peak, double spread, double lift) {
      final path = Path()..moveTo(0, baseY);
      for (var i = 0; i <= size.width; i++) {
        final x = i.toDouble();
        final center = size.width * .32;
        final value = math.exp(-math.pow((x - center) / spread, 2));
        path.lineTo(x, baseY - value * peak + (x / size.width) * lift);
      }
      return path;
    }

    for (final spec in [
      (const Color(0xFFFF7145), 86.0, 48.0, 3.0),
      (const Color(0xFFFFFF50), 74.0, 65.0, -5.0),
      (const Color(0xFF0DFF8C), 48.0, 92.0, -10.0),
    ]) {
      glow.color = spec.$1.withValues(alpha: .35);
      line.color = spec.$1;
      final path = curve(spec.$2, spec.$3, spec.$4);
      canvas.drawPath(path, glow);
      canvas.drawPath(path, line);
    }

    final perspective = Paint()
      ..color = const Color(0xFF0BE658).withValues(alpha: .34)
      ..strokeWidth = 1;
    for (var x = -50.0; x < size.width + 50; x += 20) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(size.width * .5, baseY),
        perspective,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
