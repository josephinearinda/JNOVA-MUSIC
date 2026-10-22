import 'package:flutter_test/flutter_test.dart';
import 'package:jnova/models/product.dart';
import 'package:jnova/services/blockchain_certificate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Blockchain Certificate Eligibility & Service Test', () {
    test('Produk Gitar dengan harga > 6 Juta harus berhak dapat sertifikat', () {
      const expensiveGuitar = Product(
        id: 'gtr-test-1',
        name: 'Fender Player Stratocaster',
        brand: 'Fender',
        price: 12500000,
        image: 'assets/images/fav_fender.png',
        rating: 5.0,
        reviewCount: 10,
        category: 'Gitar',
      );

      expect(expensiveGuitar.hasBlockchainCertificate, isTrue);
      expect(
        BlockchainCertificateService.instance.isEligible(expensiveGuitar),
        isTrue,
      );
    });

    test('Produk Gitar dengan harga <= 6 Juta TIDAK berhak dapat sertifikat', () {
      const cheapGuitar = Product(
        id: 'gtr-test-2',
        name: 'Yamaha C315',
        brand: 'Yamaha',
        price: 1450000,
        image: 'assets/images/fav_fender.png',
        rating: 4.8,
        reviewCount: 5,
        category: 'Gitar',
      );

      expect(cheapGuitar.hasBlockchainCertificate, isFalse);
      expect(
        BlockchainCertificateService.instance.isEligible(cheapGuitar),
        isFalse,
      );
    });

    test('Kategori non-instrumen (Aksesoris/Kabel Jack) walau mahal TIDAK dapat sertifikat', () {
      const expensiveAccessory = Product(
        id: 'acc-test-1',
        name: 'Custom Flight Case Roadie',
        brand: 'RoadReady',
        price: 7500000,
        image: 'assets/images/fav_fender.png',
        rating: 5.0,
        reviewCount: 2,
        category: 'Aksesoris',
      );

      expect(expensiveAccessory.hasBlockchainCertificate, isFalse);
    });

    test('Sertifikat dapat dibuat dengan detail on-chain lengkap', () {
      const bassPro = Product(
        id: 'bass-test-1',
        name: 'Fender Player Jazz Bass',
        brand: 'Fender',
        price: 12800000,
        image: 'assets/images/fav_fender.png',
        rating: 4.9,
        reviewCount: 8,
        category: 'Bass',
        code: '0149902500',
      );

      final cert = BlockchainCertificateService.instance.getCertificateForProduct(
        bassPro,
        ownerName: 'Arinda',
        orderNumber: 'ORD-TEST-9901',
      );

      expect(cert.product.name, equals('Fender Player Jazz Bass'));
      expect(cert.ownerName, equals('Arinda'));
      expect(cert.serialNumber, contains('SN-FENDER'));
      expect(cert.tokenId, startsWith('#'));
      expect(cert.txHash, startsWith('0x'));
      expect(cert.tokenStandard, contains('ERC-721'));
      expect(cert.network, contains('Polygon'));
      expect(cert.qrVerificationData, contains('JNOVA_BLOCKCHAIN_VERIFY'));
    });

    test('Verifikasi nomor seri yang valid berhasil menemukan sertifikat', () {
      final eligibleProduct =
          Product.allCatalog.firstWhere((p) => p.hasBlockchainCertificate);
      final cert =
          BlockchainCertificateService.instance.getCertificateForProduct(eligibleProduct);
      final verified =
          BlockchainCertificateService.instance.verifySerialNumber(cert.serialNumber);

      expect(verified, isNotNull);
      expect(verified?.product.name, equals(eligibleProduct.name));
    });
  });
}
