import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive_text.dart';
import '../providers/profile_provider.dart';

class ShippingAddressScreen extends ConsumerStatefulWidget {
  const ShippingAddressScreen({super.key});

  @override
  ConsumerState<ShippingAddressScreen> createState() =>
      _ShippingAddressScreenState();
}

class _ShippingAddressScreenState extends ConsumerState<ShippingAddressScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _labelController;
  late final TextEditingController _countryController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _postcodeController;
  bool _isDefault = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _labelController = TextEditingController();
    _countryController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _postcodeController = TextEditingController();
    Future.microtask(() => ref.read(profileProvider.notifier).fetchProfile());
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _labelController.dispose();
    _countryController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    final state = ref.read(profileProvider);
    final user = state.user;
    final address = user?.addresses.isNotEmpty == true
        ? user!.addresses.first
        : null;

    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final label = _labelController.text.trim();
    final street = _addressController.text.trim();
    final city = _cityController.text.trim();
    final stateName = _stateController.text.trim();
    final postalCode = _postcodeController.text.trim();
    final country = _countryController.text.trim();

    if (fullName.isEmpty ||
        phone.isEmpty ||
        street.isEmpty ||
        city.isEmpty ||
        stateName.isEmpty ||
        postalCode.isEmpty ||
        country.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required address fields'),
        ),
      );
      return;
    }

    final payload = {
      'fullName': fullName,
      'phone': phone,
      'street': street,
      'city': city,
      'state': stateName,
      'postalCode': postalCode,
      'country': country,
      if (label.isNotEmpty) 'label': label,
      'isDefault': _isDefault,
    };

    if (address == null) {
      await ref.read(profileProvider.notifier).addAddress(payload);
    } else {
      await ref
          .read(profileProvider.notifier)
          .updateAddress(address.id, payload);
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Address updated')));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final user = state.user;
    final address = user?.addresses.isNotEmpty == true
        ? user!.addresses.first
        : null;

    if (!_initialized) {
      _fullNameController.text = address?.fullName.isNotEmpty == true
          ? address!.fullName
          : (user?.name ?? '');
      _phoneController.text = address?.phone.isNotEmpty == true
          ? address!.phone
          : (user?.phone ?? '');
      _labelController.text = address?.label ?? '';
      _countryController.text = address?.country.isNotEmpty == true
          ? address!.country
          : 'India';
      _addressController.text =
          address?.street ?? 'Magadi Main Rd, next to Prasanna Theatre, C';
      _cityController.text = address?.city ?? 'Bengaluru';
      _stateController.text = address?.state ?? 'Karnataka';
      _postcodeController.text = address?.postalCode.isNotEmpty == true
          ? address!.postalCode
          : '560023';
      _isDefault = address?.isDefault ?? false;
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            Text(
              'Shipping Address',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
                color: const Color(0xFF1D1F24),
              ),
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Full Name'),
            const SizedBox(height: 6),
            _AddressField(controller: _fullNameController),
            const SizedBox(height: 10),
            const _FieldLabel('Phone Number'),
            const SizedBox(height: 6),
            _AddressField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            const _FieldLabel('Address Label (optional)'),
            const SizedBox(height: 6),
            _AddressField(
              controller: _labelController,
              hintText: 'Home, Office',
            ),
            const SizedBox(height: 10),
            const _FieldLabel('Country'),
            const SizedBox(height: 6),
            _AddressField(controller: _countryController, suffixArrow: true),
            const SizedBox(height: 10),
            const _FieldLabel('Street Address'),
            const SizedBox(height: 6),
            _AddressField(controller: _addressController),
            const SizedBox(height: 10),
            const _FieldLabel('Town / City'),
            const SizedBox(height: 6),
            _AddressField(controller: _cityController),
            const SizedBox(height: 10),
            const _FieldLabel('State'),
            const SizedBox(height: 6),
            _AddressField(controller: _stateController),
            const SizedBox(height: 10),
            const _FieldLabel('Postcode'),
            const SizedBox(height: 6),
            _AddressField(controller: _postcodeController),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              value: _isDefault,
              onChanged: state.isSaving
                  ? null
                  : (value) => setState(() => _isDefault = value),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Set as default address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2127),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: state.isSaving ? null : _saveAddress,
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
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
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
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: adaptiveFontSize(context, base: 16, min: 13, max: 19),
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1F2127),
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    this.suffixArrow = false,
    this.hintText,
    this.keyboardType,
  });

  final TextEditingController controller;
  final bool suffixArrow;
  final String? hintText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: adaptiveFontSize(context, base: 16)),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFE1E5F1),
        contentPadding: EdgeInsets.symmetric(
          horizontal: adaptiveFontSize(context, base: 12, min: 10, max: 16),
          vertical: adaptiveFontSize(context, base: 11, min: 9, max: 14),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixArrow
            ? const Icon(Icons.arrow_forward_rounded, color: Color(0xFFCBD0DD))
            : null,
      ),
    );
  }
}
