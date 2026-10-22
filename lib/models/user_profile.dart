/// Model data profil pengguna JNOVAMUSIC sesuai desain Figma
class UserProfileModel {
  final String fullName;
  final String username;
  final String email;
  final String phoneNumber;
  final String birthDate;
  final String photoUrl;
  final String tier;
  final int points;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isBiometricEnabled;

  // Alamat Pengiriman
  final String addressLabel;
  final String streetAddress;
  final String rtRw;
  final String courierNotes;
  final String kelurahan;
  final String kecamatan;
  final String city;
  final String province;
  final String postalCode;
  final bool isDefaultAddress;

  const UserProfileModel({
    required this.fullName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.birthDate,
    required this.photoUrl,
    required this.tier,
    required this.points,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isBiometricEnabled = true,
    required this.addressLabel,
    required this.streetAddress,
    required this.rtRw,
    required this.courierNotes,
    required this.kelurahan,
    required this.kecamatan,
    required this.city,
    required this.province,
    required this.postalCode,
    this.isDefaultAddress = true,
  });

  /// Data awal profil pengguna default bersih dengan 0 poin
  factory UserProfileModel.initial() {
    return const UserProfileModel(
      fullName: 'Pengguna JNOVAMUSIC',
      username: 'jnova_member',
      email: '',
      phoneNumber: '',
      birthDate: '',
      photoUrl: '',
      tier: 'Non-Member',
      points: 0,
      isEmailVerified: false,
      isPhoneVerified: false,
      isBiometricEnabled: false,
      addressLabel: 'Rumah Utama',
      streetAddress: '',
      rtRw: '',
      courierNotes: '',
      kelurahan: '',
      kecamatan: '',
      city: '',
      province: '',
      postalCode: '',
      isDefaultAddress: true,
    );
  }

  UserProfileModel copyWith({
    String? fullName,
    String? username,
    String? email,
    String? phoneNumber,
    String? birthDate,
    String? photoUrl,
    String? tier,
    int? points,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isBiometricEnabled,
    String? addressLabel,
    String? streetAddress,
    String? rtRw,
    String? courierNotes,
    String? kelurahan,
    String? kecamatan,
    String? city,
    String? province,
    String? postalCode,
    bool? isDefaultAddress,
  }) {
    return UserProfileModel(
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      photoUrl: photoUrl ?? this.photoUrl,
      tier: tier ?? this.tier,
      points: points ?? this.points,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      addressLabel: addressLabel ?? this.addressLabel,
      streetAddress: streetAddress ?? this.streetAddress,
      rtRw: rtRw ?? this.rtRw,
      courierNotes: courierNotes ?? this.courierNotes,
      kelurahan: kelurahan ?? this.kelurahan,
      kecamatan: kecamatan ?? this.kecamatan,
      city: city ?? this.city,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
      isDefaultAddress: isDefaultAddress ?? this.isDefaultAddress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'birthDate': birthDate,
      'photoUrl': photoUrl,
      'tier': tier,
      'points': points,
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'isBiometricEnabled': isBiometricEnabled,
      'addressLabel': addressLabel,
      'streetAddress': streetAddress,
      'rtRw': rtRw,
      'courierNotes': courierNotes,
      'kelurahan': kelurahan,
      'kecamatan': kecamatan,
      'city': city,
      'province': province,
      'postalCode': postalCode,
      'isDefaultAddress': isDefaultAddress,
    };
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    final initial = UserProfileModel.initial();
    return UserProfileModel(
      fullName: map['fullName'] as String? ?? initial.fullName,
      username: map['username'] as String? ?? initial.username,
      email: map['email'] as String? ?? initial.email,
      phoneNumber: map['phoneNumber'] as String? ?? initial.phoneNumber,
      birthDate: map['birthDate'] as String? ?? initial.birthDate,
      photoUrl: map['photoUrl'] as String? ?? initial.photoUrl,
      tier: map['tier'] as String? ?? initial.tier,
      points: (map['points'] as num?)?.toInt() ?? initial.points,
      isEmailVerified:
          map['isEmailVerified'] as bool? ?? initial.isEmailVerified,
      isPhoneVerified:
          map['isPhoneVerified'] as bool? ?? initial.isPhoneVerified,
      isBiometricEnabled:
          map['isBiometricEnabled'] as bool? ?? initial.isBiometricEnabled,
      addressLabel: map['addressLabel'] as String? ?? initial.addressLabel,
      streetAddress:
          map['streetAddress'] as String? ?? initial.streetAddress,
      rtRw: map['rtRw'] as String? ?? initial.rtRw,
      courierNotes: map['courierNotes'] as String? ?? initial.courierNotes,
      kelurahan: map['kelurahan'] as String? ?? initial.kelurahan,
      kecamatan: map['kecamatan'] as String? ?? initial.kecamatan,
      city: map['city'] as String? ?? initial.city,
      province: map['province'] as String? ?? initial.province,
      postalCode: map['postalCode'] as String? ?? initial.postalCode,
      isDefaultAddress:
          map['isDefaultAddress'] as bool? ?? initial.isDefaultAddress,
    );
  }
}
