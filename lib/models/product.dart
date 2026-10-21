/// Model data produk JNOVAMUSIC
class Product {
  final String id;
  final String name;
  final String brand;
  final int price;
  final String image;
  final double rating;
  final int reviewCount;
  final bool isOriginal;
  final bool isBestSeller;
  final String variant;
  final String category;
  final String code;
  final int stock;
  final String description;
  final Map<String, String> specs;
  final List<String> colorVariants;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.image,
    required this.rating,
    required this.reviewCount,
    this.isOriginal = false,
    this.isBestSeller = false,
    this.variant = '',
    this.category = 'Gitar',
    this.code = '0140512500',
    this.stock = 5,
    this.description =
        'Fender Player II Stratocaster HSS memadukan karakter suara ikonik Strat klasik dengan tenaga ekstra humbucker modern. Dilengkapi pickup bridge Player Series Alnico 2 Humbucking serta neck Modern "C" berbahan maple dengan radius 9.5 inci untuk kenyamanan bermain optimal di berbagai gaya musik.',
    this.specs = const {
      'Merek': 'Fender Musical Instruments',
      'Seri': 'Player II Series (2024/2025)',
      'Tipe Instrumen': 'Gitar Elektrik Solidbody',
      'Material Bodi': 'Alder (Gloss Polyester Finish)',
      'Material Neck': 'Maple, Modern "C" Shape',
      'Fingerboard': 'Maple, Radius 9.5" (241 mm)',
      'Jumlah Fret': '22 Fret Medium Jumbo',
      'Pickup Konfigurasi': 'HSS (Player Alnico 2 & 5)',
      'Tremolo / Bridge': '2-Point Synchronized Bent Steel',
      'Kelengkapan':
          'Garansi Resmi Fender Indonesia, Truss Wrench, Manual Book',
    },
    this.colorVariants = const ['3-Color Sunburst', 'Polar White', 'Aquatone Blue'],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'price': price,
      'image_url': image,
      'rating': rating,
      'review_count': reviewCount,
      'is_original': isOriginal ? 1 : 0,
      'is_best_seller': isBestSeller ? 1 : 0,
      'variant': variant,
      'category': category,
      'code': code,
      'stock': stock,
      'description': description,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      brand: map['brand']?.toString() ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      image: map['image_url']?.toString() ?? map['image']?.toString() ?? 'assets/images/fav_fender.png',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
      isOriginal: map['is_original'] == 1 || map['is_original'] == true,
      isBestSeller: map['is_best_seller'] == 1 || map['is_best_seller'] == true,
      variant: map['variant']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Gitar',
      code: map['code']?.toString() ?? '',
      stock: (map['stock'] as num?)?.toInt() ?? 5,
      description: map['description']?.toString() ?? '',
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    int? price,
    String? image,
    double? rating,
    int? reviewCount,
    bool? isOriginal,
    bool? isBestSeller,
    String? variant,
    String? category,
    String? code,
    int? stock,
    String? description,
    Map<String, String>? specs,
    List<String>? colorVariants,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      image: image ?? this.image,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isOriginal: isOriginal ?? this.isOriginal,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      variant: variant ?? this.variant,
      category: category ?? this.category,
      code: code ?? this.code,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      specs: specs ?? this.specs,
      colorVariants: colorVariants ?? this.colorVariants,
    );
  }

  /// Daftar 4 produk awal untuk Favorit
  static List<Product> get initialProducts => allCatalog.take(4).toList();


  /// Seluruh katalog produk resmi JNOVAMUSIC berdasarkan screenshot Figma
  static List<Product> get allCatalog => [
        const Product(
          id: 'p1',
          brand: 'FENDER',
          name: 'Fender Player II Stratocaster HSS',
          price: 14850000,
          image: 'assets/images/fav_fender.png',
          rating: 4.9,
          reviewCount: 48,
          isOriginal: true,
          isBestSeller: false,
          variant: 'Maple Fretboard, 3-Color Sunburst',
          category: 'Gitar',
          code: '0140512500',
          stock: 5,
        ),
        const Product(
          id: 'p2',
          brand: 'YAMAHA',
          name: 'Yamaha P-125 Digital Piano 88-Key',
          price: 9750000,
          image: 'assets/images/fav_yamaha.png',
          rating: 5.0,
          reviewCount: 112,
          isOriginal: false,
          isBestSeller: true,
          variant: 'Include Stand L-125 & Sustain Pedal',
          category: 'Piano',
          code: 'P125B-ID',
          stock: 3,
        ),
        const Product(
          id: 'p3',
          brand: 'BOSS',
          name: 'BOSS Katana 50 MkII Amp Combo',
          price: 4290000,
          image: 'assets/images/fav_boss.png',
          rating: 4.8,
          reviewCount: 64,
          isOriginal: false,
          isBestSeller: false,
          variant: '50-Watt 1x12 Guitar Combo Amplifier',
          category: 'Audio',
          code: 'KTN-50-2',
          stock: 8,
        ),
        const Product(
          id: 'p4',
          brand: 'ROLAND',
          name: 'Roland TD-07KV V-Drums Electronic',
          price: 16500000,
          image: 'assets/images/fav_roland.png',
          rating: 4.9,
          reviewCount: 29,
          isOriginal: false,
          isBestSeller: true,
          variant: 'Electronic Drum Kit Mesh Heads',
          category: 'Drum',
          code: 'TD07KV-PAC',
          stock: 2,
        ),
        const Product(
          id: 'p5',
          brand: 'IBANEZ',
          name: 'Ibanez SR300E 4-String Bass',
          price: 5650000,
          image: 'assets/images/prod_ibanez.png',
          rating: 4.9,
          reviewCount: 55,
          isOriginal: false,
          isBestSeller: true,
          variant: 'PowerSpan Dual Coil Pickups',
          category: 'Bass',
          code: 'SR300E-CUB',
          stock: 6,
        ),
        const Product(
          id: 'p6',
          brand: 'YAMAHA',
          name: 'Yamaha FG800 Folk Acoustic',
          price: 2850000,
          image: 'assets/images/prod_yamaha_acoustic.png',
          rating: 4.9,
          reviewCount: 92,
          isOriginal: true,
          isBestSeller: false,
          variant: 'Solid Spruce Top Natural',
          category: 'Gitar',
          code: 'FG800-NT',
          stock: 10,
        ),
        const Product(
          id: 'p7',
          brand: 'SHURE',
          name: 'Shure SM7B Dynamic Mic',
          price: 6790000,
          image: 'assets/images/prod_shure.png',
          rating: 5.0,
          reviewCount: 94,
          isOriginal: false,
          isBestSeller: true,
          variant: 'Cardioid Studio Vocal Microphone',
          category: 'Audio',
          code: 'SM7B-GLOBAL',
          stock: 12,
        ),
        const Product(
          id: 'p8',
          brand: 'STRUNAL',
          name: 'Strunal Schönbach Student Violin 4/4',
          price: 3950000,
          image: 'assets/images/prod_violin.png',
          rating: 4.7,
          reviewCount: 19,
          isOriginal: false,
          isBestSeller: false,
          variant: 'Solid Carved European Spruce & Maple',
          category: 'Lainnya',
          code: 'STR-220-44',
          stock: 4,
        ),
        const Product(
          id: 'p9',
          brand: 'SELMER',
          name: 'Selmer SA82II Alto Saxophone',
          price: 21500000,
          image: 'assets/images/prod_sax.png',
          rating: 4.9,
          reviewCount: 38,
          isOriginal: true,
          isBestSeller: false,
          variant: 'Super Action 82 Series II Gold Lacquer',
          category: 'Lainnya',
          code: 'SA82II-GL',
          stock: 2,
        ),
        const Product(
          id: 'p10',
          brand: 'ELECTRO-HARMONIX',
          name: 'EHX Big Muff Pi Fuzz Pedal',
          price: 1450000,
          image: 'assets/images/prod_pedal.png',
          rating: 4.8,
          reviewCount: 50,
          isOriginal: false,
          isBestSeller: false,
          variant: 'Classic NYC Original Chassis',
          category: 'Audio',
          code: 'EHX-BMP-USA',
          stock: 15,
        ),
        const Product(
          id: 'p11',
          brand: 'MOGAMI',
          name: 'Mogami Gold Instrument Cable 3m',
          price: 780000,
          image: 'assets/images/prod_cable.png',
          rating: 5.0,
          reviewCount: 41,
          isOriginal: false,
          isBestSeller: false,
          variant: 'Gold-Contact 1/4" Straight Connectors',
          category: 'Audio',
          code: 'MG-GLD-10FT',
          stock: 25,
        ),
        const Product(
          id: 'p12',
          brand: 'ERNIE BALL',
          name: 'Ernie Ball Regular Slinky Strings',
          price: 95000,
          image: 'assets/images/prod_strings.png',
          rating: 4.9,
          reviewCount: 150,
          isOriginal: false,
          isBestSeller: true,
          variant: 'Nickel Wound .010 - .046 Gauge',
          category: 'Gitar',
          code: 'EB-2221',
          stock: 50,
        ),
        // Produk tambahan khusus hasil pencarian "Gitar Fender"
        const Product(
          id: 'p13',
          brand: 'FENDER',
          name: 'Fender American Pro II Telecaster',
          price: 22450000,
          image: 'assets/images/prod_telecaster.png',
          rating: 5.0,
          reviewCount: 32,
          isOriginal: false,
          isBestSeller: true,
          variant: 'Roasted Pine Body, Maple Neck',
          category: 'Gitar',
          code: '0113942705',
          stock: 3,
        ),
        const Product(
          id: 'p14',
          brand: 'SQUIER BY FENDER',
          name: "Squier Classic Vibe '60s Custom Telecaster",
          price: 6890000,
          image: 'assets/images/prod_squier.png',
          rating: 4.8,
          reviewCount: 85,
          isOriginal: true,
          isBestSeller: false,
          variant: 'Nato Body, Laurel Fingerboard',
          category: 'Gitar',
          code: '0374040500',
          stock: 7,
        ),
        const Product(
          id: 'p15',
          brand: 'FENDER ACCESSORIES',
          name: 'Fender Deluxe Molded Electric Guitar Case',
          price: 2350000,
          image: 'assets/images/prod_case.png',
          rating: 4.9,
          reviewCount: 19,
          isOriginal: false,
          isBestSeller: false,
          variant: 'ATA Molded Polyethylene with TSA Lock',
          category: 'Aksesoris',
          code: '0996102306',
          stock: 9,
        ),
      ];
}

/// Model item di dalam keranjang belanja
class CartItem {
  final Product product;
  int quantity;
  bool isSelected;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.isSelected = true,
  });

  int get itemTotal => product.price * quantity;
}
