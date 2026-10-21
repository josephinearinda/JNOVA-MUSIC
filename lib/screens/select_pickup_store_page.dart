import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_colors.dart';
import '../models/store_branch.dart';

/// Halaman Pemilihan Toko Pickup dengan Google Maps & Lokasi Pelanggan
class SelectPickupStorePage extends StatefulWidget {
  final StoreBranch selectedBranch;

  const SelectPickupStorePage({
    super.key,
    required this.selectedBranch,
  });

  @override
  State<SelectPickupStorePage> createState() => _SelectPickupStorePageState();
}

class _SelectPickupStorePageState extends State<SelectPickupStorePage> {
  GoogleMapController? _mapController;
  late StoreBranch _currentSelectedBranch;
  Position? _userPosition;
  bool _isLoadingLocation = false;
  String? _locationStatusMessage;
  List<StoreBranchWithDistance> _sortedBranches = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(-6.244265, 106.783478), // Jakarta Flagship
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _currentSelectedBranch = widget.selectedBranch;
    _initializeBranches();
    _detectUserLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeBranches() {
    _sortedBranches = StoreBranch.branches.map((b) {
      return StoreBranchWithDistance(
        branch: b,
        distanceMeters: null,
      );
    }).toList();
  }

  Future<void> _detectUserLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatusMessage = 'Mencari lokasi perangkat...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationStatusMessage = 'GPS tidak aktif. Menggunakan lokasi default.';
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLoadingLocation = false;
              _locationStatusMessage = 'Izin lokasi ditolak.';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationStatusMessage = 'Izin lokasi ditolak secara permanen.';
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      if (!mounted) return;

      setState(() {
        _userPosition = position;
        _isLoadingLocation = false;
        _locationStatusMessage = 'Lokasimu berhasil dideteksi.';

        // Hitung jarak ke setiap cabang & urutkan dari yang paling dekat
        _sortedBranches = StoreBranch.branches.map((b) {
          final distanceMeters = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            b.latitude,
            b.longitude,
          );
          return StoreBranchWithDistance(
            branch: b,
            distanceMeters: distanceMeters,
          );
        }).toList();

        _sortedBranches.sort((a, b) {
          if (a.distanceMeters == null || b.distanceMeters == null) return 0;
          return a.distanceMeters!.compareTo(b.distanceMeters!);
        });

        // Pilih otomatis cabang terdekat jika belum diubah manual
        if (_sortedBranches.isNotEmpty) {
          _currentSelectedBranch = _sortedBranches.first.branch;
          _animateToBranch(_currentSelectedBranch);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationStatusMessage = 'Gagal memuat GPS: $e';
        });
      }
    }
  }

  void _animateToBranch(StoreBranch branch) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(branch.latitude, branch.longitude),
          zoom: 14.5,
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    for (final item in _sortedBranches) {
      final b = item.branch;
      final isSelected = b.id == _currentSelectedBranch.id;

      markers.add(
        Marker(
          markerId: MarkerId(b.id),
          position: LatLng(b.latitude, b.longitude),
          infoWindow: InfoWindow(
            title: b.name,
            snippet: b.address,
          ),
          icon: isSelected
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () {
            setState(() {
              _currentSelectedBranch = b;
            });
            _animateToBranch(b);
          },
        ),
      );
    }

    if (_userPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_current_location'),
          position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Lokasi Anda'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    return markers;
  }

  Future<void> _openGoogleMapsRoute(StoreBranch branch) async {
    final urlString = branch.getDirectionsUrl(
      _userPosition?.latitude,
      _userPosition?.longitude,
    );
    final uri = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka Google Maps: $urlString'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kesalahan saat membuka rute: $e'),
        ),
      );
    }
  }

  Future<void> _callStore(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  String _formatDistance(double? meters) {
    if (meters == null) return '';
    if (meters < 1000) {
      return '${meters.round()} m dari lokasimu';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km dari lokasimu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih Toko Pengambilan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
            Text(
              '5 Cabang Resmi JNOVAMUSIC di Indonesia',
              style: TextStyle(fontSize: 10, color: Color(0xFF7E756F)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Deteksi Lokasi Saya',
            icon: _isLoadingLocation
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.primaryOrange),
                    ),
                  )
                : const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primaryOrange,
                  ),
            onPressed: _detectUserLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          // Peta Google Maps
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _initialCamera,
                  markers: _buildMarkers(),
                  myLocationEnabled: _userPosition != null,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _animateToBranch(_currentSelectedBranch);
                  },
                ),

                // Floating bar info status GPS di atas peta
                if (_locationStatusMessage != null)
                  Positioned(
                    top: 10,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            size: 14,
                            color: AppColors.primaryOrange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _locationStatusMessage!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5A524D),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_userPosition != null)
                            const Text(
                              'GPS Aktif',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Tombol Center ke Cabang Terpilih
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter_map',
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryOrange,
                    elevation: 3,
                    onPressed: () => _animateToBranch(_currentSelectedBranch),
                    child: const Icon(Icons.center_focus_strong_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Daftar Toko & Tombol Konfirmasi
          Expanded(
            flex: 6,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header List: Cabang Terdekat
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pilih Toko untuk Pengambilan',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                        if (_userPosition != null)
                          const Row(
                            children: [
                              Icon(Icons.sort_rounded, size: 13, color: AppColors.primaryOrange),
                              SizedBox(width: 3),
                              Text(
                                'Urut Terdekat',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Search Box Toko
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF9F7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEBE8E3)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim().toLowerCase();
                          });
                        },
                        style: const TextStyle(fontSize: 11, color: AppColors.textPrimaryDark),
                        decoration: InputDecoration(
                          hintText: 'Cari toko atau kota (Bali, Bandung, Jkt, Jogja, Solo)...',
                          hintStyle: const TextStyle(fontSize: 10.5, color: Color(0xFF9E958F)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF7E756F)),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 15, color: Color(0xFF7E756F)),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                    ),
                  ),

                  // List Cabang Toko
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final filteredList = _sortedBranches.where((item) {
                          if (_searchQuery.isEmpty) return true;
                          final b = item.branch;
                          return b.name.toLowerCase().contains(_searchQuery) ||
                              b.address.toLowerCase().contains(_searchQuery) ||
                              b.tag.toLowerCase().contains(_searchQuery);
                        }).toList();

                        if (filteredList.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.storefront_outlined,
                                    size: 40,
                                    color: Color(0xFFB0AAA4),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Toko Tidak Ditemukan',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Tidak ada cabang yang cocok dengan kata kunci pencarian Anda.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF8E837D),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                    child: const Text(
                                      'Reset Pencarian',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryOrange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredList.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            final b = item.branch;
                            final isSelected = b.id == _currentSelectedBranch.id;
                            final distanceText = item.distanceMeters != null
                                ? _formatDistance(item.distanceMeters)
                                : b.distance;

                            return Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFFF9F5)
                                    : const Color(0xFFFAF9F7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryOrange
                                  : const Color(0xFFEBE8E3),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _currentSelectedBranch = b;
                              });
                              _animateToBranch(b);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.storefront_rounded,
                                        size: 16,
                                        color: isSelected
                                            ? AppColors.primaryOrange
                                            : const Color(0xFF7E756F),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          b.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: isSelected
                                                ? AppColors.primaryOrange
                                                : AppColors.textPrimaryDark,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle_rounded
                                            : Icons.radio_button_unchecked_rounded,
                                        size: 18,
                                        color: isSelected
                                            ? AppColors.primaryOrange
                                            : const Color(0xFFB0AAA4),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFEFE5),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          distanceText,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFC2410C),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Buka: ${b.operatingHours}',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Color(0xFF7E756F),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    b.address,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      color: Color(0xFF6E6560),
                                      height: 1.25,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _openGoogleMapsRoute(b),
                                            icon: const Icon(Icons.directions_rounded, size: 14),
                                            label: const Text('Rute Maps'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.primaryOrange,
                                              side: const BorderSide(
                                                color: AppColors.primaryOrange,
                                              ),
                                              visualDensity: VisualDensity.compact,
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                              textStyle: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _callStore(b.phone),
                                            icon: const Icon(Icons.phone_rounded, size: 14),
                                            label: const Text('Telepon Toko'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(0xFF2E2825),
                                              side: const BorderSide(
                                                color: Color(0xFFD4D0C8),
                                              ),
                                              visualDensity: VisualDensity.compact,
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                              textStyle: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

                  // Tombol Aksi Konfirmasi Toko Terpilih
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Color(0xFFF2F0ED), width: 1),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, _currentSelectedBranch);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Pilih ${_currentSelectedBranch.name}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
