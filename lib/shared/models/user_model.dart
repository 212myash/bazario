class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.addresses = const [],
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final List<AddressModel> addresses;

  UserModel copyWith({
    String? name,
    String? phone,
    List<AddressModel>? addresses,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      phone: phone ?? this.phone,
      addresses: addresses ?? this.addresses,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      phone: json['phone']?.toString(),
      addresses: (json['addresses'] as List<dynamic>? ?? [])
          .map((item) => AddressModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AddressModel {
  AddressModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.label,
    this.isDefault = false,
  });

  final String id;
  final String fullName;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? label;
  final bool isDefault;

  String get shortAddress => '$street, $city';

  Map<String, dynamic> toShippingJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
    };
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['_id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      postalCode: json['postalCode']?.toString() ?? '',
      country: json['country']?.toString() ?? 'India',
      label: json['label']?.toString(),
      isDefault: json['isDefault'] == true,
    );
  }
}
