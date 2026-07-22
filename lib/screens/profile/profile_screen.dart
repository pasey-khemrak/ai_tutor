import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

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
              onBack: () => setState(() => _showSettings = false),
              onNotificationsChanged: (value) {
                setState(() => _notifications = value);
              },
              onSoundChanged: (value) => setState(() => _sound = value),
              onDarkModeChanged: (value) => setState(() => _darkMode = value),
            )
          : EditProfileView(
              key: const ValueKey('edit-profile-view'),
              onBack: widget.onBack,
              onSettings: () => setState(() => _showSettings = true),
            ),
    );
  }
}

class EditProfileView extends StatelessWidget {
  const EditProfileView({
    super.key,
    required this.onBack,
    required this.onSettings,
  });

  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileTopBar(
          title: 'Edit Profile',
          onBack: onBack,
          trailing: IconButton(
            tooltip: 'Settings',
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined, color: AppColors.subtle),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ProfileIdentity(),
                const SizedBox(height: 42),
                const ProfileField(
                  label: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  value: 'Khemrak Pasey',
                ),
                const SizedBox(height: 24),
                const ProfileField(
                  label: 'Email Address',
                  icon: Icons.mail_outline_rounded,
                  value: 'khemrakpasey@gmail.com',
                ),
                const SizedBox(height: 24),
                const ProfileField(
                  label: 'Grade Level',
                  icon: Icons.school_outlined,
                  value: 'Grade 12',
                  trailing: Icons.keyboard_arrow_down_rounded,
                ),
                const SizedBox(height: 24),
                const ProfileField(
                  label: 'Learning Goals',
                  value:
                      'Currently focusing on advanced Calculus and preparing for the upcoming Physics Olympiad. I want to master quantum mechanics basics by the end of the semester.',
                  minHeight: 160,
                ),
                const SizedBox(height: 14),
                const GoalChips(),
                const SizedBox(height: 34),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Changes'),
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
                const Text(
                  'Changes are synced across your Lumina AI ecosystem.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
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

class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.notifications,
    required this.sound,
    required this.darkMode,
    required this.onBack,
    required this.onNotificationsChanged,
    required this.onSoundChanged,
    required this.onDarkModeChanged,
  });

  final bool notifications;
  final bool sound;
  final bool darkMode;
  final VoidCallback onBack;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<bool> onDarkModeChanged;

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
                const SettingsSectionTitle('គណនី'),
                const SettingsGroup(
                  children: [
                    SettingsRow(
                      icon: Icons.lock_outline_rounded,
                      title: 'ផ្លាស់ប្ដូរពាក្យសម្ងាត់',
                      subtitle: 'ធ្វើបច្ចុប្បន្នភាពព័ត៌មានសុវត្ថិភាព',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.muted,
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.shield_outlined,
                      title: 'ឯកជនភាព',
                      subtitle: 'គ្រប់គ្រងការចែករំលែកទិន្នន័យនិងការមើលឃើញ',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const SettingsSectionTitle('ការសិក្សា'),
                SettingsGroup(
                  children: [
                    const SettingsRow(
                      icon: Icons.trending_up_rounded,
                      iconColor: AppColors.cyan,
                      title: 'កម្រិតខ្ញុំ',
                      subtitle: 'Currently set to Advanced',
                      trailing: PillLabel(label: 'ខ្ពស់'),
                    ),
                    const SettingsRow(
                      icon: Icons.power_settings_new_rounded,
                      iconColor: AppColors.cyan,
                      title: 'គោលដៅប្រចាំថ្ងៃ',
                      subtitle: 'រៀនជាមធ្យមរយៈពេល ២ម៉ោងក្នុងមួយថ្ងៃ',
                      trailing: Icon(Icons.edit_outlined, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const SettingsSectionTitle('ការជូនដំណឹង'),
                SettingsGroup(
                  children: [
                    SettingsRow(
                      icon: Icons.notifications_none_rounded,
                      iconColor: const Color(0xFFC9A8FF),
                      title: 'ការរំលឹក',
                      subtitle: 'គ្រប់គ្រងការរំលឹកសិក្សា',
                      trailing: AppSwitch(
                        value: notifications,
                        onChanged: onNotificationsChanged,
                      ),
                    ),
                    SettingsRow(
                      icon: Icons.volume_up_outlined,
                      iconColor: const Color(0xFFC9A8FF),
                      title: 'សំឡេង',
                      subtitle: 'សំឡេងប៊ូតុង និងការឆ្លើយតប',
                      trailing: AppSwitch(
                        value: sound,
                        onChanged: onSoundChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const SettingsSectionTitle('រូបរាង'),
                SettingsGroup(
                  children: [
                    SettingsRow(
                      icon: Icons.dark_mode_outlined,
                      iconColor: const Color(0xFFC9A8FF),
                      title: 'រូបរាងផ្ទៃក្រោយងងឹត',
                      subtitle: 'OLED optimized deep blacks',
                      trailing: AppSwitch(
                        value: darkMode,
                        onChanged: onDarkModeChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const SettingsSectionTitle('ជំនួយ'),
                const SettingsGroup(
                  children: [
                    SettingsRow(
                      icon: Icons.help_outline_rounded,
                      title: 'មជ្ឈមណ្ឌលជំនួយ',
                      subtitle: 'FAQs and documentation',
                      trailing: Icon(Icons.open_in_new_rounded, color: AppColors.muted),
                    ),
                    SettingsRow(
                      icon: Icons.feedback_outlined,
                      title: 'ការយល់ឃើញ',
                      subtitle: 'ផ្ញើមតិយោបល់ទៅកាន់ក្រុម Rean',
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
                    side: BorderSide(color: AppColors.line),
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
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Back',
            onPressed: onBack ?? () {},
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.subtle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
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
  const ProfileIdentity({super.key});

  @override
  Widget build(BuildContext context) {
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
                child: const Text(
                  'ថ្នាក់ ១២',
                  style: TextStyle(
                    color: Color(0xFF082834),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'ឈ្មោះ: បាសី',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 31,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Khemrak  Pasey',
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

class ProfileField extends StatelessWidget {
  const ProfileField({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trailing,
    this.minHeight = 84,
  });

  final String label;
  final String value;
  final IconData? icon;
  final IconData? trailing;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.subtle,
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
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            crossAxisAlignment: minHeight > 100
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.muted, size: 22),
                const SizedBox(width: 26),
              ],
              Expanded(
                child: Text(
                  value,
                  maxLines: minHeight > 100 ? 5 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.subtle,
                    fontSize: 21,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                Icon(trailing, color: AppColors.muted),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class GoalChips extends StatelessWidget {
  const GoalChips({super.key});

  @override
  Widget build(BuildContext context) {
    const labels = ['#Physics', '#Mathematics', '+ Add Goal'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final label in labels)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFC9A8FF),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.subtle,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 92, right: 24),
                child: Divider(color: AppColors.line, height: 1),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 23),
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
                    color: AppColors.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7F86B8),
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
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
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.cyan,
      activeTrackColor: AppColors.blue,
      inactiveThumbColor: AppColors.muted,
      inactiveTrackColor: AppColors.line,
    );
  }
}

class MiniProfileAvatar extends StatelessWidget {
  const MiniProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
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
      child: const Icon(Icons.person_rounded, color: AppColors.subtle),
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
      ..cubicTo(size.width * .42, size.height * .68, size.width * .42, size.height * .42, size.width * .5, size.height * .28)
      ..cubicTo(size.width * .58, size.height * .42, size.width * .58, size.height * .68, size.width * .64, size.height * .9)
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
        ..cubicTo(-size.width * .18, size.height * .2, -size.width * .15, -size.height * .08, 0, -size.height * .13)
        ..cubicTo(size.width * .17, -size.height * .04, size.width * .17, size.height * .22, 0, size.height * .36)
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
