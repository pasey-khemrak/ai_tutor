import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';

class EditProfileResult {
  const EditProfileResult({
    required this.name,
    required this.email,
    required this.grade,
    required this.goals,
    required this.imagePath,
    required this.imageBytes,
  });

  final String name;
  final String email;
  final String grade;
  final String goals;
  final String? imagePath;
  final Uint8List? imageBytes;
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.name,
    required this.email,
    required this.grade,
    required this.goals,
    required this.imagePath,
    required this.imageBytes,
    required this.onLogout,
  });

  final String name;
  final String email;
  final String grade;
  final String goals;
  final String? imagePath;
  final Uint8List? imageBytes;
  final VoidCallback onLogout;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _goalsController;
  late String _grade;
  late String? _profileImagePath;
  late Uint8List? _profileImageBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _goalsController = TextEditingController(text: widget.goals);
    _grade = widget.grade;
    _profileImagePath = widget.imagePath;
    _profileImageBytes = widget.imageBytes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _goalsController.dispose();
    super.dispose();
  }

  Future<void> _chooseGrade() async {
    final selectedGrade = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _GradePickerSheet(selectedGrade: _grade),
    );
    if (selectedGrade != null) {
      setState(() => _grade = selectedGrade);
    }
  }

  Future<void> _chooseProfilePhoto() async {
    final selectedPhoto = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfilePhotoSheet(
        selectedImagePath: _profileImagePath,
        hasPhonePhoto: _profileImageBytes != null,
      ),
    );
    if (selectedPhoto == null) {
      return;
    }

    if (selectedPhoto == _pickPhonePhotoValue) {
      final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedImage == null) {
        return;
      }

      final imageBytes = await pickedImage.readAsBytes();
      setState(() {
        _profileImageBytes = imageBytes;
        _profileImagePath = null;
      });
      return;
    }

    setState(() {
      if (selectedPhoto == _removeProfilePhotoValue) {
        _profileImageBytes = null;
        _profileImagePath = null;
      } else {
        _profileImageBytes = null;
        _profileImagePath = selectedPhoto;
      }
    });
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

  void _saveProfile() {
    Navigator.pop(
      context,
      EditProfileResult(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        grade: _grade,
        goals: _goalsController.text.trim(),
        imagePath: _profileImagePath,
        imageBytes: _profileImageBytes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF080D19), Color(0xFF09101E), Color(0xFF10112A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EditTopBar(onLogout: _confirmLogout),
                const SizedBox(height: 22),
                _EditableAvatar(
                  imagePath: _profileImagePath,
                  imageBytes: _profileImageBytes,
                  onTap: _chooseProfilePhoto,
                ),
                const SizedBox(height: 28),
                _EditField(
                  label: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  controller: _nameController,
                ),
                const SizedBox(height: 18),
                _EditField(
                  label: 'Email Address',
                  icon: Icons.mail_outline_rounded,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 18),
                _GradeField(grade: _grade, onTap: _chooseGrade),
                const SizedBox(height: 18),
                _GoalsField(controller: _goalsController),
                const SizedBox(height: 26),
                SizedBox(
                  height: 58,
                  child: FilledButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save_outlined, size: 17),
                    label: const Text('Save Changes'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Changes are synced across your learning workspace.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF777D9E),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
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

class _EditTopBar extends StatelessWidget {
  const _EditTopBar({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox.square(
          dimension: 32,
          child: IconButton(
            tooltip: 'Back to profile',
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFFDDE4FF),
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'Edit Profile',
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

const _removeProfilePhotoValue = '__remove_profile_photo__';
const _pickPhonePhotoValue = '__pick_phone_photo__';

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.imagePath,
    required this.imageBytes,
    required this.onTap,
  });

  final String? imagePath;
  final Uint8List? imageBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 118,
              height: 118,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF0B1732),
                    Color(0xFF071128),
                    Color(0xFF050A1D),
                  ],
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
            Positioned(
              right: -2,
              bottom: 8,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF080D19), width: 3),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileAvatarImage extends StatelessWidget {
  const ProfileAvatarImage({
    super.key,
    required this.imageBytes,
    required this.imagePath,
  });

  final Uint8List? imageBytes;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes;
    if (bytes != null) {
      return Image.memory(bytes, width: 112, height: 112, fit: BoxFit.cover);
    }

    final path = imagePath;
    if (path != null) {
      return Image.asset(path, width: 112, height: 112, fit: BoxFit.cover);
    }

    return Container(
      width: 112,
      height: 112,
      color: const Color(0xFF11172E),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF8BA0FF),
        size: 58,
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.icon,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: label,
      icon: icon,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Color(0xFFDDE4FF),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
        decoration: const InputDecoration.collapsed(hintText: ''),
      ),
    );
  }
}

class _GradeField extends StatelessWidget {
  const _GradeField({required this.grade, required this.onTap});

  final String grade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      label: 'Grade Level',
      icon: Icons.school_outlined,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                grade,
                style: const TextStyle(
                  color: Color(0xFFDDE4FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF8BA0FF),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalsField extends StatelessWidget {
  const _GoalsField({required this.controller});

  final TextEditingController controller;

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
          child: TextField(
            controller: controller,
            maxLines: null,
            style: const TextStyle(
              color: Color(0xFFDDE4FF),
              fontSize: 13,
              height: 1.38,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration.collapsed(
              hintText: 'Add your learning goals',
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({
    required this.label,
    required this.icon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Widget child;

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
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfilePhotoSheet extends StatelessWidget {
  const _ProfilePhotoSheet({
    required this.selectedImagePath,
    required this.hasPhonePhoto,
  });

  final String? selectedImagePath;
  final bool hasPhonePhoto;

  @override
  Widget build(BuildContext context) {
    const options = [
      _ProfilePhotoOptionData(
        label: 'Study Avatar',
        imagePath: 'assets/images/ai_tutor_light.png',
      ),
      _ProfilePhotoOptionData(
        label: 'Learning Avatar',
        imagePath: 'assets/images/ai_tutor_brain.png',
      ),
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF090D19),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.blue.withValues(alpha: .34)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              icon: Icons.photo_camera_outlined,
              title: 'Profile Picture',
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
            _PhonePhotoOption(
              selected: hasPhonePhoto,
              onTap: () => Navigator.pop(context, _pickPhonePhotoValue),
            ),
            const SizedBox(height: 10),
            for (final option in options) ...[
              _ProfilePhotoOption(
                label: option.label,
                imagePath: option.imagePath,
                selected: selectedImagePath == option.imagePath,
                onTap: () => Navigator.pop(context, option.imagePath),
              ),
              const SizedBox(height: 10),
            ],
            _RemovePhotoOption(
              selected: selectedImagePath == null && !hasPhonePhoto,
              onTap: () => Navigator.pop(context, _removeProfilePhotoValue),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePhotoOptionData {
  const _ProfilePhotoOptionData({required this.label, required this.imagePath});

  final String label;
  final String imagePath;
}

class _PhonePhotoOption extends StatelessWidget {
  const _PhonePhotoOption({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SheetOption(
      selected: selected,
      onTap: onTap,
      icon: Icons.photo_library_outlined,
      label: 'Choose from Phone',
    );
  }
}

class _ProfilePhotoOption extends StatelessWidget {
  const _ProfilePhotoOption({
    required this.label,
    required this.imagePath,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String imagePath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SheetOption(
      selected: selected,
      onTap: onTap,
      leading: ClipOval(
        child: Image.asset(imagePath, width: 38, height: 38, fit: BoxFit.cover),
      ),
      label: label,
      height: 64,
    );
  }
}

class _RemovePhotoOption extends StatelessWidget {
  const _RemovePhotoOption({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SheetOption(
      selected: selected,
      onTap: onTap,
      icon: Icons.person_outline_rounded,
      label: 'Use Default User Icon',
    );
  }
}

class _GradePickerSheet extends StatelessWidget {
  const _GradePickerSheet({required this.selectedGrade});

  final String selectedGrade;

  @override
  Widget build(BuildContext context) {
    const grades = ['Grade 10', 'Grade 11', 'Grade 12'];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF090D19),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.blue.withValues(alpha: .34)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(
              icon: Icons.school_outlined,
              title: 'Choose Grade Level',
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
            for (final grade in grades) ...[
              _SheetOption(
                selected: grade == selectedGrade,
                onTap: () => Navigator.pop(context, grade),
                icon: grade == selectedGrade
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                label: grade,
              ),
              if (grade != grades.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.icon,
    required this.title,
    required this.onClose,
  });

  final IconData icon;
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8BA0FF), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(
            Icons.close_rounded,
            color: Color(0xFF96A0CF),
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.selected,
    required this.onTap,
    required this.label,
    this.icon,
    this.leading,
    this.height = 54,
  });

  final bool selected;
  final VoidCallback onTap;
  final String label;
  final IconData? icon;
  final Widget? leading;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.blue.withValues(alpha: .22)
                : const Color(0xFF11172E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.blue
                  : Colors.white.withValues(alpha: .06),
            ),
          ),
          child: Row(
            children: [
              leading ??
                  Icon(
                    icon,
                    color: selected ? AppColors.blue : const Color(0xFF8BA0FF),
                    size: 20,
                  ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFDDE4FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? AppColors.blue : const Color(0xFF96A0CF),
                size: 20,
              ),
            ],
          ),
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
