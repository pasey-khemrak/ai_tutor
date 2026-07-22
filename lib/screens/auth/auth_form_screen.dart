import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
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
  late bool _isSignUp;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
  }

  void _openSetupFlow() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SetupFlowScreen()),
    );
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ForgotPasswordScreen(),
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
                        onChanged: (value) => setState(() => _isSignUp = value),
                      ),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _isSignUp
                            ? _SignUpFields(key: const ValueKey('signup'))
                            : _SignInFields(
                                key: const ValueKey('signin'),
                                onForgotPassword: _openForgotPassword,
                              ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _openSetupFlow,
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
                      const _GoogleButton(),
                    ],
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

    return Column(
      children: [
        const ReanBrandName(prefix: 'Join '),
        const SizedBox(height: 12),
        const Text(
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
  const _SignUpFields({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _AuthField(
          label: 'Full Name',
          hint: 'Khemarak Pasey',
          icon: Icons.person_rounded,
        ),
        SizedBox(height: 9),
        _AuthField(
          label: 'Email Address',
          hint: 'Pasey@example.com',
          icon: Icons.mail_rounded,
        ),
        SizedBox(height: 9),
        _AuthField(
          label: 'Password',
          hint: '........................',
          icon: Icons.key_rounded,
          obscure: true,
        ),
      ],
    );
  }
}

class _SignInFields extends StatelessWidget {
  const _SignInFields({super.key, required this.onForgotPassword});

  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      children: [
        const _AuthField(
          label: 'Email Address',
          hint: 'Pasey@example.com',
          icon: Icons.mail_rounded,
        ),
        const SizedBox(height: 9),
        const _AuthField(
          label: 'Password',
          hint: '........................',
          icon: Icons.key_rounded,
          obscure: true,
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
    this.obscure = false,
  });

  final String label;
  final String hint;
  final IconData icon;
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
        SizedBox(
          height: 45,
          child: TextField(
            obscureText: obscure,
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
              suffixIcon: obscure
                  ? const Icon(
                      Icons.visibility_rounded,
                      color: Color(0xFF9EAAE8),
                      size: 18,
                    )
                  : null,
              filled: true,
              fillColor: Colors.black.withValues(alpha: .78),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: Color(0xFF7781B5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: const BorderSide(color: AppColors.blue, width: 1.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
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
  const _GoogleButton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {},
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
