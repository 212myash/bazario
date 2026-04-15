import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'john@example.com');
  final _passwordController = TextEditingController(text: 'Password@123');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.isLoggedIn) {
        context.go('/home');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Bazario',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sign in to continue shopping.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  AppTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                  ),
                  const SizedBox(height: 12),
                  if (authState.errorMessage != null)
                    Text(
                      authState.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Login',
                    isLoading: authState.isLoading,
                    onPressed: () {
                      ref
                          .read(authProvider.notifier)
                          .login(
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                          );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('Create an account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
