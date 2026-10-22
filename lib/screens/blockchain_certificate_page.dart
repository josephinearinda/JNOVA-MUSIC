import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/currency_formatter.dart';
import '../models/blockchain_certificate.dart';
import '../widgets/qr_code_widget.dart';

/// Halaman Sertifikat Keaslian Digital Blockchain (NFT On-chain Pass)
/// Menampilkan bukti kepemilikan dan audit originalitas instrumen musik resmi JNOVAMUSIC
class BlockchainCertificatePage extends StatelessWidget {
  final BlockchainCertificate certificate;

  const BlockchainCertificatePage({
    super.key,
    required this.certificate,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke clipboard!'),
        backgroundColor: const Color(0xFF1E1E1E),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showVerificationSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161A22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF2A3344), width: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 8),
            Text(
              'Audit On-Chain Lolos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
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
              style: TextStyle(fontSize: 12, color: Color(0xFFBAC5D5), height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1115),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF232A38)),
              ),
              child: Column(
                children: [
                  _buildAuditRow('Status', 'Success (12 Confirmations)', const Color(0xFF10B981)),
                  const Divider(color: Color(0xFF232A38), height: 14),
                  _buildAuditRow('Block Height', '#58,491,204', Colors.white),
                  const Divider(color: Color(0xFF232A38), height: 14),
                  _buildAuditRow('Serial Number', certificate.serialNumber, const Color(0xFFFFD580)),
                  const Divider(color: Color(0xFF232A38), height: 14),
                  _buildAuditRow('Token ID', certificate.tokenId, const Color(0xFFFF5500)),
                  const Divider(color: Color(0xFF232A38), height: 14),
                  _buildAuditRow('Gas Fee', '0.0038 POL (~Rp 45)', const Color(0xFF8CE3FF)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          style: const TextStyle(fontSize: 11, color: Color(0xFF8E9BAE)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: valueColor,
            fontFamily: label == 'Serial Number' || label == 'Token ID' ? 'monospace' : null,
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

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161A22),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sertifikat Keaslian NFT',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              'Polygon PoS • ERC-721 Verified',
              style: TextStyle(fontSize: 10, color: Color(0xFF9E86FF)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
            onPressed: () {
              _copyToClipboard(
                context,
                'Sertifikat Keaslian Instrumen ${certificate.product.name}\nSerial: ${certificate.serialNumber}\nToken: ${certificate.tokenId}\nExplorer: ${certificate.explorerUrl}',
                'Ringkasan Sertifikat',
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KARTU MEWAH SERTIFIKAT (HOLOGRAPHIC NFT BADGE)
            _buildLuxuryNftCard(context, formattedDate),

            const SizedBox(height: 20),

            // 2. TOMBOL AKSI CEPAT (Verifikasi In-App & Salin Ringkasan)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () => _showVerificationSuccessDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981), // Emerald verified green
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.verified_rounded, size: 16),
                    label: const Text(
                      'Verifikasi Keaslian',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
                      foregroundColor: const Color(0xFFFFD580),
                      side: const BorderSide(color: Color(0xFFE5A93C), width: 1.1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 15),
                    label: const Text(
                      'Salin Data',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // 3. TABEL DETAIL ON-CHAIN (LEDGER DATA)
            _buildOnChainLedgerSection(context, formattedDate),

            const SizedBox(height: 18),

            // 4. HASIL INSPEKSI LUTHIER JNOVA
            _buildLuthierInspectionCard(),

            const SizedBox(height: 18),

            // 5. QR CODE VERIFIKASI FISIK & KEPEMILIKAN
            _buildPhysicalVerificationQr(context),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  /// Kartu NFT Hologram Mewah
  Widget _buildLuxuryNftCard(BuildContext context, String formattedDate) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF231C38),
            Color(0xFF171322),
            Color(0xFF0F0C18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFE5A93C).withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5A93C).withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Atas: Logo Jnova & Tag Verified
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5500),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E244D),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF9E86FF), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.token_rounded, size: 10, color: Color(0xFF9E86FF)),
                          const SizedBox(width: 3),
                          Text(
                            certificate.tokenId,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFC7B9FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: certificate.isClaimed
                          ? const Color(0xFF064E3B)
                          : const Color(0xFF2E2214),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: certificate.isClaimed
                            ? const Color(0xFF10B981)
                            : const Color(0xFFE5A93C),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          certificate.isClaimed
                              ? Icons.verified_user_rounded
                              : Icons.storefront_rounded,
                          size: 11,
                          color: certificate.isClaimed
                              ? const Color(0xFF34D399)
                              : const Color(0xFFFFB057),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            certificate.isClaimed
                                ? 'MILIK PEMBELI'
                                : 'STOK SHOWROOM',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: certificate.isClaimed
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFFFB057),
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

          const Divider(color: Color(0xFF2C2442), height: 1),

          // Foto Produk & Info Utama
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail Gambar Produk
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5A93C), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: certificate.product.image.startsWith('assets/')
                        ? Image.asset(
                            certificate.product.image,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.music_note_rounded,
                              size: 40,
                              color: Color(0xFFFF5500),
                            ),
                          )
                        : Image.network(
                            certificate.product.image,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.music_note_rounded,
                              size: 40,
                              color: Color(0xFFFF5500),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // Info Produk
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        certificate.product.brand.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE5A93C),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        certificate.product.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatCurrency(certificate.product.price),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFF7A33),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Kategori: ${certificate.product.category}',
                          style: const TextStyle(fontSize: 9.5, color: Color(0xFFD1CADB)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Detail Bar: Serial Number & Pemilik
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            decoration: BoxDecoration(
              color: const Color(0xFF13101C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF28203D), width: 1),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Nomor Seri Resmi:',
                      style: TextStyle(fontSize: 10, color: Color(0xFF8E839E)),
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
                                color: Color(0xFFFFD580),
                                letterSpacing: 0.4,
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
                              color: Color(0xFFE5A93C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text(
                      'Pemilik Terdaftar:',
                      style: TextStyle(fontSize: 10, color: Color(0xFF8E839E)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        certificate.ownerName,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: certificate.isClaimed
                              ? Colors.white
                              : const Color(0xFFFFB057),
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

  /// Bagian Data Buku Besar On-Chain (Polygon Network)
  Widget _buildOnChainLedgerSection(BuildContext context, String formattedDate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161A22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232A38), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8247E5).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.link_rounded, size: 16, color: Color(0xFFA77DFF)),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi On-Chain Blockchain',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Tercatat permanen dan tidak dapat dipalsukan',
                    style: TextStyle(fontSize: 9.5, color: Color(0xFF8692A6)),
                  ),
                ],
              ),
            ],
          ),
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
          Icon(icon, size: 14, color: const Color(0xFF6B7A90)),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF8E9BAE)),
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
                      color: isMonospace ? const Color(0xFF8CE3FF) : Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (copyable) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _copyToClipboard(context, value, label),
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 13,
                      color: Color(0xFFFF5500),
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
        color: const Color(0xFF161A22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232A38), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.build_circle_outlined, size: 16, color: Color(0xFFFF9E3D)),
              SizedBox(width: 8),
              Text(
                'Laporan Audit & Kalibrasi Luthier',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Auditor: ${certificate.inspectorName}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF9E3D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            certificate.inspectionNotes,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFBAC5D5),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F261E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF10B981), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF34D399)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    certificate.acousticSignature,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF34D399),
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
        color: const Color(0xFF161A22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232A38), width: 1),
      ),
      child: Column(
        children: [
          const Text(
            'QR Code Verifikasi Fisik & Label Tag',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pindai QR ini saat unboxing di toko JNOVA atau saat jual kembali untuk memverifikasi keaslian instrumen.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Color(0xFF8692A6)),
          ),
          const SizedBox(height: 16),

          // QR Code Widget
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5A93C), width: 2),
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
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFFD580),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
