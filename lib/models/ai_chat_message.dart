import 'dart:convert';
import 'product.dart';

/// Model pesan dalam obrolan Jnova AI
class AIChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final String time;
  final Product? recommendedProduct;
  final String? customProductName;
  final String? customProductPrice;
  final String? productBadge;
  final String? productOriginalPrice;
  final String? productPoints;
  final String? productDescription;
  final List<String>? chips;
  final String? selectedChip;
  final String? errorCode;

  const AIChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.time,
    this.recommendedProduct,
    this.customProductName,
    this.customProductPrice,
    this.productBadge,
    this.productOriginalPrice,
    this.productPoints,
    this.productDescription,
    this.chips,
    this.selectedChip,
    this.errorCode,
  });

  AIChatMessage copyWith({
    String? selectedChip,
    Product? recommendedProduct,
    String? customProductName,
    String? customProductPrice,
    String? productBadge,
    String? productOriginalPrice,
    String? productPoints,
    String? productDescription,
    String? errorCode,
  }) {
    return AIChatMessage(
      id: id,
      isUser: isUser,
      text: text,
      time: time,
      recommendedProduct: recommendedProduct ?? this.recommendedProduct,
      customProductName: customProductName ?? this.customProductName,
      customProductPrice: customProductPrice ?? this.customProductPrice,
      productBadge: productBadge ?? this.productBadge,
      productOriginalPrice: productOriginalPrice ?? this.productOriginalPrice,
      productPoints: productPoints ?? this.productPoints,
      productDescription: productDescription ?? this.productDescription,
      chips: chips,
      selectedChip: selectedChip ?? this.selectedChip,
      errorCode: errorCode ?? this.errorCode,
    );
  }

  Map<String, dynamic> toMap({required String userEmail, int? createdAt}) {
    return {
      'id': id,
      'user_email': userEmail.toLowerCase().trim(),
      'is_user': isUser ? 1 : 0,
      'text': text,
      'time': time,
      'recommended_product_id': recommendedProduct?.id,
      'custom_product_name': customProductName,
      'custom_product_price': customProductPrice,
      'product_badge': productBadge,
      'product_original_price': productOriginalPrice,
      'product_points': productPoints,
      'product_description': productDescription,
      'chips_json': chips != null ? jsonEncode(chips) : null,
      'selected_chip': selectedChip,
      'error_code': errorCode,
      'created_at': createdAt ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory AIChatMessage.fromMap(Map<String, dynamic> map) {
    Product? product;
    final productId = map['recommended_product_id'] as String?;
    if (productId != null && productId.isNotEmpty) {
      final matches = Product.allCatalog.where((p) => p.id == productId);
      if (matches.isNotEmpty) {
        product = matches.first;
      }
    }

    List<String>? chips;
    final chipsJson = map['chips_json'] as String?;
    if (chipsJson != null && chipsJson.isNotEmpty) {
      try {
        chips = (jsonDecode(chipsJson) as List).cast<String>();
      } catch (_) {}
    }

    return AIChatMessage(
      id: map['id'] as String,
      isUser: (map['is_user'] as int? ?? 0) == 1,
      text: map['text'] as String? ?? '',
      time: map['time'] as String? ?? '',
      recommendedProduct: product,
      customProductName: map['custom_product_name'] as String?,
      customProductPrice: map['custom_product_price'] as String?,
      productBadge: map['product_badge'] as String?,
      productOriginalPrice: map['product_original_price'] as String?,
      productPoints: map['product_points'] as String?,
      productDescription: map['product_description'] as String?,
      chips: chips,
      selectedChip: map['selected_chip'] as String?,
      errorCode: map['error_code'] as String?,
    );
  }
}

