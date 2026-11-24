import 'package:flutter/material.dart';

import 'package:jnova/core/utils/currency_formatter.dart';
import 'package:jnova/models/blockchain_certificate.dart';
import 'package:jnova/services/blockchain_certificate_service.dart';
import 'package:jnova/screens/certificate/certificate_detail_screen.dart';

/// Halaman Daftar Sertifikat Keaslian Instrumen Musik (NFT Pass Portofolio)
class MyCertificatesScreen extends StatefulWidget {
  const MyCertificatesScreen({super.key});

  @override
  State<MyCertificatesScreen> createState() => _MyCertificatesScreenState();
}

class _MyCertificatesScreenState extends State<MyCertificatesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  List<BlockchainCertificate> _certificates = [];

  final List<String> _categories = [
    'Semua',
    'Milik Saya',
    'Gitar',
    'Bass',
    'Drum',
    'Piano',
    'Biola',
    'Saxophone',
  ];

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCertificates() {
    setState(() {
      _certificates = BlockchainCertificateService.instance
          .getUserCertificates();
    });
  }

  List<BlockchainCertificate> get _filteredCertificates {
    final query = _searchController.text.trim().toLowerCase();
    return _certificates.where((cert) {
      final matchesCategory =
          _selectedCategory == 'Semua' ||
          (_selectedCategory == 'Milik Saya'
              ? cert.isClaimed
              : cert.product.category.toLowerCase() ==
                    _selectedCategory.toLowerCase());
      final matchesQuery =
          query.isEmpty ||
          cert.product.name.toLowerCase().contains(query) ||
          cert.product.brand.toLowerCase().contains(query) ||
          cert.serialNumber.toLowerCase().contains(query) ||
          cert.tokenId.toLowerCase().contains(query) ||
          cert.ownerName.toLowerCase().contains(query) ||
          cert.id.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _openVerifyDialog() {
    final verifyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            Colors.white, // Warna ikon ikon untuk "Verifikasi Serial Number"
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.shield_outlined,
              color: Color(
                0xFFFF5500,
              ), // Warna ikon ikon untuk "Verifikasi Serial Number"
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'Verifikasi Serial Number',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(
                  0xFF1E1E1E,
                ), // Warna teks pada "Verifikasi Serial Number"
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan nomor seri fisik instrumen atau Token ID untuk memvalidasi keaslian di blockchain JNOVA:',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(
                  0xFF6B6560,
                ), // Warna teks pada "Contoh: SN-FENDER-014051-88421"
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: verifyController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Contoh: SN-FENDER-014051-88421',
                hintStyle: const TextStyle(
                  fontSize: 11,
                  color: Color(
                    0xFFAAA39D,
                  ), // Warna teks pada "Contoh: SN-FENDER-014051-88421"
                ),
                filled: true,
                fillColor: const Color(
                  0xFFF7F6F3,
                ), // Warna latar field input pada bagian komponen ini
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2DFD8), // Warna border atau garis tepi untuk "Contoh: SN-FENDER-014051-88421"
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2DFD8), // Warna border atau garis tepi untuk "Contoh: SN-FENDER-014051-88421"
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF5500), // Warna border atau garis tepi untuk "Contoh: SN-FENDER-014051-88421"
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: [
                ActionChip(
                  label: const Text(
                    'Coba Serial Demo',
                    style: TextStyle(fontSize: 9.5),
                  ),
                  backgroundColor: const Color(
                    0xFFFFF0E6,
                  ), // Warna teks pada "Coba Serial Demo"
                  onPressed: () {
                    if (_certificates.isNotEmpty) {
                      verifyController.text = _certificates.first.serialNumber;
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: Color(0xFF7E756F), // Warna teks pada "Batal"
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final query = verifyController.text.trim();
              Navigator.pop(ctx);
              _handleVerifyResult(query);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(
                0xFFFF5500,
              ), // Warna latar tombol pada bagian komponen ini
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Validasi On-Chain',
              style: TextStyle(
                color: Colors.white, // Warna teks pada "Validasi On-Chain"
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleVerifyResult(String query) {
    final cert = BlockchainCertificateService.instance.verifySerialNumber(
      query,
    );
    if (cert != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlockchainCertificatePage(
            certificate: cert,
            isPreview: !cert.isClaimed,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor:
              Colors.white, // Warna ikon ikon untuk "Tidak Terdaftar"
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.cancel_rounded,
                color: Color(
                  0xFFDC2626,
                ), // Warna ikon ikon untuk "Tidak Terdaftar"
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Tidak Terdaftar',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: Text(
            'Nomor seri "$query" tidak ditemukan pada buku besar blockchain JNOVA. Harap pastikan instrumen dibeli dari toko resmi JNOVAMUSIC.',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5A524D), // Warna teks pada "Nomor seri"
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Tutup',
                style: TextStyle(
                  color: Color(0xFFFF5500), // Warna teks pada "Tutup"
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCertificates;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF9F8F6,
      ), // Warna latar kotak atau kartu pada bagian komponen ini
      appBar: AppBar(
        backgroundColor:
            Colors.white, // Warna ikon ikon pada bagian komponen ini
        elevation: 0,
        surfaceTintColor:
            Colors.transparent, // Warna ikon ikon untuk "Sertifikat Blockchain"
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(
              0xFF1E1E1E,
            ), // Warna ikon ikon untuk "Sertifikat Blockchain"
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sertifikat Blockchain',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(
                  0xFF1E1E1E,
                ), // Warna teks pada "Sertifikat Blockchain"
              ),
            ),
            Text(
              'Portofolio instrumen original terverifikasi',
              style: TextStyle(
                fontSize: 10,
                color: Color(
                  0xFF7E756F,
                ), // Warna teks pada "Portofolio instrumen original terve..."
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Validasi Serial Number',
            icon: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Color(
                0xFFFF5500,
              ), // Warna ikon ikon untuk "Validasi Serial Number"
            ),
            onPressed: _openVerifyDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Edukasi Kebijakan Sertifikat
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(
                0xFFFFF7F2,
              ), // Warna border atau garis tepi untuk "Validasi Serial Number"
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFFFD1B3), // Warna border atau garis tepi untuk "Validasi Serial Number"
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2EB), // Warna border atau garis tepi untuk "Validasi Serial Number"
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(
                        0xFFFFD1B3,
                      ), // Warna ikon ikon untuk "Validasi Serial Number"
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    size: 20,
                    color: Color(
                      0xFFFF6B00,
                    ), // Warna ikon ikon untuk "Validasi Serial Number"
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jaminan Keaslian On-Chain JNOVA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF944508), // Warna teks pada "Jaminan Keaslian On-Chain JNOVA"
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Daftar sertifikat keaslian dan kepemilikan digital resmi instrumen musik Anda di blockchain Polygon.',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF7A3906), // Warna teks pada "Jaminan Keaslian On-Chain JNOVA"
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari merek, tipe, nomor seri, atau Token ID...',
                hintStyle: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFFA09891), // Warna ikon ikon untuk "Cari merek, tipe, nomor seri, atau..."
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: Color(0xFF8E837D), // Warna ikon ikon untuk "Cari merek, tipe, nomor seri, atau..."
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors
                    .white, // Warna latar field input pada bagian komponen ini
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(
                      0xFFEBE7DF,
                    ), // Warna border atau garis tepi bagian komponen ini
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(
                      0xFFEBE7DF,
                    ), // Warna border atau garis tepi bagian komponen ini
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(
                      0xFFFF5500,
                    ), // Warna border atau garis tepi bagian komponen ini
                  ),
                ),
              ),
            ),
          ),

          // Filter Kategori Horizontal
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? Colors
                                  .white // Warna teks pada bagian komponen ini
                            : const Color(
                                0xFF4A423D,
                              ), // Warna visual pada bagian komponen ini
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    backgroundColor: Colors.white, // Warna latar kotak atau kartu pada bagian komponen ini
                    selectedColor: const Color(
                      0xFFFF5500,
                    ), // Warna visual pada bagian komponen ini
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFFFF5500) // Warna border atau garis tepi bagian komponen ini
                            : const Color(0xFFE5E0D8), // Warna border atau garis tepi bagian komponen ini
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Daftar Kartu Sertifikat
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          size: 48,
                          color: Color(0xFFC7BFB8), // Warna ikon ikon untuk "Tidak ada sertifikat yang cocok"
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada sertifikat yang cocok',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5A524D), // Warna teks pada "Tidak ada sertifikat yang cocok"
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Coba ganti filter kategori atau kata kunci pencarian.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8E837D), // Warna teks pada "Coba ganti filter kategori atau kat..."
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final cert = filtered[index];
                      return _buildCertificateItemCard(context, cert);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateItemCard(
    BuildContext context,
    BlockchainCertificate cert,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, // Warna border atau garis tepi kartu
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEDE9E3), // Warna border atau garis tepi kartu
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              // Warna border atau garis tepi kartu

              alpha: 0.03,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar Kartu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF9F5), // Warna border atau garis tepi kartu
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(
                bottom: BorderSide(
                  color: Color(
                    0xFFFFE0CC,
                  ), // Warna border atau garis tepi kartu
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.token_rounded,
                      size: 13,
                      color: Color(
                        0xFFFF6B00,
                      ), // Warna ikon ikon untuk "TOKEN ${cert.tokenId}"
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'TOKEN ${cert.tokenId}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(
                          0xFFFF6B00,
                        ), // Warna teks pada "TOKEN ${cert.tokenId}"
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: cert.isClaimed
                          ? const Color(0xFFECFDF5) // Warna latar kotak atau kartu untuk "TOKEN ${cert.tokenId}"
                          : const Color(0xFFFFF2EB), // Warna border atau garis tepi untuk "TOKEN ${cert.tokenId}"
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: cert.isClaimed
                            ? const Color(0xFFA7F3D0) // Warna border atau garis tepi untuk "TOKEN ${cert.tokenId}"
                            : const Color(0xFFFFD1B3), // Warna border atau garis tepi untuk "TOKEN ${cert.tokenId}"
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      cert.isClaimed ? 'TERVERIFIKASI' : 'STOK SHOWROOM',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: cert.isClaimed
                            ? const Color(
                                0xFF059669,
                              ) // Warna teks pada "TERVERIFIKASI"
                            : const Color(
                                0xFFFF6B00,
                              ), // Warna visual pada kartu
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Konten Produk
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFAF9F7,
                    ), // Warna border atau garis tepi kartu
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(
                        0xFFEBE8E3,
                      ), // Warna border atau garis tepi kartu
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: _buildProductImage(cert.product.image),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert.product.brand.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFF5500), // Warna teks pada kartu
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cert.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E1E1E), // Warna teks pada kartu
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCurrency(cert.product.price),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(
                            0xFF4A423D,
                          ), // Warna teks pada "Serial: ${cert.serialNumber}"
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Serial: ${cert.serialNumber}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(
                            0xFF6B6560,
                          ), // Warna teks pada "monospace"
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pemilik: ${cert.ownerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: cert.isClaimed
                              ? const Color(0xFF059669) // Warna teks pada "Pemilik: ${cert.ownerName}"
                              : const Color(0xFFB45309), // Warna teks pada "Pemilik: ${cert.ownerName}"
                          fontStyle: cert.isClaimed
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
            color: Color(0xFFF0ECE6), // Warna garis pemisah pada kartu
          ),
          // Tombol Buka Sertifikat
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlockchainCertificatePage(
                    certificate: cert,
                    isPreview: !cert.isClaimed,
                  ),
                ),
              );
            },
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(15),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    size: 14,
                    color: Color(0xFFFF5500), // Warna ikon ikon untuk "Lihat Sertifikat Keaslian Digital"
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Lihat Sertifikat Keaslian Digital',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF5500), // Warna ikon ikon untuk "Lihat Sertifikat Keaslian Digital"
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: Color(0xFFFF5500), // Warna ikon ikon untuk "Lihat Sertifikat Keaslian Digital"
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imagePath) {
    final isNetworkImage =
        imagePath.startsWith('https://') || imagePath.startsWith('http://');
    const fallback = Icon(
      Icons.music_note_rounded,
      color: Color(0xFFFF5500), // Warna ikon ikon untuk "https://"
    );

    return isNetworkImage
        ? Image.network(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => fallback,
          )
        : Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => fallback,
          );
  }
}

typedef CertificateListScreen = MyCertificatesScreen;
