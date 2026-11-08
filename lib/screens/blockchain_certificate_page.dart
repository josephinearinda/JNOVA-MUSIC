import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/utils/currency_formatter.dart';
import '../models/blockchain_certificate.dart';
import '../widgets/qr_code_widget.dart';

/// Halaman Sertifikat Keaslian Digital Blockchain (NFT ERC-721 On-Chain Pass)
/// Menampilkan bukti kepemilikan dan audit originalitas instrumen musik resmi JNOVAMUSIC
/// Mengadopsi palet warna putih dan orange bersih yang selaras dengan halaman Beranda.
class BlockchainCertificatePage extends StatelessWidget {
  final BlockchainCertificate certificate;
  final bool isPreview;

  const BlockchainCertificatePage({
    super.key,
    required this.certificate,
    this.isPreview = false,
  });

  // Palet Warna Resmi JNOVAMUSIC (White & Orange Theme)
  static const Color _bgPrimary = Color(0xFFFFFFFF);
  static const Color _bgCard = Color(0xFFFFFFFF);
  static const Color _bgSection = Color(0xFFF8F8F8);
  static const Color _primaryOrange = Color(0xFFFF6B00);
  static const Color _orangeLight = Color(0xFFFFF2EB);
  static const Color _orangeBorder = Color(0xFFFFD1B3);
  static const Color _textPrimary = Color(0xFF222222);
  static const Color _textSecondary = Color(0xFF777777);
  static const Color _borderLight = Color(0xFFEAEAEA);
  static const Color _verifiedGreen = Color(0xFF059669);
  static const Color _verifiedGreenBg = Color(0xFFECFDF5);
  static const Color _verifiedGreenBorder = Color(0xFFA7F3D0);

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke clipboard!'),
        backgroundColor: const Color(0xFF222222),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _openPolygonScan(BuildContext context) async {
    final uri = Uri.tryParse(certificate.explorerUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'polygonscan.com' ||
        !uri.path.startsWith('/address/')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tautan PolygonScan sertifikat tidak valid.'),
          backgroundColor: Color(0xFF222222),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PolygonScan tidak dapat dibuka.'),
            backgroundColor: Color(0xFF222222),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on PlatformException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PolygonScan tidak dapat dibuka.'),
            backgroundColor: Color(0xFF222222),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showVerificationSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _borderLight, width: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: _verifiedGreen, size: 24),
            SizedBox(width: 8),
            Text(
              'Audit On-Chain Lolos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Instrumen ini terverifikasi 100% ASLI di jaringan Polygon PoS dan tercatat permanen di smart contract resmi.',
              style: TextStyle(
                fontSize: 12,
                color: _textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bgSection,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderLight),
              ),
              child: Column(
                children: [
                  _buildAuditRow(
                    'Status',
                    'Success (12 Confirmations)',
                    _verifiedGreen,
                  ),
                  const Divider(color: _borderLight, height: 14),
                  _buildAuditRow('Block Height', '#58,491,204', _textPrimary),
                  const Divider(color: _borderLight, height: 14),
                  _buildAuditRow(
                    'Serial Number',
                    certificate.serialNumber,
                    _primaryOrange,
                  ),
                  const Divider(color: _borderLight, height: 14),
                  _buildAuditRow(
                    'Token ID',
                    certificate.tokenId,
                    _primaryOrange,
                  ),
                  const Divider(color: _borderLight, height: 14),
                  _buildAuditRow(
                    'Gas Fee',
                    '0.0038 POL (~Rp 45)',
                    _textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Tutup',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildAuditRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: _textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: valueColor,
            fontFamily: label == 'Serial Number' || label == 'Token ID'
                ? 'monospace'
                : null,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute WIB';
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatDateTime(certificate.mintDate);
    final isPreviewMode = isPreview || !certificate.isClaimed;

    return Scaffold(
      backgroundColor: _bgPrimary,
      appBar: AppBar(
        backgroundColor: _bgPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _textPrimary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPreviewMode
                  ? 'Pratinjau Sertifikat Digital'
                  : 'Sertifikat Keaslian NFT',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
              ),
            ),
            Text(
              isPreviewMode
                  ? 'Polygon PoS • ERC-721 Showroom Preview'
                  : 'Polygon PoS • ERC-721 Verified',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: _primaryOrange,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Salin Ringkasan Sertifikat',
            icon: const Icon(
              Icons.share_outlined,
              color: _textPrimary,
              size: 20,
            ),
            onPressed: () {
              _copyToClipboard(
                context,
                'Sertifikat Keaslian Instrumen ${certificate.product.name}\nSerial: ${certificate.serialNumber}\nToken: ${certificate.tokenId}\nExplorer: ${certificate.explorerUrl}',
                'Ringkasan Sertifikat',
              );
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1.0, color: _borderLight),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Keterangan Jika Berada di Mode Pratinjau
            if (isPreviewMode) ...[
              _buildPreviewNoticeBanner(),
              const SizedBox(height: 14),
            ],

            // 1. KARTU MEWAH SERTIFIKAT (TEMA PUTIH & ORANGE)
            _buildLuxuryNftCard(context, formattedDate, isPreviewMode),

            const SizedBox(height: 18),

            // 2. TOMBOL AKSI CEPAT (Verifikasi Keaslian & Salin Data)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () => _showVerificationSuccessDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.verified_rounded, size: 16),
                    label: const Text(
                      'Verifikasi Keaslian',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _copyToClipboard(
                        context,
                        'Sertifikat Keaslian Instrumen ${certificate.product.name}\nSerial: ${certificate.serialNumber}\nToken ID: ${certificate.tokenId}\nJaringan: ${certificate.network}\nStatus: Terverifikasi Asli (JNOVA)',
                        'Detail Sertifikat',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _primaryOrange,
                      side: const BorderSide(
                        color: _primaryOrange,
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(
                      Icons.copy_rounded,
                      size: 15,
                      color: _primaryOrange,
                    ),
                    label: const Text(
                      'Salin Data',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 3. TABEL DETAIL ON-CHAIN (LEDGER DATA TEMA PUTIH & ORANGE)
            _buildOnChainLedgerSection(context, formattedDate),

            const SizedBox(height: 12),

            // Tombol PolygonScan (Desain Putih dengan Border Orange)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openPolygonScan(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _primaryOrange,
                  side: const BorderSide(color: _primaryOrange, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: _primaryOrange,
                ),
                label: const Text(
                  'Buka Alamat Kontrak di PolygonScan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 4. HASIL INSPEKSI LUTHIER JNOVA
            _buildLuthierInspectionCard(),

            const SizedBox(height: 18),

            // 5. QR CODE VERIFIKASI FISIK & LABEL TAG
            _buildPhysicalVerificationQr(context),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Banner informasi pratinjau sertifikat digital
  Widget _buildPreviewNoticeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _orangeLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _orangeBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.workspace_premium_rounded, color: _primaryOrange, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pratinjau Sertifikat Resmi JNOVAMUSIC',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF944508),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Sertifikat digital NFT ERC-721 ini akan di-minting secara resmi di blockchain Polygon dan diterbitkan atas nama Anda saat instrumen ini telah selesai diproses.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF7A3906),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu Sertifikat Mewah (Tema Putih & Orange)
  Widget _buildLuxuryNftCard(
    BuildContext context,
    String formattedDate,
    bool isPreviewMode,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF8A3D),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryOrange.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Atas: Logo Jnova, Token ID, & Tag Status Kepemilikan
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo JNOVAMUSIC
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryOrange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'JNOVAMUSIC',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Badge Token ID
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: _orangeLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _orangeBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.token_rounded,
                            size: 11,
                            color: _primaryOrange,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            certificate.tokenId,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: _primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                // Badge Status Kepemilikan (Warna Orange Muda)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: _orangeLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _orangeBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          certificate.isClaimed
                              ? Icons.verified_user_rounded
                              : (isPreviewMode
                                  ? Icons.visibility_rounded
                                  : Icons.storefront_rounded),
                          size: 12,
                          color: _primaryOrange,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            isPreviewMode
                                ? 'PRATINJAU SERTIFIKAT'
                                : (certificate.isClaimed
                                    ? 'MILIK PEMBELI'
                                    : 'STOK SHOWROOM'),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: _primaryOrange,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: _borderLight, height: 1),

          // Foto Produk Proporsional & Info Utama
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wadah Foto Produk Bersih dengan Background Putih
                Container(
                  width: 90,
                  height: 90,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _borderLight,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildProductImage(certificate.product.image),
                  ),
                ),
                const SizedBox(width: 14),

                // Info Produk yang Jelas & Terbaca
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        certificate.product.brand.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: _primaryOrange,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        certificate.product.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatCurrency(certificate.product.price),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _primaryOrange,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: _bgSection,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: _borderLight),
                        ),
                        child: Text(
                          'Kategori: ${certificate.product.category}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Section Rapi: Nomor Seri Resmi & Pemilik Terdaftar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            decoration: BoxDecoration(
              color: _bgSection,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderLight, width: 1),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Nomor Seri Resmi:',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              certificate.serialNumber,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                                fontFamily: 'monospace',
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _copyToClipboard(
                              context,
                              certificate.serialNumber,
                              'Nomor Seri',
                            ),
                            child: const Icon(
                              Icons.copy_rounded,
                              size: 13,
                              color: _primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: _borderLight, height: 16),
                Row(
                  children: [
                    const Text(
                      'Pemilik Terdaftar:',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        certificate.ownerName,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                          fontStyle: certificate.isClaimed
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
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
      size: 40,
      color: _primaryOrange,
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

  /// Bagian Data Buku Besar On-Chain (Card Putih & Bersih)
  Widget _buildOnChainLedgerSection(
    BuildContext context,
    String formattedDate,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _orangeLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _orangeBorder, width: 0.8),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  size: 16,
                  color: _primaryOrange,
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi On-Chain Blockchain',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                  Text(
                    'Tercatat permanen dan tidak dapat dipalsukan',
                    style: TextStyle(fontSize: 10, color: _textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: _borderLight, height: 1),
          const SizedBox(height: 14),

          _buildLedgerRow(
            context: context,
            label: 'Jaringan Blockchain',
            value: certificate.network,
            icon: Icons.hub_outlined,
          ),
          _buildLedgerRow(
            context: context,
            label: 'Pemilik Sah (Owner)',
            value: certificate.ownerName,
            icon: Icons.person_pin_rounded,
          ),
          _buildLedgerRow(
            context: context,
            label: 'Dompet Pemilik',
            value: certificate.ownerWalletAddress,
            isMonospace: true,
            copyable: certificate.isClaimed,
            icon: Icons.account_balance_wallet_outlined,
          ),
          _buildLedgerRow(
            context: context,
            label: 'Standar Token',
            value: certificate.tokenStandard,
            icon: Icons.verified_user_outlined,
          ),
          _buildLedgerRow(
            context: context,
            label: 'Smart Contract',
            value: certificate.smartContractAddress,
            isMonospace: true,
            copyable: true,
            icon: Icons.code_rounded,
          ),
          _buildLedgerRow(
            context: context,
            label: 'Token ID',
            value: certificate.tokenId,
            copyable: true,
            icon: Icons.tag_rounded,
          ),
          _buildLedgerRow(
            context: context,
            label: 'Transaction Hash (Tx)',
            value: certificate.txHash,
            isMonospace: true,
            copyable: true,
            icon: Icons.receipt_long_rounded,
          ),
          _buildLedgerRow(
            context: context,
            label: 'Penyimpanan Metadata',
            value: certificate.ipfsMetadataUri,
            isMonospace: true,
            copyable: true,
            icon: Icons.cloud_done_outlined,
          ),
          _buildLedgerRow(
            context: context,
            label: 'Waktu Minting',
            value: formattedDate,
            icon: Icons.access_time_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerRow({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    bool isMonospace = false,
    bool copyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: _primaryOrange),
          const SizedBox(width: 8),
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: _textSecondary),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: isMonospace ? 'monospace' : null,
                      color: _textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (copyable) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _copyToClipboard(context, value, label),
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 13,
                      color: _primaryOrange,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hasil Inspeksi Master Luthier
  Widget _buildLuthierInspectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.build_circle_outlined,
                size: 16,
                color: _primaryOrange,
              ),
              SizedBox(width: 8),
              Text(
                'Laporan Audit & Kalibrasi Luthier',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Auditor: ${certificate.inspectorName}',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: _primaryOrange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            certificate.inspectionNotes,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF555555),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: _verifiedGreenBg,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: _verifiedGreenBorder, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 13,
                  color: _verifiedGreen,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    certificate.acousticSignature,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _verifiedGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// QR Code Verifikasi Fisik
  Widget _buildPhysicalVerificationQr(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'QR Code Verifikasi Fisik & Label Tag',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pindai QR ini saat unboxing di showroom JNOVA atau saat jual kembali untuk memverifikasi keaslian instrumen.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: _textSecondary, height: 1.35),
          ),
          const SizedBox(height: 16),

          // QR Code Widget dengan Frame Orange Rapi
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primaryOrange, width: 1.8),
            ),
            child: QrCodeWidget(
              data: certificate.qrVerificationData,
              size: 160,
            ),
          ),

          const SizedBox(height: 12),
          Text(
            'ID Sertifikat: ${certificate.id}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _primaryOrange,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
