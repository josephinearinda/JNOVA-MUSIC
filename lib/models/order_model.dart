import 'product.dart';
import 'store_branch.dart';

enum FulfillmentMethod { pickup, delivery }

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
  final String courierName;
  final String trackingNumber;
  final String estimatedArrival;
  final List<TrackingStep> trackingSteps;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.dateFormatted,
    required this.fulfillmentMethod,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.shippingFee,
    required this.packingFee,
    required this.serviceFee,
    required this.totalPayment,
    required this.paymentMethod,
    this.pickupStore,
    this.pickupCode = 'PKP-8841-JNV',
    this.recipientName = 'Budi Pratama',
    this.recipientPhone = '(+62) 812-3456-7890',
    this.recipientAddress =
        'Jl. Senopati No. 42, RT 04 / RW 02, Kebayoran Baru, Jakarta Selatan, DKI Jakarta 12110',
    this.courierName = 'JNE Cargo - Music Care Handling',
    this.trackingNumber = 'JNE-MC8829104439',
    this.estimatedArrival = '20 Mei 2025',
    this.trackingSteps = const [],
  });

  /// Factory untuk membuat pesanan baru dari data keranjang aktual
  static OrderModel createFromCart({
    required List<CartItem> cartItems,
    required FulfillmentMethod fulfillment,
    required String paymentMethod,
    StoreBranch? store,
    int shippingCost = 0,
    int packingCost = 0,
    int serviceCost = 1000,
  }) {
    final sub = cartItems.fold(0, (sum, item) => sum + item.itemTotal);
    final disc = (sub * 0.10).round(); // Silver Member 10%
    final total = sub - disc + shippingCost + packingCost + serviceCost;

    return OrderModel(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      orderNumber: '#JNV-202505-8841',
      dateFormatted: '18 Mei 2025, 14:32 WIB',
      fulfillmentMethod: fulfillment,
      status: fulfillment == FulfillmentMethod.pickup
          ? 'Siap Diambil'
          : 'Dalam Pengiriman',
      items: List.from(cartItems),
      subtotal: sub,
      discount: disc,
      shippingFee: shippingCost,
      packingFee: packingCost,
      serviceFee: serviceCost,
      totalPayment: total > 0 ? total : 0,
      paymentMethod: paymentMethod,
      pickupStore: store ?? StoreBranch.branches.first,
      trackingSteps: const [
        TrackingStep(
          title: 'Pesanan Dibuat',
          time: '16 Mei, 14:32',
          description: 'Pesanan berhasil dibuat di sistem JNOVAMUSIC.',
          isCompleted: true,
        ),
        TrackingStep(
          title: 'Pembayaran Dikonfirmasi',
          time: '16 Mei, 14:33',
          description: 'Pembayaran otomatis via QRIS Instant terverifikasi.',
          isCompleted: true,
        ),
        TrackingStep(
          title: 'Pesanan Diproses & QC Luthier',
          time: '18 Mei, 17:00',
          description:
              'Instrumen selesai setup action senar & dikemas dalam peti kayu standar ekspor.',
          isCompleted: true,
        ),
        TrackingStep(
          title: 'Paket Diserahkan ke Ekspedisi',
          time: '18 Mei, 20:45',
          description: 'Diserahkan ke Drop Point JNE Cargo Jakarta Selatan.',
          isCompleted: true,
        ),
        TrackingStep(
          title: 'Paket Dalam Perjalanan',
          time: '19 Mei, 08:15',
          description:
              'Paket telah tiba di Gateway Hub Transit Jakarta & sedang menuju DC Kebayoran Baru.',
          isCompleted: true,
          isActive: true,
        ),
        TrackingStep(
          title: 'Paket Sampai di Tujuan',
          time: 'Est. 20 Mei',
          description: 'Kurir mengantar paket ke alamat penerima.',
        ),
        TrackingStep(
          title: 'Pesanan Selesai',
          time: '',
          description: 'Konfirmasi penerimaan instrumen oleh pembeli.',
        ),
      ],
    );
  }
}
