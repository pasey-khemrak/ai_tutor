import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_service.dart';
import '../../core/routing/app_routes.dart';
import 'rean_logo_mark.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final isAuthenticated = await (widget.authService ?? appAuthService)
        .restoreSession();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(
      isAuthenticated ? AppRoutes.dashboard : AppRoutes.intro,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReanLogoMark(size: 104),
            SizedBox(height: 22),
            SizedBox(
              height: 26,
              width: 26,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.cyan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
