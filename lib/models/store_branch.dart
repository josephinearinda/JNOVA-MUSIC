/// Model cabang toko resmi JNOVAMUSIC untuk opsi Ambil di Toko
/// Data disesuaikan 100% dari CSV resmi: Bali, Bandung, Jakarta, Jogja, dan Solo
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
  final double latitude;
  final double longitude;
  final String phone;

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
    required this.latitude,
    required this.longitude,
    required this.phone,
  });

  String get mapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  String getDirectionsUrl([double? userLat, double? userLng]) {
    if (userLat != null && userLng != null) {
      return 'https://www.google.com/maps/dir/?api=1&origin=$userLat,$userLng&destination=$latitude,$longitude&travelmode=driving';
    }
    return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';
  }

  static StoreBranch findById(String? id) {
    if (id == null || id.isEmpty) return branches.first;
    return branches.firstWhere(
      (b) => b.id == id,
      orElse: () => branches.first,
    );
  }

  /// Daftar cabang resmi JNOVAMUSIC disesuaikan dari data CSV riil:
  /// Bali, Bandung, Jakarta, Jogja, dan Solo
  static List<StoreBranch> get branches => const [
        // === BALI (Bali_TokoMusik.csv) ===
        StoreBranch(
          id: 'ypid:YN458DB2EF913B5CCD',
          name: 'Rockpizz Singaraja',
          tag: 'Cabang Bali',
          distance: 'Bali, Indonesia',
          address: 'Jalan Samratulangi Penarukan Bali',
          operatingHours: 'Open · Closes 21:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -8.101308822631836,
          longitude: 115.11983489990234,
          phone: '0819-1653-7000',
        ),
        StoreBranch(
          id: 'ypid:YN64F61D2DE85F5FCC',
          name: 'Red Musik',
          tag: 'Cabang Bali',
          distance: 'Bali, Indonesia',
          address: 'Jalan Merpati 33 80119 Tegal Kertha Bali',
          operatingHours: 'Closed · Opens tomorrow 09:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -8.656976699829102,
          longitude: 115.19608306884766,
          phone: '0819-9997-1515',
        ),
        StoreBranch(
          id: 'ypid:YN6F73FFC429905C1C',
          name: 'Melodramatic Music Store',
          tag: 'Cabang Bali',
          distance: 'Bali, Indonesia',
          address: 'Jalan Sedap Malam Kesiman Bali',
          operatingHours: 'Open · Closes 22:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -8.663582801818848,
          longitude: 115.25016021728516,
          phone: '0823-4249-6040',
        ),
        StoreBranch(
          id: 'ypid:YN66C14E2C8A568BDA',
          name: 'Yamaha Music Store Bali',
          tag: 'Cabang Bali',
          distance: 'Bali, Indonesia',
          address: 'Jalan Diponegoro 114 80232 Dauh Puri Bali',
          operatingHours: 'Closed · Opens tomorrow 10:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -8.663618087768555,
          longitude: 115.21511840820312,
          phone: '(0361) 226886',
        ),
        StoreBranch(
          id: 'ypid:YN9895E25A450CBEFD',
          name: 'Rockpizz Music Batubulan',
          tag: 'Cabang Bali',
          distance: 'Bali, Indonesia',
          address: 'Jalan Raya Batubulan 21 80582 Batubulan Bali',
          operatingHours: 'Open · Closes 21:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -8.613082885742188,
          longitude: 115.253662109375,
          phone: '0819-1653-7000',
        ),

        // === BANDUNG (Bandung_TokoMusik.csv) ===
        StoreBranch(
          id: 'ypid:YN3170D354035ABD74',
          name: 'Tiga Negeri Music House',
          tag: 'Cabang Bandung',
          distance: 'Bandung, Jawa Barat',
          address: 'Jalan Soka 6 40113 Merdeka West Java',
          operatingHours: 'Closed · Opens tomorrow 09:30',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -6.915881633758545,
          longitude: 107.62635040283203,
          phone: '(022) 7208123',
        ),
        StoreBranch(
          id: 'ypid:YN95C9106958229FDF',
          name: 'Nada Musical Instrument Store',
          tag: 'Cabang Bandung',
          distance: 'Bandung, Jawa Barat',
          address: 'Jalan Sunda 111 Kebon Pisang West Java',
          operatingHours: 'Closed · Opens tomorrow 09:45',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -6.921096324920654,
          longitude: 107.61787414550781,
          phone: '(022) 4205169',
        ),
        StoreBranch(
          id: 'ypid:YN32507431232AC724',
          name: 'Sumber Makmur Music',
          tag: 'Cabang Bandung',
          distance: 'Bandung, Jawa Barat',
          address: 'Jalan Balonggede 97 40251 Balong Gede West Java',
          operatingHours: 'Closed · Opens tomorrow 10:30',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -6.927428245544434,
          longitude: 107.60782623291016,
          phone: '(022) 4215672',
        ),

        // === JAKARTA (Jakarta_TokoMusik.csv) ===
        StoreBranch(
          id: 'ypid:YN3F0F94DFF32B9F6F',
          name: 'MG Sports & Music - Blok M',
          tag: 'Cabang Utama Jakarta',
          distance: 'Jakarta Selatan, DKI Jakarta',
          address: 'Jalan Panglima Polim Raya Kramat Pela Special Capital Region of Jakarta',
          operatingHours: 'Closed · Opens tomorrow 11:00',
          stockStatus: '3 Unit Siap di Toko',
          availableStock: 3,
          isMainBranch: true,
          latitude: -6.244929313659668,
          longitude: 106.79830932617188,
          phone: '(021) 7206020',
        ),
        StoreBranch(
          id: 'ypid:YN3718A5BEFBC7C27B',
          name: 'MG Sport & Music - Mangga Besar',
          tag: 'Cabang Jakarta',
          distance: 'Jakarta Barat, DKI Jakarta',
          address: 'Jalan Mangga Besar Raya 41 11180 Mangga Besar Special Capital Region of Jakarta',
          operatingHours: 'Closed · Opens tomorrow 10:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -6.149697303771973,
          longitude: 106.82068634033203,
          phone: '(021) 6283231',
        ),
        StoreBranch(
          id: 'ypid:YND468B3421FF91F26',
          name: 'Bandar Musik Jakarta BMJ',
          tag: 'Cabang Jakarta',
          distance: 'Jakarta Pusat, DKI Jakarta',
          address: 'Jalan Lautze 78 10750 Pasar Baru Special Capital Region of Jakarta',
          operatingHours: 'Closed · Opens tomorrow 10:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -6.1467061042785645,
          longitude: 106.8377914428711,
          phone: '0819-2929-0560',
        ),
        StoreBranch(
          id: 'ypid:YN2DA68D3D806A8198',
          name: 'Wijaya Musik Pasar Baru',
          tag: 'Cabang Jakarta',
          distance: 'Jakarta Pusat, DKI Jakarta',
          address: 'Jalan Pasar Baru 12 10710 Pasar Baru Special Capital Region of Jakarta',
          operatingHours: 'Closed · Opens tomorrow 10:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -6.165143966674805,
          longitude: 106.83464813232422,
          phone: '(021) 3840705',
        ),
        StoreBranch(
          id: 'ypid:YN6D06C21A959BD1D8',
          name: 'Yamaha Music Square - Plaza Indonesia',
          tag: 'Cabang Jakarta',
          distance: 'Jakarta Pusat, DKI Jakarta',
          address: 'Jalan M. Mashabi 12a Kebon Melati Special Capital Region of Jakarta',
          operatingHours: 'Open · Closes 22:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -6.1947503089904785,
          longitude: 106.81982421875,
          phone: '0859-2133-7866',
        ),
        StoreBranch(
          id: 'ypid:YN1D04F79DB631DDBA',
          name: 'Sincere Yamaha Music',
          tag: 'Cabang Jakarta',
          distance: 'Jakarta Pusat, DKI Jakarta',
          address: 'Jalan Bungur Besar Raya 10620 Kemayoran Special Capital Region of Jakarta',
          operatingHours: 'Closed · Opens tomorrow 08:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -6.164178371429443,
          longitude: 106.8412857055664,
          phone: '(021) 4243173',
        ),
        StoreBranch(
          id: 'ypid:YN47371F510AA4D764',
          name: 'Galeri Musik Indonesia.com',
          tag: 'Cabang Jakarta',
          distance: 'Jakarta Utara, DKI Jakarta',
          address: 'Jalan Sunter Mas Barat I 14350 Sunter Jaya Special Capital Region of Jakarta',
          operatingHours: 'Closed · Opens tomorrow 09:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -6.157591342926025,
          longitude: 106.87090301513672,
          phone: '(021) 65306112',
        ),
        StoreBranch(
          id: 'ypid:YN2C86619473E5E997',
          name: 'PT Megah Gentaswara - MG Music',
          tag: 'Cabang Jakarta',
          distance: 'Jakarta Utara, DKI Jakarta',
          address: 'Jalan Danau Sunter Selatan 46 14350 Sunter Jaya Special Capital Region of Jakarta',
          operatingHours: 'Closed · Opens tomorrow 08:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -6.1437811851501465,
          longitude: 106.88440704345703,
          phone: '(021) 6504868',
        ),
        StoreBranch(
          id: 'ypid:YN1AB367396AE1825',
          name: 'Wijaya Musik Putra Kelapa Gading',
          tag: 'Cabang Jakarta',
          distance: 'Jakarta Utara, DKI Jakarta',
          address: 'Jalan Boulevard Barat Raya 15 Kelapa Gading Barat Special Capital Region of Jakarta',
          operatingHours: 'Open · Closes 19:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -6.154747009277344,
          longitude: 106.8945083618164,
          phone: '(021) 45851219',
        ),
        StoreBranch(
          id: 'ypid:YN2158843EF517CC5D',
          name: "Chic's Musik Rawamangun",
          tag: 'Cabang Jakarta',
          distance: 'Jakarta Timur, DKI Jakarta',
          address: 'Jalan Pemuda 13220 Jati Special Capital Region of Jakarta',
          operatingHours: 'Closed · Opens tomorrow 10:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -6.193930625915527,
          longitude: 106.89444732666016,
          phone: '0811-1565-565',
        ),

        // === JOGJA (Jogja_TokoMusik.csv) ===
        StoreBranch(
          id: 'ypid:YN1550CBAF985B869',
          name: 'Kurnia Musik Jogja',
          tag: 'Cabang Yogyakarta',
          distance: 'Sleman, D.I. Yogyakarta',
          address: 'Jalan Magelang 55284 Sinduadi Special Region of Yogyakarta',
          operatingHours: 'Closed · Opens tomorrow 10:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -7.753913879394531,
          longitude: 110.36203002929688,
          phone: '0821-3438-4858',
        ),
        StoreBranch(
          id: 'ypid:YNC36BD0070B91700B',
          name: 'Melodia Musik Yogyakarta',
          tag: 'Cabang Yogyakarta',
          distance: 'Kota Yogyakarta, D.I. Yogyakarta',
          address: 'Jalan C. Simanjuntak 18 55223 Terban Special Region of Yogyakarta',
          operatingHours: 'Closed · Opens tomorrow 11:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -7.779523849487305,
          longitude: 110.37325286865234,
          phone: '0877-7051-5107',
        ),
        StoreBranch(
          id: 'ypid:YN2DBD8A0E8613D63D',
          name: 'Diana Musik',
          tag: 'Cabang Yogyakarta',
          distance: 'Kota Yogyakarta, D.I. Yogyakarta',
          address: 'Jalan Pakuningratan 51 55233 Cokrodiningratan Special Region of Yogyakarta',
          operatingHours: 'Closed · Opens tomorrow 09:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -7.781036376953125,
          longitude: 110.36370849609375,
          phone: '0878-5096-5758',
        ),
        StoreBranch(
          id: 'ypid:YN198C4E4D587D0738',
          name: 'Zeal Musik',
          tag: 'Cabang Yogyakarta',
          distance: 'Sleman, D.I. Yogyakarta',
          address: 'Perumahan Griya Mahkota Blok F 7 Nogotirto Special Region of Yogyakarta',
          operatingHours: 'Closed · Opens tomorrow 10:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -7.774946689605713,
          longitude: 110.34664154052734,
          phone: '0878-7802-0514',
        ),

        // === SOLO (Solo_TokoMusik.csv) ===
        StoreBranch(
          id: 'ypid:YN38C8820BB052A8C2',
          name: 'Queen Music Solo',
          tag: 'Cabang Solo',
          distance: 'Surakarta, Jawa Tengah',
          address: 'Jalan R.E. Martadinata 62 57121 Kampung Baru Jawa Tengah',
          operatingHours: 'Closed · Opens tomorrow 09:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -7.570154666900635,
          longitude: 110.83258056640625,
          phone: '(0271) 643315',
        ),
        StoreBranch(
          id: 'ypid:YN3DD37CEC8389B332',
          name: 'Yamaha Musik Wisma Kurnia Solo',
          tag: 'Cabang Solo',
          distance: 'Surakarta, Jawa Tengah',
          address: 'Slamet Riyadi St 159 57151 Surakarta Jawa Tengah',
          operatingHours: 'Closed · Opens tomorrow 10:00',
          stockStatus: 'Stok Siap di Toko',
          availableStock: 3,
          isMainBranch: false,
          latitude: -7.570523262023926,
          longitude: 110.82215881347656,
          phone: '0821-3525-9970',
        ),
      ];
}

/// Model pembungkus cabang toko dengan informasi jarak aktual dari pengguna
class StoreBranchWithDistance {
  final StoreBranch branch;
  final double? distanceMeters;
  final bool isNearest;

  const StoreBranchWithDistance({
    required this.branch,
    required this.distanceMeters,
    this.isNearest = false,
  });

  String get formattedDistance {
    if (distanceMeters == null) return branch.distance;
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()} m';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
  }
}
