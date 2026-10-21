import 'product.dart';
import 'store_branch.dart';

enum FulfillmentMethod { pickup }

class TrackingStep {
  final String title;
  final String time;
  final String description;
  final bool isCompleted;
  final bool isActive;

  const TrackingStep({
    required this.title,
    required this.time,
    required this.description,
    this.isCompleted = false,
    this.isActive = false,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'time': time,
        'description': description,
        'isCompleted': isCompleted,
        'isActive': isActive,
      };

  factory TrackingStep.fromMap(Map<String, dynamic> map) => TrackingStep(
        title: map['title'] as String? ?? '',
        time: map['time'] as String? ?? '',
        description: map['description'] as String? ?? '',
        isCompleted: map['isCompleted'] as bool? ?? false,
        isActive: map['isActive'] as bool? ?? false,
      );
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String dateFormatted;
  final FulfillmentMethod fulfillmentMethod;
  final String status;
  final List<CartItem> items;
  final int subtotal;
  final int discount;
  final int shippingFee;
  final int packingFee;
  final int serviceFee;
  final int totalPayment;
  final String paymentMethod;
  final StoreBranch? pickupStore;
  final String pickupCode;
  final String recipientName;
  final String recipientPhone;
  final String recipientAddress;
  final bool isCompleted;
  final bool pointsAwarded;
  final String userEmail;
  final List<TrackingStep> trackingSteps;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.dateFormatted,
    this.fulfillmentMethod = FulfillmentMethod.pickup,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.discount,
    this.shippingFee = 0,
    this.packingFee = 0,
    this.serviceFee = 1000,
    required this.totalPayment,
    required this.paymentMethod,
    this.pickupStore,
    this.pickupCode = '',
    this.recipientName = '',
    this.recipientPhone = '',
    this.recipientAddress = '',
    this.isCompleted = false,
    this.pointsAwarded = false,
    this.userEmail = '',
    this.trackingSteps = const [],
  });

  StoreBranch? get store => pickupStore;

  OrderModel copyWith({
    String? id,
    String? orderNumber,
    String? dateFormatted,
    FulfillmentMethod? fulfillmentMethod,
    String? status,
    List<CartItem>? items,
    int? subtotal,
    int? discount,
    int? shippingFee,
    int? packingFee,
    int? serviceFee,
    int? totalPayment,
    String? paymentMethod,
    StoreBranch? pickupStore,
    String? pickupCode,
    String? recipientName,
    String? recipientPhone,
    String? recipientAddress,
    bool? isCompleted,
    bool? pointsAwarded,
    String? userEmail,
    List<TrackingStep>? trackingSteps,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      dateFormatted: dateFormatted ?? this.dateFormatted,
      fulfillmentMethod: fulfillmentMethod ?? this.fulfillmentMethod,
      status: status ?? this.status,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      shippingFee: shippingFee ?? this.shippingFee,
      packingFee: packingFee ?? this.packingFee,
      serviceFee: serviceFee ?? this.serviceFee,
      totalPayment: totalPayment ?? this.totalPayment,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      pickupStore: pickupStore ?? this.pickupStore,
      pickupCode: pickupCode ?? this.pickupCode,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      isCompleted: isCompleted ?? this.isCompleted,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      userEmail: userEmail ?? this.userEmail,
      trackingSteps: trackingSteps ?? this.trackingSteps,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'dateFormatted': dateFormatted,
      'fulfillmentMethod': fulfillmentMethod.name,
      'status': status,
      'items': items
          .map((i) => {
                'productId': i.product.id,
                'quantity': i.quantity,
                'isSelected': i.isSelected,
              })
          .toList(),
      'subtotal': subtotal,
      'discount': discount,
      'shippingFee': shippingFee,
      'packingFee': packingFee,
      'serviceFee': serviceFee,
      'totalPayment': totalPayment,
      'paymentMethod': paymentMethod,
      'pickupStoreId': pickupStore?.id,
      'pickupCode': pickupCode,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'recipientAddress': recipientAddress,
      'isCompleted': isCompleted,
      'pointsAwarded': pointsAwarded,
      'userEmail': userEmail,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final storeId = map['pickupStoreId'] as String?;
    final store = storeId != null ? StoreBranch.findById(storeId) : StoreBranch.branches.first;

    final rawItems = map['items'] as List<dynamic>? ?? [];
    final items = <CartItem>[];
    for (final raw in rawItems) {
      final itemMap = Map<String, dynamic>.from(raw as Map);
      final pId = itemMap['productId'] as String?;
      final product = Product.allCatalog.firstWhere(
        (p) => p.id == pId,
        orElse: () => Product.allCatalog.first,
      );
      items.add(CartItem(
        product: product,
        quantity: (itemMap['quantity'] as num?)?.toInt() ?? 1,
        isSelected: itemMap['isSelected'] as bool? ?? true,
      ));
    }

    return OrderModel(
      id: map['id'] as String? ?? '',
      orderNumber: map['orderNumber'] as String? ?? '',
      dateFormatted: map['dateFormatted'] as String? ?? '',
      fulfillmentMethod: FulfillmentMethod.pickup,
      status: map['status'] as String? ?? 'Menunggu Pengambilan & Pembayaran di Toko',
      items: items,
      subtotal: (map['subtotal'] as num?)?.toInt() ?? 0,
      discount: (map['discount'] as num?)?.toInt() ?? 0,
      shippingFee: (map['shippingFee'] as num?)?.toInt() ?? 0,
      packingFee: (map['packingFee'] as num?)?.toInt() ?? 0,
      serviceFee: (map['serviceFee'] as num?)?.toInt() ?? 1000,
      totalPayment: (map['totalPayment'] as num?)?.toInt() ?? 0,
      paymentMethod: map['paymentMethod'] as String? ?? 'Bayar di Toko (Pickup & Pay)',
      pickupStore: store,
      pickupCode: map['pickupCode'] as String? ?? '',
      recipientName: map['recipientName'] as String? ?? '',
      recipientPhone: map['recipientPhone'] as String? ?? '',
      recipientAddress: map['recipientAddress'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      pointsAwarded: map['pointsAwarded'] as bool? ?? false,
      userEmail: map['userEmail'] as String? ?? '',
    );
  }

  /// Factory untuk membuat pesanan baru dari data keranjang aktual
  static OrderModel createFromCart({
    required List<CartItem> cartItems,
    required FulfillmentMethod fulfillment,
    required String paymentMethod,
    StoreBranch? store,
    int shippingCost = 0,
    int packingCost = 0,
    int serviceCost = 1000,
    String? recipientName,
    String? recipientPhone,
    String? recipientAddress,
    String? userEmail,
    double? discountRate,
  }) {
    final sub = cartItems.fold(0, (sum, item) => sum + item.itemTotal);
    final effectiveDiscountRate = discountRate ?? 0.10;
    final disc = (sub * effectiveDiscountRate).round();
    final total = sub - disc + shippingCost + packingCost + serviceCost;

    final now = DateTime.now();
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final dateStr =
        '${now.day} ${months[now.month - 1]} ${now.year}, ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';
    final randomSuffix = 1000 + (now.millisecondsSinceEpoch % 9000);

    return OrderModel(
      id: 'ord_${now.millisecondsSinceEpoch}',
      orderNumber: '#JNV-${now.year}${now.month.toString().padLeft(2, '0')}-$randomSuffix',
      dateFormatted: dateStr,
      fulfillmentMethod: FulfillmentMethod.pickup,
      status: 'Menunggu Pengambilan & Pembayaran di Toko',
      items: List.from(cartItems),
      subtotal: sub,
      discount: disc,
      shippingFee: 0,
      packingFee: 0,
      serviceFee: serviceCost,
      totalPayment: total > 0 ? total : 0,
      paymentMethod: paymentMethod,
      pickupStore: store ?? StoreBranch.branches.first,
      pickupCode: 'PKP-$randomSuffix-JNV',
      recipientName: recipientName ?? '',
      recipientPhone: recipientPhone ?? '',
      recipientAddress: recipientAddress ?? '',
      isCompleted: false,
      pointsAwarded: false,
      userEmail: userEmail ?? '',
    );
  }
}
