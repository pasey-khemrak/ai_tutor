import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_service.dart';
import '../../core/auth/auth_validators.dart';
import '../../core/routing/app_routes.dart';
import 'rean_logo_mark.dart';

class AuthFormScreen extends StatefulWidget {
  const AuthFormScreen({super.key, this.initialIsSignUp = true});

  final bool initialIsSignUp;

  @override
  State<AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends State<AuthFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _isSignUp;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate() || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await appAuthService.registerWithEmail(
          name: _nameController.text,
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await appAuthService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (!mounted) {
        return;
      }
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _openForgotPassword() {
    Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
  }

  String _friendlyError(Object error) {
    if (error is AuthException) {
      return error.message;
    }
    final message = error.toString();
    if (message.contains('user-not-found') ||
        message.contains('wrong-password')) {
      return 'Email or password is incorrect.';
    }
    if (message.contains('email-already-in-use')) {
      return 'This email is already registered.';
    }
    return 'Authentication failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: AppColors.backgroundDecoration,
        child: SafeArea(
          child: Stack(
            children: [
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
                      Form(
                        key: _formKey,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _isSignUp
                              ? _SignUpFields(
                                  key: const ValueKey('signup'),
                                  nameController: _nameController,
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                )
                              : _SignInFields(
                                  key: const ValueKey('signin'),
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  onForgotPassword: _openForgotPassword,
                                ),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
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
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _isSubmitting
                                ? 'Please wait...'
                                : _isSignUp
                                ? 'Create Account'
                                : 'Sign In',
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
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AuthField(
          key: const Key('auth-name-field'),
          label: 'Full Name',
          hint: 'Khemarak Pasey',
          icon: Icons.person_rounded,
          controller: nameController,
          textInputAction: TextInputAction.next,
          validator: AuthValidators.name,
        ),
        const SizedBox(height: 9),
        _AuthField(
          key: const Key('auth-email-field'),
          label: 'Email Address',
          hint: 'Pasey@example.com',
          icon: Icons.mail_rounded,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: AuthValidators.email,
        ),
        const SizedBox(height: 9),
        _AuthField(
          key: const Key('auth-password-field'),
          label: 'Password',
          hint: '........................',
          icon: Icons.key_rounded,
          controller: passwordController,
          obscure: true,
          textInputAction: TextInputAction.done,
          validator: AuthValidators.password,
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
    required this.onForgotPassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      children: [
        _AuthField(
          key: const Key('auth-email-field'),
          label: 'Email Address',
          hint: 'Pasey@example.com',
          icon: Icons.mail_rounded,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: AuthValidators.email,
        ),
        const SizedBox(height: 9),
        _AuthField(
          key: const Key('auth-password-field'),
          label: 'Password',
          hint: '........................',
          icon: Icons.key_rounded,
          controller: passwordController,
          obscure: true,
          textInputAction: TextInputAction.done,
          validator: AuthValidators.password,
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
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
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
        SizedBox(
          height: 45,
          child: TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autovalidateMode: AutovalidateMode.onUserInteraction,
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
