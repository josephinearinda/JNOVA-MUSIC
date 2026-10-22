import 'package:flutter_test/flutter_test.dart';
import 'package:jnova/models/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads all CSV products and matches their catalog images', () async {
    await Product.loadCatalogFromAssets();

    expect(Product.allCatalog, hasLength(102));

    final yamahaF310 = Product.allCatalog.singleWhere(
      (product) => product.name == 'Yamaha F310',
    );
    expect(yamahaF310.brand, 'Yamaha');
    expect(yamahaF310.category, 'Gitar');
    expect(yamahaF310.variant, 'Akustik / Steel');
    expect(yamahaF310.price, 1650000);
    expect(yamahaF310.stock, 5);
    expect(yamahaF310.rating, 0);
    expect(yamahaF310.reviewCount, 0);
    expect(yamahaF310.image, 'GAMBAR KATALOG/GITAR/Yamaha F310.jpg');

    final dAddarioStrings = Product.allCatalog.singleWhere(
      (product) => product.name == 'D\'Addario EJ45 Pro-Arté',
    );
    expect(
      dAddarioStrings.image,
      'GAMBAR KATALOG/AKSESORIS/D\'Addario EJ45 Pro-Arté.jpg',
    );
  });
}
