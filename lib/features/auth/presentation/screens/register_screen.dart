import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController(text: 'John User');
  final _emailController = TextEditingController(text: 'john@example.com');
  final _passwordController = TextEditingController(text: 'Password@123');

  @override
  void dispose() {
    _nameController.dispose();
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
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  AppTextField(
                    controller: _nameController,
                    hintText: 'Full Name',
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Register',
                    isLoading: authState.isLoading,
                    onPressed: () {
                      ref
                          .read(authProvider.notifier)
                          .register(
                            name: _nameController.text.trim(),
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                          );
                    },
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
