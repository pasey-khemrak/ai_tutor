import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../app/tutor_shell.dart';
import 'forgot_password_screen.dart';
import 'rean_logo_mark.dart';
import 'setup_flow_screen.dart';

class AuthFormScreen extends StatefulWidget {
  const AuthFormScreen({super.key, this.initialIsSignUp = true});

  final bool initialIsSignUp;

  @override
  State<AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends State<AuthFormScreen> {
  static const _savedEmail = 'meanseav672@gmail.com';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _isSignUp;
  bool _showSavedEmail = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
    _emailController.addListener(_updateSavedEmailSuggestion);
  }

  void _updateSavedEmailSuggestion() {
    final text = _emailController.text.trim();
    final shouldShow =
        text.isNotEmpty &&
        text != _savedEmail &&
        _savedEmail.startsWith(text.toLowerCase());
    if (shouldShow != _showSavedEmail) {
      setState(() => _showSavedEmail = shouldShow);
    }
  }

  void _useSavedEmail() {
    _emailController.value = const TextEditingValue(
      text: _savedEmail,
      selection: TextSelection.collapsed(offset: _savedEmail.length),
    );
    setState(() => _showSavedEmail = false);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final nextScreen = _isSignUp ? const SetupFlowScreen() : const TutorShell();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => nextScreen));
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ForgotPasswordScreen(),
      ),
    );
  }

  void _showGoogleConfigMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Google Sign-In is ready for configuration.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            colors: [
              Color(0xFF080D19),
              Color(0xFF09101E),
              Color(0xFF10112A),
              Color(0xFF171342),
            ],
            stops: [0, .46, .74, 1],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const _AuthGlow(),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.sizeOf(context).height -
                        MediaQuery.paddingOf(context).vertical -
                        54,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        const ReanLogoMark(size: 110),
                        const SizedBox(height: 14),
                        _AuthTitle(isSignUp: _isSignUp),
                        const SizedBox(height: 44),
                        _AuthTabs(
                          isSignUp: _isSignUp,
                          onChanged: (value) =>
                              setState(() => _isSignUp = value),
                        ),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _isSignUp
                              ? _SignUpFields(
                                  key: const ValueKey('signup'),
                                  nameController: _nameController,
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  showSavedEmail: _showSavedEmail,
                                  savedEmail: _savedEmail,
                                  onUseSavedEmail: _useSavedEmail,
                                )
                              : _SignInFields(
                                  key: const ValueKey('signin'),
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  showSavedEmail: _showSavedEmail,
                                  savedEmail: _savedEmail,
                                  onUseSavedEmail: _useSavedEmail,
                                  onForgotPassword: _openForgotPassword,
                                ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _isSignUp ? 'Create Account' : 'Sign In',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const _DividerLabel(),
                        const SizedBox(height: 16),
                        _GoogleButton(onPressed: _showGoogleConfigMessage),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthTitle extends StatelessWidget {
  const _AuthTitle({required this.isSignUp});

  final bool isSignUp;

  @override
  Widget build(BuildContext context) {
    if (!isSignUp) {
      return const Column(
        children: [
          Text(
            'Welcome Back!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 29,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Sign in to continue your learning journey',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8390BF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return const Column(
      children: [
        ReanBrandName(prefix: 'Join '),
        SizedBox(height: 12),
        Text(
          'Create your free account and start learning',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF8390BF),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({required this.isSignUp, required this.onChanged});

  final bool isSignUp;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 210,
        height: 45,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .72),
          border: Border.all(color: const Color(0xFF6975AC)),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            _AuthTabButton(
              label: 'Sign In',
              selected: !isSignUp,
              onTap: () => onChanged(false),
            ),
            _AuthTabButton(
              label: 'Sign Up',
              selected: isSignUp,
              onTap: () => onChanged(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  const _AuthTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: selected ? 1 : .82),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _SignUpFields extends StatelessWidget {
  const _SignUpFields({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.showSavedEmail,
    required this.savedEmail,
    required this.onUseSavedEmail,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool showSavedEmail;
  final String savedEmail;
  final VoidCallback onUseSavedEmail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AuthField(
          label: 'Full Name',
          hint: 'Khemarak Pasey',
          icon: Icons.person_rounded,
          controller: nameController,
          validator: _validateName,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: 9),
        _AuthField(
          label: 'Email Address',
          hint: 'Pasey@example.com',
          icon: Icons.mail_rounded,
          controller: emailController,
          validator: _validateEmail,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        if (showSavedEmail) ...[
          const SizedBox(height: 8),
          _SavedEmailSuggestion(email: savedEmail, onTap: onUseSavedEmail),
        ],
        SizedBox(height: 9),
        _AuthField(
          label: 'Password',
          hint: '........................',
          icon: Icons.key_rounded,
          obscure: true,
          controller: passwordController,
          validator: _validatePassword,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }
}

class _SignInFields extends StatelessWidget {
  const _SignInFields({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.showSavedEmail,
    required this.savedEmail,
    required this.onUseSavedEmail,
    required this.onForgotPassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool showSavedEmail;
  final String savedEmail;
  final VoidCallback onUseSavedEmail;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      children: [
        _AuthField(
          label: 'Email Address',
          hint: 'Pasey@example.com',
          icon: Icons.mail_rounded,
          controller: emailController,
          validator: _validateEmail,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        if (showSavedEmail) ...[
          const SizedBox(height: 8),
          _SavedEmailSuggestion(email: savedEmail, onTap: onUseSavedEmail),
        ],
        const SizedBox(height: 9),
        _AuthField(
          label: 'Password',
          hint: '........................',
          icon: Icons.key_rounded,
          obscure: true,
          controller: passwordController,
          validator: _validatePassword,
          textInputAction: TextInputAction.done,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onForgotPassword,
            child: const SizedBox(
              key: Key('forgot-password-link'),
              width: 160,
              height: 42,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Forgot Password ?',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFADB8E7),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: .58),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFFB9C5F9), size: 18),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 52,
            ),
            suffixIcon: obscure
                ? const Icon(
                    Icons.visibility_rounded,
                    color: Color(0xFF9EAAE8),
                    size: 18,
                  )
                : null,
            filled: true,
            fillColor: Colors.black.withValues(alpha: .78),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
            constraints: const BoxConstraints(minHeight: 52),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: Color(0xFF7781B5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: AppColors.blue, width: 1.4),
            ),
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}

class _SavedEmailSuggestion extends StatelessWidget {
  const _SavedEmailSuggestion({required this.email, required this.onTap});

  final String email;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF11172E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.blue.withValues(alpha: .38)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_circle_outlined,
                color: Color(0xFF8BA0FF),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFDDE4FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Use',
                style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 12,
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

String? _validateName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter your full name.';
  }
  return null;
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return 'Please enter your email.';
  }
  if (!email.contains('@') || !email.contains('.')) {
    return 'Please enter a valid email address.';
  }
  return null;
}

String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your password.';
  }
  if (value.length < 6) {
    return 'Password must be at least 6 characters.';
  }
  return null;
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFF566084))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: TextStyle(
              color: Color(0xFF7F8AB7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: const Color(0xFF566084))),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(52, 52),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const CircleBorder(),
        ),
        child: Image.asset(
          'assets/images/ai_tutor_google.png',
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _AuthGlow extends StatelessWidget {
  const _AuthGlow();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 96, sigmaY: 96),
          child: Align(
            alignment: const Alignment(.3, -1.1),
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blue.withValues(alpha: .2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
