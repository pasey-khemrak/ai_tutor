import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../auth/rean_logo_mark.dart';
import 'add_goal_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Khemarak Pasey';
  String _email = 'khemarakpasey@gmail.com';
  String _grade = 'Grade 12';
  String _goals =
      'Currently focusing on advanced Calculus and preparing for the upcoming Physics Olympiad. I want to master quantum mechanics basics by next month.';
  String? _profileImagePath;
  Uint8List? _profileImageBytes;

  void _openAddGoal() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddGoalScreen()));
  }

  Future<void> _openEditProfile() async {
    final result = await Navigator.of(context).push<EditProfileResult>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          name: _name,
          email: _email,
          grade: _grade,
          goals: _goals,
          imagePath: _profileImagePath,
          imageBytes: _profileImageBytes,
          onLogout: widget.onLogout,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _name = result.name;
      _email = result.email;
      _grade = result.grade;
      _goals = result.goals;
      _profileImagePath = result.imagePath;
      _profileImageBytes = result.imageBytes;
    });
    _showSavedMessage(context);
  }

  void _openSettings() {
    _showSettingsMessage(context);
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => const _LogoutConfirmDialog(),
    );
    if (shouldLogout == true) {
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF080D19), Color(0xFF09101E), Color(0xFF10112A)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileTopBar(
              onOpenSettings: _openSettings,
              onLogout: _confirmLogout,
            ),
            const SizedBox(height: 22),
            _ProfileAvatar(
              imagePath: _profileImagePath,
              imageBytes: _profileImageBytes,
            ),
            const SizedBox(height: 16),
            const ReanBrandName(fontSize: 25),
            const SizedBox(height: 10),
            Text(
              _name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '$_grade - Student Profile',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8BA0FF),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                onPressed: _openEditProfile,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue,
                  side: BorderSide(color: AppColors.blue.withValues(alpha: .5)),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            _ProfileField(
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
              value: _name,
            ),
            const SizedBox(height: 18),
            _ProfileField(
              label: 'Email Address',
              icon: Icons.mail_outline_rounded,
              value: _email,
            ),
            const SizedBox(height: 18),
            _ProfileField(
              label: 'Grade Level',
              icon: Icons.school_outlined,
              value: _grade,
            ),
            const SizedBox(height: 18),
            _LearningGoalsBox(goals: _goals),
            const SizedBox(height: 12),
            _GoalChips(onAddGoal: _openAddGoal),
          ],
        ),
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({required this.onOpenSettings, required this.onLogout});

  final VoidCallback onOpenSettings;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox.square(
          dimension: 32,
          child: IconButton(
            tooltip: 'Settings',
            onPressed: onOpenSettings,
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.settings_outlined,
              color: Color(0xFFDDE4FF),
              size: 21,
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFFDDE4FF),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onLogout,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFFF6B6B),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            minimumSize: const Size(0, 38),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          child: const Text('Logout'),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.imagePath, required this.imageBytes});

  final String? imagePath;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 118,
        height: 118,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFF0B1732), Color(0xFF071128), Color(0xFF050A1D)],
            stops: [0, .62, 1],
          ),
          border: Border.all(color: AppColors.blue, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: .26),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipOval(
          child: ProfileAvatarImage(
            imageBytes: imageBytes,
            imagePath: imagePath,
          ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.icon,
    required this.value,
  });

  final String label;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF96A0CF),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            color: const Color(0xFF090D19).withValues(alpha: .9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.blue.withValues(alpha: .32)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF8BA0FF), size: 17),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFDDE4FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LearningGoalsBox extends StatelessWidget {
  const _LearningGoalsBox({required this.goals});

  final String goals;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Learning Goals',
          style: TextStyle(
            color: Color(0xFF96A0CF),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: const Color(0xFF090D19).withValues(alpha: .9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.blue.withValues(alpha: .32)),
          ),
          child: Text(
            goals,
            style: const TextStyle(
              color: Color(0xFFDDE4FF),
              fontSize: 13,
              height: 1.38,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalChips extends StatelessWidget {
  const _GoalChips({required this.onAddGoal});

  final VoidCallback onAddGoal;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        const _GoalChip(label: '#Physics'),
        const _GoalChip(label: '#Mathematics'),
        _AddGoalButton(onTap: onAddGoal),
      ],
    );
  }
}

class _AddGoalButton extends StatelessWidget {
  const _AddGoalButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: .22),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 15),
              SizedBox(width: 5),
              Text(
                'Add Goal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withValues(alpha: .24)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF8BA0FF),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LogoutConfirmDialog extends StatelessWidget {
  const _LogoutConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF090D19),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.blue.withValues(alpha: .32)),
      ),
      title: const Text(
        'Logout?',
        style: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: const Text(
        'Are you sure you want to sign out of your account?',
        style: TextStyle(
          color: Color(0xFF96A0CF),
          fontSize: 13,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.logout_rounded, size: 17),
          label: const Text('Logout'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}

void _showSavedMessage(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Profile changes saved.'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.blue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

void _showSettingsMessage(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Settings preview'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.blue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}