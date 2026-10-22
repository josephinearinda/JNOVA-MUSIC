import 'package:flutter/foundation.dart';

import '../models/blockchain_certificate.dart';
import '../models/order_model.dart';
import '../models/product.dart';
import 'order_service.dart';
import 'user_profile_service.dart';

/// Layanan sertifikat keaslian digital blockchain (NFT / On-chain Authenticity)
class BlockchainCertificateService extends ChangeNotifier {
  BlockchainCertificateService._();

  static final BlockchainCertificateService instance =
      BlockchainCertificateService._();

  /// Mengecek apakah suatu produk memenuhi kriteria sertifikat keaslian blockchain
  /// Syarat: Kategori instrumen utama (Gitar, Bass, Drum, Piano, Biola, Saxophone)
  /// dan harga di atas Rp 6.000.000.
  bool isEligible(Product product) {
    return product.hasBlockchainCertificate;
  }

  /// Mengambil nama pembeli resmi yang terverifikasi untuk sertifikat NFT
  String getCurrentBuyerName({OrderModel? order}) {
    if (order != null && order.recipientName.trim().isNotEmpty) {
      return order.recipientName.trim();
    }
    final profile = UserProfileService.instance.profile;
    final fullName = profile.fullName.trim();
    if (fullName.isNotEmpty && fullName != 'Pengguna JNOVAMUSIC') {
      return fullName;
    }
    final email = profile.email.trim();
    if (email.isNotEmpty) {
      final namePart = email.split('@').first;
      if (namePart.isNotEmpty) {
        return namePart[0].toUpperCase() + namePart.substring(1);
      }
    }
    return 'Pelanggan JNOVAMUSIC';
  }

  /// Membuat atau mengambil sertifikat digital untuk produk tertentu
  /// Jika produk telah dibeli dalam riwayat pesanan pengguna, pemiliknya
  /// akan otomatis disesuaikan dengan nama pengguna yang membeli.
  BlockchainCertificate getCertificateForProduct(
    Product product, {
    String? ownerName,
    String? orderNumber,
  }) {
    if (ownerName == null || ownerName.trim().isEmpty) {
      final orders = OrderService.instance.orders;
      for (final order in orders) {
        final hasItem = order.items.any((i) => i.product.id == product.id);
        if (hasItem) {
          final buyer = getCurrentBuyerName(order: order);
          return BlockchainCertificate.forProduct(
            product: product,
            ownerName: buyer,
            orderNumber: order.orderNumber,
          );
        }
      }
    }

    return BlockchainCertificate.forProduct(
      product: product,
      ownerName: ownerName,
      orderNumber: orderNumber,
    );
  }

  /// Mengambil semua sertifikat keaslian:
  /// 1. Instrumen yang SUDAH DIBELI oleh user (dari pesanan) -> Atas nama pengguna
  /// 2. Instrumen stok showroom JNOVA -> Berstatus "Belum Terdaftar (Tersedia di Showroom)"
  List<BlockchainCertificate> getUserCertificates() {
    final orders = OrderService.instance.orders;
    final certificates = <BlockchainCertificate>[];
    final seenProductIds = <String>{};

    final defaultBuyer = getCurrentBuyerName();

    // 1. Ekstrak dari pesanan yang BENAR-BENAR dibeli oleh pengguna
    for (final order in orders) {
      for (final item in order.items) {
        if (item.product.hasBlockchainCertificate &&
            !seenProductIds.contains(item.product.id)) {
          seenProductIds.add(item.product.id);
          final buyerName = order.recipientName.trim().isNotEmpty
              ? order.recipientName.trim()
              : defaultBuyer;
          certificates.add(
            BlockchainCertificate.forProduct(
              product: item.product,
              ownerName: buyerName,
              orderNumber: order.orderNumber,
            ),
          );
        }
      }
    }

    // 2. Instrumen stok showroom bersertifikat (Belum dibeli oleh pengguna)
    // Pemiliknya tetap berstatus "Belum Terdaftar (Tersedia di Showroom)"
    final catalog = Product.allCatalog;
    final eligibleCatalog =
        catalog.where((p) => p.hasBlockchainCertificate).toList();

    for (final cat in Product.blockchainEligibleCategories) {
      final matching = eligibleCatalog.where(
        (p) => p.category.toLowerCase() == cat.toLowerCase(),
      );
      if (matching.isNotEmpty) {
        final product = matching.first;
        if (!seenProductIds.contains(product.id)) {
          seenProductIds.add(product.id);
          certificates.add(
            BlockchainCertificate.forProduct(
              product: product,
              ownerName: null, // Belum dibeli, stok showroom
              orderNumber: null,
            ),
          );
        }
      }
    }

    return certificates;
  }

  /// Verifikasi serial number instrumen
  /// Mengembalikan objek [BlockchainCertificate] jika ditemukan, atau null jika tidak valid
  BlockchainCertificate? verifySerialNumber(String query) {
    final cleanQuery = query.trim().toUpperCase();
    if (cleanQuery.isEmpty) return null;

    final allCertificates = getUserCertificates();
    for (final cert in allCertificates) {
      if (cert.serialNumber.toUpperCase().contains(cleanQuery) ||
          cert.id.toUpperCase().contains(cleanQuery) ||
          cert.tokenId.toUpperCase().contains(cleanQuery)) {
        return cert;
      }
    }

    // Cek juga ke semua katalog yang eligible
    final eligibleCatalog =
        Product.allCatalog.where((p) => p.hasBlockchainCertificate).toList();
    for (final product in eligibleCatalog) {
      final cert = getCertificateForProduct(product);
      if (cert.serialNumber.toUpperCase().contains(cleanQuery) ||
          cert.id.toUpperCase().contains(cleanQuery) ||
          cert.tokenId.toUpperCase().contains(cleanQuery)) {
        return cert;
      }
    }

    return null;
  }
}
