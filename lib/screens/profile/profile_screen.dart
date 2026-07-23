import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme_controller.dart';

class ProfilePalette {
  const ProfilePalette._();

  static bool isLight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light;
  }

  static Color text(BuildContext context) {
    return isLight(context) ? const Color(0xFF172033) : AppColors.text;
  }

  static Color subtle(BuildContext context) {
    return isLight(context) ? const Color(0xFF3C465D) : AppColors.subtle;
  }

  static Color muted(BuildContext context) {
    return isLight(context) ? const Color(0xFF69738A) : AppColors.muted;
  }

  static Color label(BuildContext context) {
    return isLight(context) ? const Color(0xFF7C8498) : AppColors.subtle;
  }

  static Color panel(BuildContext context) {
    return isLight(context) ? Colors.white : AppColors.panel;
  }

  static Color card(BuildContext context) {
    return isLight(context) ? Colors.white : AppColors.card;
  }

  static Color line(BuildContext context) {
    return isLight(context) ? const Color(0xFFD8DEEC) : AppColors.line;
  }

  static Color subtitle(BuildContext context) {
    return isLight(context) ? const Color(0xFF5D687F) : const Color(0xFF7F86B8);
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showSettings = false;
  bool _notifications = true;
  bool _sound = false;
  bool _darkMode = true;
  String _level = 'Advanced';
  String _goal =
      'Currently focusing on advanced Calculus and preparing for Physics.';

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _showSettings
          ? SettingsView(
              key: const ValueKey('settings-view'),
              notifications: _notifications,
              sound: _sound,
              darkMode: _darkMode,
              level: _level,
              goal: _goal,
              onBack: () => setState(() => _showSettings = false),
              onNotificationsChanged: (value) {
                setState(() => _notifications = value);
              },
              onSoundChanged: (value) => setState(() => _sound = value),
              onDarkModeChanged: (value) {
                setState(() => _darkMode = value);
                AppThemeController.setDarkMode(value);
              },
              onLevelChanged: (value) => setState(() => _level = value),
              onGoalChanged: (value) => setState(() => _goal = value),
            )
          : EditProfileView(
              key: const ValueKey('edit-profile-view'),
              onBack: widget.onBack,
              onSettings: () => setState(() => _showSettings = true),
            ),
    );
  }
}

class EditProfileView extends StatefulWidget {
  const EditProfileView({
    super.key,
    required this.onBack,
    required this.onSettings,
  });

  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _schoolController;
  late final TextEditingController _dailyTargetController;
  late final TextEditingController _goalsController;
  String _gradeLevel = 'Grade 12';
  String _savedName = 'Khemrak Pasey';
  String _savedGrade = 'Grade 12';
  bool _isEditing = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _savedName);
    _emailController = TextEditingController(text: 'khemrakpasey@gmail.com');
    _schoolController = TextEditingController(text: 'Rean High School');
    _dailyTargetController = TextEditingController(text: '2 hours per day');
    _goalsController = TextEditingController(
      text:
          'Currently focusing on advanced Calculus and preparing for the upcoming Physics Olympiad.',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    _dailyTargetController.dispose();
    _goalsController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_isEditing) {
      setState(() {
        _isEditing = true;
        _saved = false;
      });
      return;
    }

    setState(() {
      _savedName = _nameController.text.trim().isEmpty
          ? 'Student'
          : _nameController.text.trim();
      _savedGrade = _gradeLevel;
      _isEditing = false;
      _saved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileTopBar(
          title: 'Profile',
          onBack: widget.onBack,
          trailing: IconButton(
            tooltip: 'Settings',
            onPressed: widget.onSettings,
            icon: Icon(
              Icons.settings_outlined,
              color: ProfilePalette.subtle(context),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileIdentity(name: _savedName, gradeLevel: _savedGrade),
                const SizedBox(height: 42),
                ProfileTextField(
                  label: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  controller: _nameController,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 24),
                ProfileTextField(
                  label: 'Email Address',
                  icon: Icons.mail_outline_rounded,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 24),
                ProfileDropdownField(
                  label: 'Grade Level',
                  icon: Icons.school_outlined,
                  value: _gradeLevel,
                  options: const ['Grade 10', 'Grade 11', 'Grade 12'],
                  enabled: _isEditing,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _gradeLevel = value);
                    }
                  },
                ),
                const SizedBox(height: 24),
                ProfileTextField(
                  label: 'School',
                  icon: Icons.account_balance_outlined,
                  controller: _schoolController,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 24),
                ProfileTextField(
                  label: 'Daily Study Target',
                  icon: Icons.schedule_outlined,
                  controller: _dailyTargetController,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 24),
                ProfileTextField(
                  label: 'Learning Goals',
                  controller: _goalsController,
                  minHeight: 150,
                  maxLines: 5,
                  enabled: _isEditing,
                ),
                const SizedBox(height: 14),
                GoalChips(enabled: _isEditing),
                const SizedBox(height: 34),
                FilledButton.icon(
                  onPressed: _saveProfile,
                  icon: Icon(
                    _isEditing ? Icons.save_outlined : Icons.edit_outlined,
                  ),
                  label: Text(_isEditing ? 'Save Profile' : 'Edit Profile'),
                  style: FilledButton.styleFrom(
                    fixedSize: const Size.fromHeight(64),
                    backgroundColor: AppColors.blue,
                    foregroundColor: AppColors.text,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _saved
                      ? 'Saved. Changes are synced across your Rean AI ecosystem.'
                      : _isEditing
                      ? 'Update your student information, then save your profile.'
                      : 'Changes are synced across your Rean AI ecosystem.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ).copyWith(color: ProfilePalette.muted(context)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.notifications,
    required this.sound,
    required this.darkMode,
    required this.level,
    required this.goal,
    required this.onBack,
    required this.onNotificationsChanged,
    required this.onSoundChanged,
    required this.onDarkModeChanged,
    required this.onLevelChanged,
    required this.onGoalChanged,
  });

  final bool notifications;
  final bool sound;
  final bool darkMode;
  final String level;
  final String goal;
  final VoidCallback onBack;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<bool> onDarkModeChanged;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<String> onGoalChanged;

  Future<void> _openPasswordDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const ChangePasswordDialog(),
    );
  }

  Future<void> _openLevelPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: ProfilePalette.panel(context),
      showDragHandle: true,
      builder: (sheetContext) {
        const levels = ['Low', 'Medium', 'High', 'Advanced'];
        final titleColor = ProfilePalette.text(sheetContext);
        final itemColor = ProfilePalette.subtle(sheetContext);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Level',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                for (final option in levels)
                  ListTile(
                    key: Key('level-$option'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      option,
                      style: TextStyle(
                        color: itemColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    trailing: option == level
                        ? const Icon(Icons.check_rounded, color: AppColors.cyan)
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(option),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      onLevelChanged(selected);
    }
  }

  Future<void> _openGoalDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => LearningGoalDialog(
        goal: goal,
        onGoalChanged: onGoalChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileTopBar(
          title: 'Settings',
          onBack: onBack,
          trailing: const MiniProfileAvatar(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SettingsSectionTitle('Account'),
                SettingsGroup(
                  children: [
                    SettingsRow(
                      key: const Key('settings-password-row'),
                      icon: Icons.lock_outline_rounded,
                      title: 'Password',
                      subtitle: 'Change your login password',
                      onTap: () => _openPasswordDialog(context),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.muted,
                      ),
                    ),
                    const SettingsRow(
                      icon: Icons.shield_outlined,
                      title: 'Privacy',
                      subtitle: 'Manage learning data visibility',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const SettingsSectionTitle('Learning'),
                SettingsGroup(
                  children: [
                    SettingsRow(
                      key: const Key('settings-level-row'),
                      icon: Icons.trending_up_rounded,
                      iconColor: AppColors.cyan,
                      title: 'My Level',
                      subtitle: 'Choose from low to high',
                      onTap: () => _openLevelPicker(context),
                      trailing: PillLabel(label: level),
                    ),
                    SettingsRow(
                      key: const Key('settings-goal-row'),
                      icon: Icons.flag_outlined,
                      iconColor: AppColors.cyan,
                      title: 'Daily Goal',
                      subtitle: goal,
                      onTap: () => _openGoalDialog(context),
                      trailing: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const SettingsSectionTitle('Notifications'),
                SettingsGroup(
                  children: [
                    SettingsRow(
                      key: const Key('settings-reminders-row'),
                      icon: Icons.notifications_none_rounded,
                      iconColor: const Color(0xFFC9A8FF),
                      title: 'Study Reminders',
                      subtitle: notifications
                          ? 'Notifications are allowed'
                          : 'Notifications are off',
                      onTap: () => onNotificationsChanged(!notifications),
                      trailing: AppSwitch(
                        value: notifications,
                        onChanged: onNotificationsChanged,
                      ),
                    ),
                    SettingsRow(
                      key: const Key('settings-sound-row'),
                      icon: Icons.volume_up_outlined,
                      iconColor: const Color(0xFFC9A8FF),
                      title: 'Sound',
                      subtitle: sound
                          ? 'Button and tutor sounds are on'
                          : 'Button and tutor sounds are off',
                      onTap: () => onSoundChanged(!sound),
                      trailing: AppSwitch(value: sound, onChanged: onSoundChanged),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const SettingsSectionTitle('Appearance'),
                SettingsGroup(
                  children: [
                    SettingsRow(
                      key: const Key('settings-theme-row'),
                      icon: Icons.dark_mode_outlined,
                      iconColor: const Color(0xFFC9A8FF),
                      title: darkMode ? 'Dark Mode' : 'Light Mode',
                      subtitle: darkMode
                          ? 'Using the dark Rean theme'
                          : 'Using a light learning theme',
                      onTap: () => onDarkModeChanged(!darkMode),
                      trailing: AppSwitch(
                        value: darkMode,
                        onChanged: onDarkModeChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const SettingsSectionTitle('Help'),
                const SettingsGroup(
                  children: [
                    SettingsRow(
                      icon: Icons.help_outline_rounded,
                      title: 'Help Center',
                      subtitle: 'FAQs and documentation',
                      trailing: Icon(
                        Icons.open_in_new_rounded,
                        color: AppColors.muted,
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.feedback_outlined,
                      title: 'Feedback',
                      subtitle: 'Send comments to the Rean team',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout from Rean'),
                  style: OutlinedButton.styleFrom(
                    fixedSize: const Size.fromHeight(64),
                    foregroundColor: const Color(0xFFFF5574),
                    side: BorderSide(color: ProfilePalette.line(context)),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileTopBar extends StatelessWidget {
  const ProfileTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final iconColor = ProfilePalette.subtle(context);

    return SizedBox(
      height: 72,
      child: Row(
        children: [
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Back',
            onPressed: onBack ?? () {},
            icon: Icon(Icons.arrow_back_rounded, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.cyan,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ?trailing,
          const SizedBox(width: 22),
        ],
      ),
    );
  }
}

class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({
    super.key,
    required this.name,
    required this.gradeLevel,
  });

  final String name;
  final String gradeLevel;

  @override
  Widget build(BuildContext context) {
    final nameColor = ProfilePalette.text(context);

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 156,
              height: 156,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: AppColors.blue, width: 3),
              ),
              child: ClipOval(child: CustomPaint(painter: BokChoyPainter())),
            ),
            Positioned(
              right: -4,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cyan,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  gradeLevel,
                  style: const TextStyle(
                    color: Color(0xFF082834),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: nameColor,
            fontSize: 31,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Student Profile',
          style: TextStyle(
            color: AppColors.cyan,
            fontSize: 18,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class ProfileTextField extends StatelessWidget {
  const ProfileTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.enabled,
    this.icon,
    this.keyboardType,
    this.minHeight = 84,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final IconData? icon;
  final TextInputType? keyboardType;
  final double minHeight;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final iconColor = ProfilePalette.muted(context);
    final fieldTextColor = ProfilePalette.text(context);

    return ProfileFieldShell(
      label: label,
      minHeight: minHeight,
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 20),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: TextStyle(
                color: fieldTextColor,
                fontSize: 18,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileDropdownField extends StatelessWidget {
  const ProfileDropdownField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final List<String> options;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final iconColor = ProfilePalette.muted(context);
    final fieldTextColor = ProfilePalette.text(context);
    final dropdownColor = ProfilePalette.panel(context);

    return ProfileFieldShell(
      label: label,
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 20),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                dropdownColor: dropdownColor,
                iconEnabledColor: iconColor,
                iconDisabledColor: iconColor,
                isExpanded: true,
                selectedItemBuilder: (context) => [
                  for (final option in options)
                    Text(
                      option,
                      style: TextStyle(
                        color: fieldTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
                style: TextStyle(
                  color: fieldTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                items: [
                  for (final option in options)
                    DropdownMenuItem(value: option, child: Text(option)),
                ],
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileFieldShell extends StatelessWidget {
  const ProfileFieldShell({
    super.key,
    required this.label,
    required this.child,
    this.minHeight = 84,
  });

  final String label;
  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final labelColor = ProfilePalette.label(context);
    final cardColor = ProfilePalette.card(context);
    final lineColor = ProfilePalette.line(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 18,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: lineColor),
          ),
          child: child,
        ),
      ],
    );
  }
}

class GoalChips extends StatelessWidget {
  const GoalChips({super.key, required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    const labels = ['#Physics', '#Mathematics', '+ Add Goal'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final label in labels)
          ActionChip(
            onPressed: enabled ? () {} : null,
            label: Text(label),
            labelStyle: const TextStyle(
              color: Color(0xFFC9A8FF),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: Colors.white.withValues(alpha: .12),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
      ],
    );
  }
}

class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final textColor = ProfilePalette.subtle(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final panelColor = ProfilePalette.panel(context);
    final lineColor = ProfilePalette.line(context);

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lineColor),
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 92, right: 24),
                child: Divider(color: lineColor, height: 1),
              ),
          ],
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.iconColor = AppColors.subtle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rowIconColor =
        iconColor == AppColors.subtle ? ProfilePalette.subtle(context) : iconColor;
    final iconBackground = ProfilePalette.card(context);
    final titleColor = ProfilePalette.text(context);
    final subtitleColor = ProfilePalette.subtitle(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: rowIconColor, size: 23),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ).copyWith(color: titleColor),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ).copyWith(color: subtitleColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsDialogField extends StatelessWidget {
  const SettingsDialogField({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final textColor = ProfilePalette.text(context);
    final labelColor = ProfilePalette.muted(context);
    final fillColor = ProfilePalette.card(context);
    final lineColor = ProfilePalette.line(context);

    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLines: obscure ? 1 : maxLines,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: labelColor),
        filled: true,
        fillColor: fillColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cyan, width: 1.4),
        ),
      ),
    );
  }
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  late final TextEditingController _currentController;
  late final TextEditingController _newController;
  late final TextEditingController _confirmController;

  @override
  void initState() {
    super.initState();
    _currentController = TextEditingController();
    _newController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panelColor = ProfilePalette.panel(context);
    final titleColor = ProfilePalette.text(context);

    return AlertDialog(
      backgroundColor: panelColor,
      title: Text(
        'Change Password',
        style: TextStyle(color: titleColor, fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsDialogField(
            key: const Key('current-password-field'),
            controller: _currentController,
            label: 'Current Password',
            obscure: true,
          ),
          const SizedBox(height: 12),
          SettingsDialogField(
            key: const Key('new-password-field'),
            controller: _newController,
            label: 'New Password',
            obscure: true,
          ),
          const SizedBox(height: 12),
          SettingsDialogField(
            key: const Key('confirm-password-field'),
            controller: _confirmController,
            label: 'Confirm Password',
            obscure: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('change-password-button'),
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password updated')),
            );
          },
          child: const Text('Change Password'),
        ),
      ],
    );
  }
}

class LearningGoalDialog extends StatefulWidget {
  const LearningGoalDialog({
    super.key,
    required this.goal,
    required this.onGoalChanged,
  });

  final String goal;
  final ValueChanged<String> onGoalChanged;

  @override
  State<LearningGoalDialog> createState() => _LearningGoalDialogState();
}

class _LearningGoalDialogState extends State<LearningGoalDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.goal);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panelColor = ProfilePalette.panel(context);
    final titleColor = ProfilePalette.text(context);

    return AlertDialog(
      backgroundColor: panelColor,
      title: Text(
        'Learning Goal',
        style: TextStyle(color: titleColor, fontWeight: FontWeight.w900),
      ),
      content: SettingsDialogField(
        key: const Key('learning-goal-field'),
        controller: _controller,
        label: 'Write your goal',
        maxLines: 5,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('save-goal-button'),
          onPressed: () {
            final value = _controller.text.trim();
            widget.onGoalChanged(value.isEmpty ? 'No goal set yet' : value);
            Navigator.of(context).pop();
          },
          child: const Text('Save Goal'),
        ),
      ],
    );
  }
}

class PillLabel extends StatelessWidget {
  const PillLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cyan.withValues(alpha: .65)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.cyan,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final mutedColor = ProfilePalette.muted(context);
    final lineColor = ProfilePalette.line(context);

    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.cyan,
      activeTrackColor: AppColors.blue,
      inactiveThumbColor: mutedColor,
      inactiveTrackColor: lineColor,
    );
  }
}

class MiniProfileAvatar extends StatelessWidget {
  const MiniProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final iconColor = ProfilePalette.subtle(context);

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.blue, width: 3),
        gradient: const LinearGradient(
          colors: [Color(0xFF12384A), Color(0xFF0E1425), Color(0xFF1A4856)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.person_rounded, color: iconColor),
    );
  }
}

class BokChoyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()..color = const Color(0xFFEAF1D9);
    final stemShadow = Paint()..color = const Color(0xFFC8D5B0);
    final leafPaint = Paint()..color = const Color(0xFF76A850);
    final darkLeafPaint = Paint()..color = const Color(0xFF4C812D);
    final veinPaint = Paint()
      ..color = Colors.white.withValues(alpha: .35)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height * .62);
    final stem = Path()
      ..moveTo(size.width * .36, size.height * .9)
      ..cubicTo(
        size.width * .42,
        size.height * .68,
        size.width * .42,
        size.height * .42,
        size.width * .5,
        size.height * .28,
      )
      ..cubicTo(
        size.width * .58,
        size.height * .42,
        size.width * .58,
        size.height * .68,
        size.width * .64,
        size.height * .9,
      )
      ..close();
    canvas.drawPath(stem, stemShadow);

    for (final data in [
      (Offset(size.width * .26, size.height * .24), -0.55, darkLeafPaint),
      (Offset(size.width * .38, size.height * .18), -0.25, leafPaint),
      (Offset(size.width * .52, size.height * .16), 0.05, darkLeafPaint),
      (Offset(size.width * .66, size.height * .2), 0.35, leafPaint),
      (Offset(size.width * .76, size.height * .28), 0.62, darkLeafPaint),
    ]) {
      canvas.save();
      canvas.translate(data.$1.dx, data.$1.dy);
      canvas.rotate(data.$2);
      final leaf = Path()
        ..moveTo(0, size.height * .36)
        ..cubicTo(
          -size.width * .18,
          size.height * .2,
          -size.width * .15,
          -size.height * .08,
          0,
          -size.height * .13,
        )
        ..cubicTo(
          size.width * .17,
          -size.height * .04,
          size.width * .17,
          size.height * .22,
          0,
          size.height * .36,
        )
        ..close();
      canvas.drawPath(leaf, data.$3);
      canvas.drawLine(Offset.zero, Offset(0, size.height * .32), veinPaint);
      canvas.restore();
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, size.height * .18),
        width: size.width * .34,
        height: size.height * .62,
      ),
      stemPaint,
    );
    canvas.drawLine(
      Offset(size.width * .5, size.height * .34),
      Offset(size.width * .5, size.height * .9),
      veinPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
