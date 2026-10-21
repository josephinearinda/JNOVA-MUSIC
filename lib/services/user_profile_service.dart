import 'package:flutter/foundation.dart';
import '../core/config/app_config.dart';
import '../core/network/network_info.dart';
import '../core/storage/secure_storage_service.dart';
import '../data/datasources/remote/supabase_client_service.dart';
import '../models/user_profile.dart';

/// Layanan manajemen profil pengguna terpusat untuk JNOVAMUSIC dengan penyimpanan aman & sinkronisasi Supabase
class UserProfileService extends ChangeNotifier {
  UserProfileService._() {
    _loadProfileFromStorage();
  }

  static final UserProfileService instance = UserProfileService._();
  final SupabaseClientService _supabaseService = SupabaseClientService.instance;
  final SecureStorageService _storage = SecureStorageService.instance;

  UserProfileModel _profile = UserProfileModel.initial();

  UserProfileModel get profile => _profile;

  Future<void> _loadProfileFromStorage() async {
    try {
      final map = await _storage.getProfile();
      if (map != null && map.isNotEmpty) {
        _profile = UserProfileModel.fromMap(map);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Memperbarui informasi profil pengguna dan menyimpannya secara persisten
  Future<bool> updateProfile({
    String? fullName,
    String? username,
    String? email,
    String? phoneNumber,
    String? birthDate,
    String? streetAddress,
    String? rtRw,
    String? courierNotes,
    String? kelurahan,
    String? kecamatan,
    String? city,
    String? province,
    String? postalCode,
    bool? isDefaultAddress,
  }) async {
    _profile = _profile.copyWith(
      fullName: fullName,
      username: username,
      email: email,
      phoneNumber: phoneNumber,
      birthDate: birthDate,
      streetAddress: streetAddress,
      rtRw: rtRw,
      courierNotes: courierNotes,
      kelurahan: kelurahan,
      kecamatan: kecamatan,
      city: city,
      province: province,
      postalCode: postalCode,
      isDefaultAddress: isDefaultAddress,
    );

    notifyListeners();

    // Simpan ke SecureStorage agar tersimpan permanen
    try {
      await _storage.saveProfile(_profile.toMap());
    } catch (_) {}

    // Sinkronkan ke Supabase jika online dan terotentikasi
    _syncProfileToSupabase();

    return true;
  }

  Future<void> _syncProfileToSupabase() async {
    final isOnline = await NetworkInfo.instance.isConnected;
    if (!isOnline || !AppConfig.isSupabaseConfigured || !_supabaseService.isInitialized) {
      return;
    }

    try {
      final client = _supabaseService.client;
      final user = client?.auth.currentUser;
      if (client != null && user != null) {
        await client.from('profiles').upsert({
          'id': user.id,
          'full_name': _profile.fullName,
          'username': _profile.username,
          'email': _profile.email,
          'phone_number': _profile.phoneNumber,
          'street_address': _profile.streetAddress,
          'city': _profile.city,
          'province': _profile.province,
          'postal_code': _profile.postalCode,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  /// Memperbarui foto profil
  void updatePhoto(String newPhotoUrl) {
    _profile = _profile.copyWith(photoUrl: newPhotoUrl);
    notifyListeners();
    try {
      _storage.saveProfile(_profile.toMap());
    } catch (_) {}
    _syncProfileToSupabase();
  }

  /// Menghapus foto profil kembali ke avatar default
  void removePhoto() {
    _profile = _profile.copyWith(photoUrl: '');
    notifyListeners();
    try {
      _storage.saveProfile(_profile.toMap());
    } catch (_) {}
    _syncProfileToSupabase();
  }

  /// Mengubah status login biometrik
  void toggleBiometric(bool value) {
    _profile = _profile.copyWith(isBiometricEnabled: value);
    notifyListeners();
    try {
      _storage.saveProfile(_profile.toMap());
    } catch (_) {}
  }
}
