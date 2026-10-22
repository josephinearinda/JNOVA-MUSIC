import 'product.dart';

/// Model data Sertifikat Keaslian Digital Blockchain (NFT / On-chain Certificate)
/// Khusus untuk instrumen musik kategori utama dengan harga > Rp 6.000.000
class BlockchainCertificate {
  final String id;
  final Product product;
  final String serialNumber;
  final String ownerName;
  final String ownerWalletAddress;
  final String smartContractAddress;
  final String tokenId;
  final String tokenStandard;
  final String network;
  final DateTime mintDate;
  final String txHash;
  final String ipfsMetadataUri;
  final String explorerUrl;
  final String inspectorName;
  final String inspectionNotes;
  final String acousticSignature;
  final String orderNumber;

  const BlockchainCertificate({
    required this.id,
    required this.product,
    required this.serialNumber,
    required this.ownerName,
    required this.ownerWalletAddress,
    required this.smartContractAddress,
    required this.tokenId,
    this.tokenStandard = 'ERC-721 (Non-Fungible Token)',
    this.network = 'Polygon PoS (Matic Network)',
    required this.mintDate,
    required this.txHash,
    required this.ipfsMetadataUri,
    required this.explorerUrl,
    this.inspectorName = 'Josephine Arinda, Master Luthier',
    this.inspectionNotes =
        'Telah lolos inspeksi 18 titik showroom JNOVA: kayu resonant grade A, intonasi frekuensi 440Hz akurat, hardware original terverifikasi.',
    this.acousticSignature = 'Acoustic Tone Signature: Pure Resonance 98.6%',
    this.orderNumber = 'ORD-JNV-2024-8841',
  });

  /// Cek apakah instrumen sudah dibeli/diklaim oleh pengguna
  bool get isClaimed =>
      ownerName != 'Belum Terdaftar (Tersedia di Showroom)' &&
      ownerName != 'Tersedia di Showroom';

  /// Factory untuk membuat sertifikat deterministik yang realistis berdasarkan produk
  factory BlockchainCertificate.forProduct({
    required Product product,
    String? ownerName,
    String? orderNumber,
    DateTime? date,
  }) {
    final seed = product.name.hashCode.abs();
    final pCode = product.code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final cleanCode = pCode.isNotEmpty
        ? (pCode.length > 6 ? pCode.substring(0, 6).toUpperCase() : pCode.toUpperCase())
        : 'JNV';
    final hexSeed = seed.toRadixString(16).padLeft(8, '0');

    final isPurchased = ownerName != null &&
        ownerName.trim().isNotEmpty &&
        ownerName != 'Belum Terdaftar (Tersedia di Showroom)';
    final actualOwner =
        isPurchased ? ownerName : 'Belum Terdaftar (Tersedia di Showroom)';
    final actualOrder = isPurchased
        ? (orderNumber ?? 'ORD-JNV-${(seed % 9000) + 1000}')
        : 'Stok Showroom JNOVA (Belum Terjual)';
    final actualWallet = isPurchased
        ? '0x71c8...${hexSeed.substring(0, 4)}'
        : '0x0000...0000 (JNOVA Genesis Vault)';
    final actualDate = date ?? DateTime.now().subtract(const Duration(days: 2));

    final serialNumber = 'SN-${product.brand.toUpperCase().replaceAll(' ', '')}-$cleanCode-${(seed % 89999) + 10000}';
    final tokenId = '#${(seed % 900000) + 100000}';
    final contract = '0x2953399124F0cBB46d2CbACD8A89cF0599974963'; // Official Polygon NFT Contract (Verified)

    // Generate valid 64-hex-char hash (total 66 chars with 0x prefix)
    final hex64 = _generateHex64('${product.name}_${product.id}_$seed');
    final txHash = '0x$hex64';
    final ipfsHash = 'ipfs://bafybei${hexSeed}m7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi';

    return BlockchainCertificate(
      id: 'CERT-JNV-${(seed % 90000) + 10000}',
      product: product,
      serialNumber: serialNumber,
      ownerName: actualOwner,
      ownerWalletAddress: actualWallet,
      smartContractAddress: contract,
      tokenId: tokenId,
      tokenStandard: 'ERC-721 (Non-Fungible Token)',
      network: 'Polygon PoS (Matic Network)',
      mintDate: actualDate,
      txHash: txHash,
      ipfsMetadataUri: ipfsHash,
      explorerUrl: 'https://polygonscan.com/address/$contract',
      inspectorName: 'Josephine Arinda (Head Luthier JNOVA)',
      inspectionNotes:
          'Pemeriksaan fisik & elektronik 18 titik JNOVA: Serial number bodi & neck cocok, kelistrikan pickup stabil, fret leveling presisi tanpa buzz.',
      acousticSignature: 'Acoustic Tone Signature: Resonance Balanced Grade A+',
      orderNumber: actualOrder,
    );
  }

  /// Menghasilkan 64 karakter heksadesimal deterministik (sesuai standar 32-byte hash EVM)
  static String _generateHex64(String input) {
    final buffer = StringBuffer();
    var h = input.hashCode.abs();
    for (int i = 0; i < 8; i++) {
      h = (h * 1664525 + 1013904223 + (i * 31)) & 0xFFFFFFFF;
      buffer.write(h.toRadixString(16).padLeft(8, '0'));
    }
    return buffer.toString().substring(0, 64);
  }

  /// Data payload teks untuk QR code verifikasi
  String get qrVerificationData =>
      'JNOVA_BLOCKCHAIN_VERIFY|CERT:$id|SN:$serialNumber|TOKEN:$tokenId|NET:POLYGON|TX:$txHash';
}
