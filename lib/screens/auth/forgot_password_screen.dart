import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_service.dart';
import '../../core/auth/auth_validators.dart';
import '../../core/routing/app_routes.dart';
import 'rean_logo_mark.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _backToSignIn() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.signIn);
  }

  Future<void> _sendResetLink() async {
    if (_isSent || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSent = true;
      _errorMessage = null;
    });

    try {
      await appAuthService.sendPasswordResetEmail(_emailController.text.trim());
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reset link sent. Please check your email.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.blue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        _backToSignIn();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSent = false;
          _errorMessage = 'Could not send reset link. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return _SetupBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        constraints.maxHeight -
                        MediaQuery.paddingOf(context).vertical,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 42, 28, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ReanLogoMark(size: 112),
                        const SizedBox(height: 16),
                        const Text(
                          'Forgot Password?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No worries! Enter your email and we will\nsend you a link to reset your password.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF8793C3),
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Form(
                          key: _formKey,
                          child: _EmailField(controller: _emailController),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.peach,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        _PrimaryButton(
                          label: _isSent
                              ? 'Reset Link Sent'
                              : 'Send Reset Link',
                          onPressed: _sendResetLink,
                        ),
                        const SizedBox(height: 30),
                        const _DividerLabel(),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _backToSignIn,
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                color: Color(0xFF8793C3),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              children: [
                                TextSpan(text: 'Remember your password? '),
                                TextSpan(
                                  text: 'Sign In',
                                  style: TextStyle(color: AppColors.blue),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 170),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Address',
          style: TextStyle(
            color: Color(0xFFADB8E7),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 45,
          child: TextFormField(
            key: const Key('forgot-email-field'),
            controller: controller,
            validator: AuthValidators.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Pasey@example.com',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: .58),
                fontWeight: FontWeight.w700,
              ),
              prefixIcon: const Icon(
                Icons.mail_rounded,
                color: Color(0xFFB9C5F9),
                size: 18,
              ),
              filled: true,
              fillColor: Colors.black.withValues(alpha: .78),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF7781B5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
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
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFF566084), height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'or',
            style: TextStyle(
              color: Color(0xFF7F8AB7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFF566084), height: 1)),
      ],
    );
  }
}

class _SetupBackground extends StatelessWidget {
  const _SetupBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppColors.backgroundDecoration,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 96, sigmaY: 96),
                child: Align(
                  alignment: const Alignment(.2, -1.05),
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
          ),
          child,
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
