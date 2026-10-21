/// Model cabang toko resmi JNOVAMUSIC untuk opsi Ambil di Toko
class StoreBranch {
  final String id;
  final String name;
  final String tag;
  final String distance;
  final String address;
  final String operatingHours;
  final String stockStatus;
  final int availableStock;
  final bool isMainBranch;

  const StoreBranch({
    required this.id,
    required this.name,
    required this.tag,
    required this.distance,
    required this.address,
    required this.operatingHours,
    required this.stockStatus,
    this.availableStock = 3,
    this.isMainBranch = false,
  });

  /// Daftar cabang resmi JNOVAMUSIC sesuai data desain Figma
  static List<StoreBranch> get branches => const [
        StoreBranch(
          id: 'store_jkt',
          name: 'JNOVAMUSIC Flagship Jakarta',
          tag: 'Cabang Utama',
          distance: '1.6 km dari lokasimu',
          address:
              'Jl. Sultan Iskandar Muda No. 88, Kebayoran Lama, Jakarta Selatan',
          operatingHours: '10.00 - 21.00 WIB',
          stockStatus: '3 Unit Siap di Toko',
          availableStock: 3,
          isMainBranch: true,
        ),
        StoreBranch(
          id: 'store_bdg',
          name: 'JNOVAMUSIC Bandung Dago',
          tag: 'Cabang Bandung',
          distance: '142 km dari lokasimu',
          address: 'Jl. Ir. H. Juanda No. 120, Coblong, Kota Bandung',
          operatingHours: '10.00 - 21.00 WIB',
          stockStatus: 'Stok Tersedia',
          availableStock: 2,
        ),
        StoreBranch(
          id: 'store_ygy',
          name: 'JNOVAMUSIC Yogyakarta Malioboro',
          tag: 'Cabang Yogyakarta',
          distance: '450 km dari lokasimu',
          address: 'Jl. Malioboro No. 45, Danurejan, Kota Yogyakarta',
          operatingHours: '09.30 - 21.00 WIB',
          stockStatus: 'Stok Tersedia',
          availableStock: 2,
        ),
        StoreBranch(
          id: 'store_slo',
          name: 'JNOVAMUSIC Solo Slamet Riyadi',
          tag: 'Cabang Solo',
          distance: '510 km dari lokasimu',
          address: 'Jl. Slamet Riyadi No. 230, Timuran, Banjarsari, Kota Surakarta',
          operatingHours: '10.00 - 21.00 WIB',
          stockStatus: 'Stok Tersedia',
          availableStock: 1,
        ),
        StoreBranch(
          id: 'store_dps',
          name: 'JNOVAMUSIC Bali Sunset Road',
          tag: 'Cabang Bali',
          distance: '960 km dari lokasimu',
          address: 'Jl. Sunset Road No. 89, Kuta, Kabupaten Badung, Bali',
          operatingHours: '10.00 - 22.00 WITA',
          stockStatus: 'Stok Tersedia',
          availableStock: 2,
        ),
      ];
}
