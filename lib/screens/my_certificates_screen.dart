import 'package:flutter/material.dart';

import '../core/utils/currency_formatter.dart';
import '../models/blockchain_certificate.dart';
import '../services/blockchain_certificate_service.dart';
import 'blockchain_certificate_page.dart';

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
      _certificates =
          BlockchainCertificateService.instance.getUserCertificates();
    });
  }

  List<BlockchainCertificate> get _filteredCertificates {
    final query = _searchController.text.trim().toLowerCase();
    return _certificates.where((cert) {
      final matchesCategory = _selectedCategory == 'Semua' ||
          (_selectedCategory == 'Milik Saya'
              ? cert.isClaimed
              : cert.product.category.toLowerCase() == _selectedCategory.toLowerCase());
      final matchesQuery = query.isEmpty ||
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFFFF5500), size: 22),
            SizedBox(width: 8),
            Text(
              'Verifikasi Serial Number',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E1E1E),
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
              style: TextStyle(fontSize: 11.5, color: Color(0xFF6B6560)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: verifyController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Contoh: SN-FENDER-014051-88421',
                hintStyle: const TextStyle(fontSize: 11, color: Color(0xFFAAA39D)),
                filled: true,
                fillColor: const Color(0xFFF7F6F3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2DFD8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2DFD8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFFF5500)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: [
                ActionChip(
                  label: const Text('Coba Serial Demo', style: TextStyle(fontSize: 9.5)),
                  backgroundColor: const Color(0xFFFFF0E6),
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
            child: const Text('Batal', style: TextStyle(color: Color(0xFF7E756F))),
          ),
          ElevatedButton(
            onPressed: () {
              final query = verifyController.text.trim();
              Navigator.pop(ctx);
              _handleVerifyResult(query);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5500),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Validasi On-Chain',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _handleVerifyResult(String query) {
    final cert = BlockchainCertificateService.instance.verifySerialNumber(query);
    if (cert != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlockchainCertificatePage(certificate: cert),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 24),
              SizedBox(width: 8),
              Text(
                'Tidak Terdaftar',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: Text(
            'Nomor seri "$query" tidak ditemukan pada buku besar blockchain JNOVA. Harap pastikan instrumen dibeli dari toko resmi JNOVAMUSIC.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF5A524D)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup', style: TextStyle(color: Color(0xFFFF5500))),
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
      backgroundColor: const Color(0xFFF9F8F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E1E1E)),
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
                color: Color(0xFF1E1E1E),
              ),
            ),
            Text(
              'Portofolio instrumen original terverifikasi',
              style: TextStyle(fontSize: 10, color: Color(0xFF7E756F)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Validasi Serial Number',
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFFF5500)),
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
              gradient: LinearGradient(
                colors: [Color(0xFF1D172E), Color(0xFF13101C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8247E5).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF9E86FF), width: 0.8),
                  ),
                  child: const Icon(Icons.security_rounded, size: 20, color: Color(0xFFD6C7FF)),
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
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Daftar sertifikat keaslian dan kepemilikan digital resmi instrumen musik Anda di blockchain Polygon.',
                        style: TextStyle(fontSize: 9.5, color: Color(0xFFBFB5D1), height: 1.3),
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
                hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFFA09891)),
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF8E837D)),
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
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEBE7DF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEBE7DF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF5500)),
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
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF4A423D),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFFFF5500),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFFF5500) : const Color(0xFFE5E0D8),
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
                          color: Color(0xFFC7BFB8),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada sertifikat yang cocok',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5A524D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Coba ganti filter kategori atau kata kunci pencarian.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF8E837D)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE9E3), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              color: Color(0xFF1E1A29),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.token_rounded, size: 12, color: Color(0xFF9E86FF)),
                    const SizedBox(width: 4),
                    Text(
                      'TOKEN ${cert.tokenId}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD6C7FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cert.isClaimed
                          ? const Color(0xFF0F3B2E)
                          : const Color(0xFF382310),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      cert.isClaimed ? 'TERVERIFIKASI' : 'STOK SHOWROOM',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: cert.isClaimed
                            ? const Color(0xFF34D399)
                            : const Color(0xFFFFB057),
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
                    color: const Color(0xFFFAF9F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEBE8E3)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: cert.product.image.startsWith('assets/')
                        ? Image.asset(
                            cert.product.image,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.music_note_rounded,
                              color: Color(0xFFFF5500),
                            ),
                          )
                        : Image.network(
                            cert.product.image,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.music_note_rounded,
                              color: Color(0xFFFF5500),
                            ),
                          ),
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
                          color: Color(0xFFFF5500),
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
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCurrency(cert.product.price),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4A423D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Serial: ${cert.serialNumber}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B6560),
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
                              ? const Color(0xFF059669)
                              : const Color(0xFFB45309),
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

          const Divider(height: 1, color: Color(0xFFF0ECE6)),

          // Tombol Buka Sertifikat
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlockchainCertificatePage(certificate: cert),
                ),
              );
            },
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFFFF5500)),
                  SizedBox(width: 6),
                  Text(
                    'Lihat Sertifikat Keaslian Digital',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF5500),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFFFF5500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
