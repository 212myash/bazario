import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive_text.dart';
import '../providers/profile_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController(text: '************');
    Future.microtask(() => ref.read(profileProvider.notifier).fetchProfile());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final user = state.user;

    if (!_initialized && user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      color: const Color(0xFF1D1F24),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your Profile',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF23262F),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 108,
                        width: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFDCE2EE),
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const ColoredBox(
                                color: Color(0xFFE7EBF6),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 52,
                                  color: Color(0xFF5E6A80),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        right: -4,
                        top: -2,
                        child: Material(
                          color: const Color(0xFF0B4DFF),
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () {},
                            customBorder: const CircleBorder(),
                            child: const SizedBox(
                              height: 32,
                              width: 32,
                              child: Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _InputBox(controller: _nameController),
                  const SizedBox(height: 12),
                  _InputBox(controller: _emailController, readOnly: true),
                  const SizedBox(height: 12),
                  _InputBox(controller: _passwordController, readOnly: true),
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Color(0xFFD92D20)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: state.isSaving
                      ? null
                      : () async {
                          await ref
                              .read(profileProvider.notifier)
                              .updateProfile(name: _nameController.text.trim());
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile updated')),
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0B4DFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: state.isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({required this.controller, this.readOnly = false});

  final TextEditingController controller;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: TextStyle(
        fontSize: adaptiveFontSize(context, base: 18, min: 14, max: 22),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFE1E5F1),
        contentPadding: EdgeInsets.symmetric(
          horizontal: adaptiveFontSize(context, base: 16, min: 12, max: 20),
          vertical: adaptiveFontSize(context, base: 12, min: 9, max: 15),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
