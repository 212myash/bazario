import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileProvider.notifier).fetchProfile());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final user = state.user;
    final primaryAddress = user?.addresses.isNotEmpty == true
        ? user!.addresses.first
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
            const SizedBox(height: 20),
            const _SectionLabel(title: 'Personal'),
            const SizedBox(height: 10),
            _SettingsTile(
              label: 'Profile',
              onTap: () => context.push('/profile/edit'),
            ),
            _SettingsTile(
              label: 'Shipping Address',
              onTap: () => context.push('/profile/shipping-address'),
            ),
            const _SettingsTile(label: 'Payment methods'),
            const SizedBox(height: 20),
            const _SectionLabel(title: 'Shop'),
            const SizedBox(height: 10),
            _SettingsTile(
              label: 'Country',
              trailingText: primaryAddress?.country ?? 'Vietnam',
            ),
            const _SettingsTile(label: 'Currency', trailingText: '\$ USD'),
            const _SettingsTile(label: 'Sizes', trailingText: 'UK'),
            const _SettingsTile(label: 'Terms and Conditions'),
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Color(0xFFD92D20)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF23262F),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.label, this.trailingText, this.onTap});

  final String label;
  final String? trailingText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE7E7EC))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2127),
                ),
              ),
            ),
            if (trailingText != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  trailingText!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF30323A),
                  ),
                ),
              ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: Color(0xFF1F2127),
            ),
          ],
        ),
      ),
    );
  }
}
