import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/brand_colors.dart';
import '../../../../shared/widgets/brand_logo.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Row(
          children: [
            BrandLogo(width: 98, showWordmark: false),
            SizedBox(width: 10),
            Text('Profile'),
          ],
        ),
      ),
      body: user == null && state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.transparent,
                              child: Icon(
                                Icons.person_rounded,
                                color: BrandColors.logoNavy,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? '-',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    user?.email ?? '-',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _ProfileActionTile(
                          icon: Icons.edit_outlined,
                          title: 'Edit Profile',
                          subtitle: user?.phone?.isEmpty ?? true
                              ? 'Add your phone number'
                              : user?.phone ?? '',
                          onTap: () => _showEditProfileDialog(context, user),
                        ),
                        _ProfileActionTile(
                          icon: Icons.receipt_long_outlined,
                          title: 'My Orders',
                          subtitle: 'Track all your placed orders',
                          onTap: () => context.push('/orders'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Addresses',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.tonalIcon(
                      onPressed: () => _showAddressDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...?user?.addresses.map(
                  (address) => Card(
                    child: ListTile(
                      title: Text(address.fullName),
                      subtitle: Text(
                        '${address.shortAddress}\n${address.phone}',
                      ),
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          IconButton(
                            onPressed: () => _showAddressDialog(
                              context,
                              addressId: address.id,
                              existing: address,
                            ),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () => ref
                                .read(profileProvider.notifier)
                                .deleteAddress(address.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                  child: const Text('Logout'),
                ),
              ],
            ),
    );
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    dynamic user,
  ) async {
    final nameController = TextEditingController(text: user?.name ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(hintText: 'Phone'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(profileProvider.notifier)
                    .updateProfile(
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddressDialog(
    BuildContext context, {
    String? addressId,
    dynamic existing,
  }) async {
    final fullNameController = TextEditingController(
      text: existing?.fullName ?? '',
    );
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final streetController = TextEditingController(
      text: existing?.street ?? '',
    );
    final cityController = TextEditingController(text: existing?.city ?? '');
    final stateController = TextEditingController(text: existing?.state ?? '');
    final postalController = TextEditingController(
      text: existing?.postalCode ?? '',
    );
    final countryController = TextEditingController(
      text: existing?.country ?? 'India',
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(addressId == null ? 'Add Address' : 'Edit Address'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(hintText: 'Full name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(hintText: 'Phone'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: streetController,
                  decoration: const InputDecoration(hintText: 'Street'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(hintText: 'City'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: stateController,
                  decoration: const InputDecoration(hintText: 'State'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: postalController,
                  decoration: const InputDecoration(hintText: 'Postal code'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: countryController,
                  decoration: const InputDecoration(hintText: 'Country'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final payload = {
                  'fullName': fullNameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'street': streetController.text.trim(),
                  'city': cityController.text.trim(),
                  'state': stateController.text.trim(),
                  'postalCode': postalController.text.trim(),
                  'country': countryController.text.trim(),
                };

                if (addressId == null) {
                  await ref.read(profileProvider.notifier).addAddress(payload);
                } else {
                  await ref
                      .read(profileProvider.notifier)
                      .updateAddress(addressId, payload);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.onSecondaryContainer),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
