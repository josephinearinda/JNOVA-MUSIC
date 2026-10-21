import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      final activeEmail = await _storage.getUserEmail();
      if (activeEmail != null && activeEmail.isNotEmpty) {
        await loadProfileForUser(activeEmail);
        return;
      }

      final map = await _storage.getProfile();
      if (map != null && map.isNotEmpty) {
        _profile = UserProfileModel.fromMap(map);
        if (_profile.email.isNotEmpty) {
          final isEnabled =
              await _storage.isBiometricEnabledForUser(_profile.email);
          _profile = _profile.copyWith(isBiometricEnabled: isEnabled);
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Memuat profil spesifik untuk pengguna aktif yang sedang login
  Future<void> loadProfileForUser(String email, {String? fullName}) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return;

    try {
      final savedMap = await _storage.getProfileForUser(cleanEmail);
      if (savedMap != null && savedMap.isNotEmpty) {
        _profile = UserProfileModel.fromMap(savedMap);
        if (fullName != null &&
            fullName.isNotEmpty &&
            (_profile.fullName == 'Pengguna JNOVAMUSIC' ||
                _profile.fullName.isEmpty)) {
          _profile = _profile.copyWith(fullName: fullName);
        }
      } else {
        // Periksa data registrasi lokal
        final users = await _storage.getRegisteredUsers();
        final regData = users[cleanEmail];
        final name = fullName ??
            (regData?['fullName'] as String?) ??
            'Pengguna JNOVAMUSIC';

        _profile = UserProfileModel.initial().copyWith(
          email: cleanEmail,
          fullName: name,
          username: cleanEmail.split('@').first,
          points: 0,
        );
      }

      // Pastikan email selalu konsisten dengan akun login aktif
      if (_profile.email.isEmpty || _profile.email.toLowerCase().trim() != cleanEmail) {
        _profile = _profile.copyWith(email: cleanEmail);
      }

      final isEnabled = await _storage.isBiometricEnabledForUser(cleanEmail);
      _profile = _profile.copyWith(isBiometricEnabled: isEnabled);

      // Sinkronkan status verifikasi autentikasi dari Supabase jika tersedia
      if (AppConfig.isSupabaseConfigured && _supabaseService.isInitialized) {
        final client = _supabaseService.client;
        final currentUser = client?.auth.currentUser;
        if (currentUser != null &&
            currentUser.email?.toLowerCase().trim() == cleanEmail) {
          final isEmailVerified = currentUser.emailConfirmedAt != null;
          final isPhoneVerified = currentUser.phoneConfirmedAt != null;
          _profile = _profile.copyWith(
            isEmailVerified: isEmailVerified,
            isPhoneVerified: isPhoneVerified,
          );
        }
      }

      await _storage.saveProfile(_profile.toMap());
      await _storage.saveProfileForUser(cleanEmail, _profile.toMap());
      notifyListeners();

      _loadProfileFromSupabase(cleanEmail);
    } catch (_) {}
  }

  Future<void> _loadProfileFromSupabase(String email) async {
    final isOnline = await NetworkInfo.instance.isConnected;
    if (!isOnline ||
        !AppConfig.isSupabaseConfigured ||
        !_supabaseService.isInitialized) {
      return;
    }

    try {
      final client = _supabaseService.client;
      final user = client?.auth.currentUser;
      if (client != null && user != null && user.email == email) {
        final data = await client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        final isEmailVerified = user.emailConfirmedAt != null;
        final isPhoneVerified = user.phoneConfirmedAt != null;

        if (data != null) {
          final fullName = data['full_name'] as String?;
          final phone = data['phone_number'] as String?;
          final address = data['street_address'] as String?;
          final city = data['city'] as String?;
          final province = data['province'] as String?;
          final postal = data['postal_code'] as String?;
          final avatarUrl = data['avatar_url'] as String?;

          _profile = _profile.copyWith(
            fullName: fullName != null && fullName.isNotEmpty
                ? fullName
                : _profile.fullName,
            phoneNumber: phone != null && phone.isNotEmpty
                ? phone
                : _profile.phoneNumber,
            streetAddress: address != null && address.isNotEmpty
                ? address
                : _profile.streetAddress,
            city: city != null && city.isNotEmpty ? city : _profile.city,
            province: province != null && province.isNotEmpty
                ? province
                : _profile.province,
            postalCode: postal != null && postal.isNotEmpty
                ? postal
                : _profile.postalCode,
            photoUrl: avatarUrl != null && avatarUrl.isNotEmpty
                ? avatarUrl
                : _profile.photoUrl,
            isEmailVerified: isEmailVerified,
            isPhoneVerified: isPhoneVerified,
          );

          await _storage.saveProfile(_profile.toMap());
          await _storage.saveProfileForUser(email, _profile.toMap());
          notifyListeners();
        } else {
          _profile = _profile.copyWith(
            isEmailVerified: isEmailVerified,
            isPhoneVerified: isPhoneVerified,
          );
          await _storage.saveProfile(_profile.toMap());
          await _storage.saveProfileForUser(email, _profile.toMap());
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  /// Memuat ulang profil dari penyimpanan lokal dan backend Supabase
  Future<void> refreshProfile() async {
    final activeEmail = await _storage.getUserEmail();
    if (activeEmail != null && activeEmail.isNotEmpty) {
      await loadProfileForUser(activeEmail);
    } else if (_profile.email.isNotEmpty) {
      await loadProfileForUser(_profile.email);
    } else {
      await _loadProfileFromStorage();
    }
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
    int? points,
    String? tier,
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
      points: points,
      tier: tier,
    );

    notifyListeners();

    try {
      await _storage.saveProfile(_profile.toMap());
      if (_profile.email.isNotEmpty) {
        await _storage.saveProfileForUser(_profile.email, _profile.toMap());
      }
    } catch (_) {}

    _syncProfileToSupabase();

    return true;
  }

  Future<void> _syncProfileToSupabase() async {
    final isOnline = await NetworkInfo.instance.isConnected;
    if (!isOnline ||
        !AppConfig.isSupabaseConfigured ||
        !_supabaseService.isInitialized) {
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
          'avatar_url': _profile.photoUrl,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  /// Memilih foto dari galeri atau kamera dan menyimpannya ke profil
  Future<Map<String, dynamic>> pickAndUploadPhoto({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return {
          'success': false,
          'cancelled': true,
          'message': 'Pemilihan foto dibatalkan.',
        };
      }

      final file = File(pickedFile.path);
      if (!await file.exists()) {
        return {
          'success': false,
          'message': 'Berkas gambar tidak ditemukan di perangkat.',
        };
      }

      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        return {
          'success': false,
          'message': 'Ukuran foto melebihi batas maksimal 5MB.',
        };
      }

      String finalUrl = pickedFile.path;

      // Unggah ke Supabase Storage jika online
      final isOnline = await NetworkInfo.instance.isConnected;
      if (isOnline &&
          AppConfig.isSupabaseConfigured &&
          _supabaseService.isInitialized) {
        try {
          final client = _supabaseService.client;
          final user = client?.auth.currentUser;
          if (client != null && user != null) {
            final ext = pickedFile.name.split('.').last;
            final fileName =
                '${user.id}_avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
            await client.storage.from('avatars').uploadBinary(
                  fileName,
                  bytes,
                  fileOptions: const FileOptions(upsert: true),
                );
            final publicUrl =
                client.storage.from('avatars').getPublicUrl(fileName);
            if (publicUrl.isNotEmpty) {
              finalUrl = publicUrl;
            }
          }
        } catch (_) {
          // Tetap gunakan path lokal jika penyimpanan cloud belum dibuat
        }
      }

      updatePhoto(finalUrl);
      return {
        'success': true,
        'message': 'Foto profil berhasil diperbarui.',
        'url': finalUrl,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal memperbarui foto profil: $e',
      };
    }
  }

  /// Memperbarui foto profil secara langsung
  void updatePhoto(String newPhotoUrl) {
    _profile = _profile.copyWith(photoUrl: newPhotoUrl);
    notifyListeners();
    try {
      _storage.saveProfile(_profile.toMap());
      if (_profile.email.isNotEmpty) {
        _storage.saveProfileForUser(_profile.email, _profile.toMap());
      }
    } catch (_) {}
    _syncProfileToSupabase();
  }

  /// Menghapus foto profil kembali ke avatar bawaan
  Future<bool> removePhoto() async {
    try {
      final oldUrl = _profile.photoUrl;
      _profile = _profile.copyWith(photoUrl: '');
      notifyListeners();

      await _storage.saveProfile(_profile.toMap());
      if (_profile.email.isNotEmpty) {
        await _storage.saveProfileForUser(_profile.email, _profile.toMap());
      }

      final isOnline = await NetworkInfo.instance.isConnected;
      if (isOnline &&
          AppConfig.isSupabaseConfigured &&
          _supabaseService.isInitialized) {
        try {
          final client = _supabaseService.client;
          final user = client?.auth.currentUser;
          if (client != null && user != null) {
            await client
                .from('profiles')
                .update({'avatar_url': null}).eq('id', user.id);
            if (oldUrl.contains('/avatars/')) {
              final path = oldUrl.split('/avatars/').last;
              await client.storage.from('avatars').remove([path]);
            }
          }
        } catch (_) {}
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mengubah status login biometrik dan menyinkronkan dengan SecureStorage
  Future<void> toggleBiometric(bool value) async {
    _profile = _profile.copyWith(isBiometricEnabled: value);
    notifyListeners();
    try {
      await _storage.saveProfile(_profile.toMap());
      if (_profile.email.isNotEmpty) {
        await _storage.saveProfileForUser(_profile.email, _profile.toMap());
        if (value) {
          await _storage.setBiometricEnabledForUser(_profile.email, true);
        } else {
          await _storage.clearBiometricForUser(_profile.email);
        }
      }
    } catch (_) {}
  }

  /// Reset profil saat logout
  void resetProfile() {
    _profile = UserProfileModel.initial();
    notifyListeners();
  }
}
