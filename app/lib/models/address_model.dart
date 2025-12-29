
class Address {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String province;
  final String district;
  final String ward;
  final String streetAddress;
  final bool isDefault;

  Address({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.province,
    required this.district,
    required this.ward,
    required this.streetAddress,
    this.isDefault = false,
  });

  String get fullAddress => '$streetAddress, $ward, $district, $province';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phone': phone,
      'province': province,
      'district': district,
      'ward': ward,
      'streetAddress': streetAddress,
      'isDefault': isDefault,
    };
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      province: map['province'] ?? '',
      district: map['district'] ?? '',
      ward: map['ward'] ?? '',
      streetAddress: map['streetAddress'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }
}
