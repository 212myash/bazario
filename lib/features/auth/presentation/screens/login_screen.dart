import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/responsive_text.dart';
import '../providers/auth_provider.dart';

enum _LoginStep { email, password, recoveryMethod, otp, newPassword }

enum _RecoveryMethod { sms, email }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _repeatPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();
  _LoginStep _step = _LoginStep.email;
  _RecoveryMethod _recoveryMethod = _RecoveryMethod.sms;
  bool _isSubmitting = false;
  String _displayName = 'Romina';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _repeatPasswordController.dispose();
    _passwordFocusNode.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  String _deriveDisplayName(String email) {
    final localPart = email.trim().split('@').first;
    if (localPart.isEmpty) {
      return 'Romina';
    }
    return localPart
        .replaceAll(RegExp(r'[_\.-]+'), ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  }

  Future<void> _goToPasswordStep() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Email is required', isError: true);
      return;
    }
    if (!_isValidEmail(email)) {
      _showMessage('Enter a valid email address', isError: true);
      return;
    }

    setState(() {
      _displayName = _deriveDisplayName(email);
      _step = _LoginStep.password;
    });

    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (mounted) {
      FocusScope.of(context).requestFocus(_passwordFocusNode);
    }
  }

  Future<void> _submitLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Email and password are required', isError: true);
      return;
    }

    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await ref
        .read(authProvider.notifier)
        .login(email: email, password: password);
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);

    if (!success) {
      _showMessage(
        ref.read(authProvider).errorMessage ?? 'Login failed',
        isError: true,
      );
      return;
    }

    final isAdmin =
        (ref.read(authProvider).user?.role.toLowerCase() ?? '') == 'admin';
    context.go(isAdmin ? '/admin' : '/home');
  }

  void _openRecovery() {
    setState(() => _step = _LoginStep.recoveryMethod);
  }

  Future<void> _sendRecoveryCode() async {
    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) {
      return;
    }
    setState(() {
      _isSubmitting = false;
      _otpController.clear();
      _step = _LoginStep.otp;
    });
    _showMessage('Code sent successfully');
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (mounted) {
      FocusScope.of(context).requestFocus(_otpFocusNode);
    }
  }

  Future<void> _submitOtp() async {
    if (_otpController.text.trim().length < 4) {
      _showMessage('Enter the 4-digit code', isError: true);
      return;
    }

    setState(() => _step = _LoginStep.newPassword);
  }

  Future<void> _saveNewPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final repeatPassword = _repeatPasswordController.text.trim();

    if (newPassword.length < 6) {
      _showMessage('Password must be at least 6 characters', isError: true);
      return;
    }
    if (newPassword != repeatPassword) {
      _showMessage('Passwords do not match', isError: true);
      return;
    }

    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);

    _showMessage('Password updated successfully');
    setState(() {
      _step = _LoginStep.email;
      _passwordController.clear();
      _otpController.clear();
      _newPasswordController.clear();
      _repeatPasswordController.clear();
    });
  }

  void _cancel() {
    if (_step == _LoginStep.email) {
      context.go('/onboarding');
      return;
    }

    setState(() {
      _step = _LoginStep.email;
      _passwordController.clear();
      _otpController.clear();
      _newPasswordController.clear();
      _repeatPasswordController.clear();
    });
  }

  void _goBackToPassword() {
    setState(() => _step = _LoginStep.password);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _AuthBackdrop()),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _buildStep(context, theme, authState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    ThemeData theme,
    AuthState authState,
  ) {
    switch (_step) {
      case _LoginStep.email:
        return _LoginEmailStep(
          key: const ValueKey('email'),
          controller: _emailController,
          isSubmitting: _isSubmitting || authState.isLoading,
          onNext: _goToPasswordStep,
          onCancel: _cancel,
        );
      case _LoginStep.password:
        return _LoginPasswordStep(
          key: const ValueKey('password'),
          displayName: _displayName,
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          isSubmitting: _isSubmitting || authState.isLoading,
          onLogin: _submitLogin,
          onForgotPassword: _openRecovery,
          onNotYou: _cancel,
          onFieldChanged: () => setState(() {}),
        );
      case _LoginStep.recoveryMethod:
        return _RecoveryMethodStep(
          key: const ValueKey('recovery'),
          selectedMethod: _recoveryMethod,
          isSubmitting: _isSubmitting,
          onSelected: (method) => setState(() => _recoveryMethod = method),
          onNext: _sendRecoveryCode,
          onCancel: _goBackToPassword,
        );
      case _LoginStep.otp:
        return _OtpStep(
          key: const ValueKey('otp'),
          controller: _otpController,
          focusNode: _otpFocusNode,
          isSubmitting: _isSubmitting,
          maskedTarget: _recoveryMethod == _RecoveryMethod.sms
              ? '+98*******00'
              : _emailController.text.trim().isEmpty
              ? 'romina@example.com'
              : _emailController.text.trim(),
          onSendAgain: _sendRecoveryCode,
          onCancel: _goBackToPassword,
          onChanged: (value) {
            setState(() {});
            if (value.trim().length >= 4) {
              _submitOtp();
            }
          },
        );
      case _LoginStep.newPassword:
        return _NewPasswordStep(
          key: const ValueKey('newPassword'),
          newPasswordController: _newPasswordController,
          repeatPasswordController: _repeatPasswordController,
          isSubmitting: _isSubmitting,
          onSave: _saveNewPassword,
          onCancel: _goBackToPassword,
          onChanged: () => setState(() {}),
        );
    }
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: -120,
          top: -120,
          child: Container(
            height: 380,
            width: 380,
            decoration: const BoxDecoration(
              color: Color(0xFF0B4DFF),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: -110,
          top: -20,
          child: Container(
            height: 440,
            width: 280,
            decoration: const BoxDecoration(
              color: Color(0xFFDCE8FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(220),
                topRight: Radius.circular(220),
                bottomLeft: Radius.circular(220),
                bottomRight: Radius.circular(220),
              ),
            ),
          ),
        ),
        Positioned(
          right: -80,
          top: 120,
          child: Container(
            height: 190,
            width: 130,
            decoration: const BoxDecoration(
              color: Color(0xFF0B4DFF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(140),
                topRight: Radius.circular(120),
                bottomLeft: Radius.circular(80),
                bottomRight: Radius.circular(60),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginEmailStep extends StatelessWidget {
  const _LoginEmailStep({
    super.key,
    required this.controller,
    required this.isSubmitting,
    required this.onNext,
    required this.onCancel,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final Future<void> Function() onNext;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      child: Column(
        children: [
          const Spacer(flex: 3),
          Text(
            'Login',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF171717),
              letterSpacing: -1.2,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Good to see you back! \u2665',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 21,
              color: const Color(0xFF4B4B4B),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 28),
          _RoundedField(
            controller: controller,
            hintText: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isSubmitting ? null : onNext,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(78),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                backgroundColor: const Color(0xFF0B4DFF),
                foregroundColor: Colors.white,
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Next'),
            ),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: onCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 20, color: Color(0xFF3D3D3D)),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _LoginPasswordStep extends StatelessWidget {
  const _LoginPasswordStep({
    super.key,
    required this.displayName,
    required this.controller,
    required this.focusNode,
    required this.isSubmitting,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onNotYou,
    required this.onFieldChanged,
  });

  final String displayName;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSubmitting;
  final Future<void> Function() onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onNotYou;
  final VoidCallback onFieldChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(focusNode),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
        child: Column(
          children: [
            const Spacer(flex: 2),
            const _AvatarBadge(),
            const SizedBox(height: 26),
            Text(
              'Hello, $displayName!!',
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F1F1F),
                letterSpacing: -1,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Type your password',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF1D1D1D),
              ),
            ),
            const SizedBox(height: 28),
            _RoundedField(
              controller: controller,
              hintText: 'Password',
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: onForgotPassword,
                child: const Text(
                  'Forgot your password?',
                  style: TextStyle(
                    fontSize: 19,
                    color: Color(0xFF565656),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onLogin,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(78),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  backgroundColor: const Color(0xFF0B4DFF),
                  foregroundColor: Colors.white,
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                child: Text(
                  isSubmitting ? 'Please wait while logging in' : 'Login',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: onNotYou,
              child: const Text(
                'Not you?',
                style: TextStyle(fontSize: 18, color: Color(0xFF4E4E4E)),
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _RecoveryMethodStep extends StatelessWidget {
  const _RecoveryMethodStep({
    super.key,
    required this.selectedMethod,
    required this.isSubmitting,
    required this.onSelected,
    required this.onNext,
    required this.onCancel,
  });

  final _RecoveryMethod selectedMethod;
  final bool isSubmitting;
  final ValueChanged<_RecoveryMethod> onSelected;
  final Future<void> Function() onNext;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
      child: Column(
        children: [
          const Spacer(flex: 2),
          const _AvatarBadge(),
          const SizedBox(height: 26),
          Text(
            'Password Recovery',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F1F1F),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'How you would like to restore\nyour password?',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 29,
              fontWeight: FontWeight.w300,
              height: 1.35,
              color: const Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 30),
          _RecoveryChoiceTile(
            label: 'SMS',
            selected: selectedMethod == _RecoveryMethod.sms,
            selectedColor: const Color(0xFFE1E9FF),
            accentColor: const Color(0xFF0B4DFF),
            onTap: () => onSelected(_RecoveryMethod.sms),
          ),
          const SizedBox(height: 12),
          _RecoveryChoiceTile(
            label: 'Email',
            selected: selectedMethod == _RecoveryMethod.email,
            selectedColor: const Color(0xFFFCE5EB),
            accentColor: const Color(0xFFF25D9E),
            onTap: () => onSelected(_RecoveryMethod.email),
          ),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isSubmitting ? null : onNext,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(78),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                backgroundColor: const Color(0xFF0B4DFF),
                foregroundColor: Colors.white,
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Next'),
            ),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: onCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 20, color: Color(0xFF3D3D3D)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isSubmitting,
    required this.maskedTarget,
    required this.onSendAgain,
    required this.onCancel,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSubmitting;
  final String maskedTarget;
  final Future<void> Function() onSendAgain;
  final VoidCallback onCancel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(focusNode),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
        child: Column(
          children: [
            const Spacer(flex: 2),
            const _AvatarBadge(),
            const SizedBox(height: 26),
            Text(
              'Password Recovery',
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F1F1F),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter 4-digits code we sent you\non your phone number',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                height: 1.4,
                color: const Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              maskedTarget,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: const Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 28),
            _PinDotsField(
              controller: controller,
              focusNode: focusNode,
              slotCount: 4,
              activeColor: const Color(0xFF0B4DFF),
              inactiveColor: const Color(0xFFE1E9FF),
              onChanged: onChanged,
            ),
            const Spacer(flex: 4),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSubmitting ? null : onSendAgain,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4B95),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(78),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Send Again'),
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: onCancel,
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 20, color: Color(0xFF3D3D3D)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewPasswordStep extends StatelessWidget {
  const _NewPasswordStep({
    super.key,
    required this.newPasswordController,
    required this.repeatPasswordController,
    required this.isSubmitting,
    required this.onSave,
    required this.onCancel,
    required this.onChanged,
  });

  final TextEditingController newPasswordController;
  final TextEditingController repeatPasswordController;
  final bool isSubmitting;
  final Future<void> Function() onSave;
  final VoidCallback onCancel;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
      child: Column(
        children: [
          const Spacer(flex: 2),
          const _AvatarBadge(),
          const SizedBox(height: 28),
          Text(
            'Setup New Password',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F1F1F),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Please, setup a new password for\nyour account',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              height: 1.4,
              color: const Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 26),
          _RoundedField(
            controller: newPasswordController,
            hintText: 'New Password',
            obscureText: true,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 14),
          _RoundedField(
            controller: repeatPasswordController,
            hintText: 'Repeat Password',
            obscureText: true,
            onChanged: (_) => onChanged(),
          ),
          const Spacer(flex: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isSubmitting ? null : onSave,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(78),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                backgroundColor: const Color(0xFF0B4DFF),
                foregroundColor: Colors.white,
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: onCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 20, color: Color(0xFF3D3D3D)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundedField extends StatelessWidget {
  const _RoundedField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final fieldHeight = adaptiveFontSize(context, base: 56, min: 50, max: 68);
    final textSize = adaptiveFontSize(context, base: 18, min: 14, max: 22);

    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          selectionColor: Color(0xFFDDE8FF),
          selectionHandleColor: Color(0xFF0B4DFF),
        ),
      ),
      child: Container(
        height: fieldHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE8EAF1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          cursorColor: const Color(0xFF0B4DFF),
          onChanged: onChanged,
          style: TextStyle(
            fontSize: textSize,
            color: Color(0xFF1C1C1C),
            fontWeight: FontWeight.w400,
          ),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hintText,
            hintStyle: TextStyle(
              color: Color(0xFFB9BDC7),
              fontSize: textSize,
              fontWeight: FontWeight.w400,
            ),
            border: InputBorder.none,
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.transparent),
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.transparent),
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: adaptiveFontSize(context, base: 20, min: 14, max: 24),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinDotsField extends StatelessWidget {
  const _PinDotsField({
    required this.controller,
    required this.focusNode,
    required this.slotCount,
    required this.activeColor,
    required this.inactiveColor,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int slotCount;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(slotCount, (index) {
              final filled = index < controller.text.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  color: filled ? activeColor : inactiveColor,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
          Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLength: slotCount,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: onChanged,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryChoiceTile extends StatelessWidget {
  const _RecoveryChoiceTile({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: selected ? selectedColor : const Color(0xFFFDF2F5),
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? accentColor : const Color(0xFF1C1C1C),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: selected ? accentColor : const Color(0xFFFFCBDC),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : const Color(0xFFF8E0E8),
                  width: 3,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 20, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      width: 116,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1E000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFF89AD0),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.person_rounded, size: 64, color: Color(0xFF5A3445)),
        ),
      ),
    );
  }
}
