import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/product.dart';
import '../services/gemini_service.dart';
import '../widgets/app_bottom_nav.dart';

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
}

/// Halaman AI ASSISTANT JNOVAMUSIC sesuai desain Figma (figma_slice_13_593x762.png)
class AIChatPage extends StatefulWidget {
  final VoidCallback? onBack;

  const AIChatPage({super.key, this.onBack});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAITyping = false;
  String _typingNote = 'Jnova menganalisis paket pemula & pick...';

  late List<AIChatMessage> _messages;

  Product get _yamahaF310Product {
    return Product.allCatalog.firstWhere(
      (p) => p.id == 'p6',
      orElse: () => Product.allCatalog.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeDefaultChat();
  }

  void _initializeDefaultChat() {
    _messages = [
      const AIChatMessage(
        id: 'm1',
        isUser: false,
        text: 'Halo! Ada yang bisa kubantu hari ini?\n\nAku siap membantumu menemukan alat musik yang sesuai dengan kebutuhan, gaya bermain, dan budget-mu.',
        time: '14:20',
      ),
      const AIChatMessage(
        id: 'm2',
        isUser: true,
        text: 'Aku mau cari gitar untuk pemula dengan budget Rp2.000.000.',
        time: '14:21',
      ),
      AIChatMessage(
        id: 'm3',
        isUser: false,
        text: 'Tentu! Untuk pemula dengan budget Rp2.000.000, kita bisa mencari gitar yang nyaman dimainkan dan sesuai dengan preferensi suaramu.\n\nKamu lebih tertarik dengan gitar akustik atau gitar elektrik?',
        time: '14:21',
        chips: const ['Gitar Akustik', 'Gitar Elektrik'],
        selectedChip: 'Gitar Akustik',
        recommendedProduct: _yamahaF310Product,
        customProductName: 'Yamaha F310 Natural',
        customProductPrice: 'Rp1.850.000',
        productBadge: 'REKOMENDASI TERBAIK PEMULA',
        productOriginalPrice: 'Rp2.000.000',
        productPoints: '+93 Poin Member',
        productDescription: 'Action senar rendah bersahabat untuk pemula, kayu spruce terpilih, dan intonasi presisi standar studio Yamaha.',
      ),
    ];
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleChipSelected(String chipText) async {
    if (_isAITyping) return;

    final queryText = chipText == 'Gitar Elektrik'
        ? 'Saya lebih tertarik dengan gitar elektrik.'
        : 'Saya lebih tertarik dengan gitar akustik.';

    setState(() {
      _messages.add(
        AIChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          isUser: true,
          text: queryText,
          time: _formatCurrentTime(),
        ),
      );
      _isAITyping = true;
      _typingNote = 'Jnova AI mencari rekomendasi $chipText...';
    });
    _scrollToBottom();

    final response = await GeminiService.instance.sendMessage(queryText);
    if (!mounted) return;

    setState(() {
      _isAITyping = false;
      _messages.add(
        AIChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          isUser: false,
          text: response.text,
          time: _formatCurrentTime(),
          recommendedProduct: response.isSuccess
              ? response.recommendedProduct
              : null,
          productBadge: response.isSuccess ? response.badge : null,
          productOriginalPrice:
              response.isSuccess && response.recommendedProduct != null
              ? 'Rp${((response.recommendedProduct!.price * 1.15) / 1000).round() * 1000}'
              : null,
          productPoints: response.isSuccess ? response.pointsLabel : null,
          productDescription: response.isSuccess
              ? response.recommendedProduct?.description
              : null,
          errorCode: response.errorCode,
        ),
      );
    });
    _scrollToBottom();
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _sendMessage() async {
    if (_isAITyping) return;
    final query = _inputController.text.trim();
    if (query.isEmpty) return;

    final nowTime = _formatCurrentTime();
    setState(() {
      _messages.add(
        AIChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          isUser: true,
          text: query,
          time: nowTime,
        ),
      );
      _inputController.clear();
      _isAITyping = true;
      _typingNote = 'Jnova AI sedang memproses...';
    });
    _scrollToBottom();

    final response = await GeminiService.instance.sendMessage(query);
    if (!mounted) return;

    setState(() {
      _isAITyping = false;
      _messages.add(
        AIChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          isUser: false,
          text: response.text,
          time: _formatCurrentTime(),
          recommendedProduct: response.isSuccess
              ? response.recommendedProduct
              : null,
          productBadge: response.isSuccess ? response.badge : null,
          productPoints: response.isSuccess ? response.pointsLabel : null,
          productDescription: response.isSuccess
              ? response.recommendedProduct?.description
              : null,
          errorCode: response.errorCode,
        ),
      );
    });
    _scrollToBottom();
  }

  Future<void> _retryLastUserMessage() async {
    if (_isAITyping) return;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) {
        final lastText = _messages[i].text;
        if (lastText.isNotEmpty) {
          _inputController.text = lastText;
          _sendMessage();
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopAppBar(context),

            // Chat Messages Area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: _messages.length + (_isAITyping ? 2 : 1),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildDateHeader();
                  }

                  final messageIndex = index - 1;
                  if (messageIndex < _messages.length) {
                    final msg = _messages[messageIndex];
                    return _buildMessageItem(msg);
                  }

                  // AI Typing Indicator
                  return _buildAITypingIndicator();
                },
              ),
            ),

            // Bottom Input Bar
            _buildInputBar(),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 4, // Profil / Activity context
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/favorite');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/all-products');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/membership-settings');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/order-detail');
          } else if (index == 4) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF2F0ED), width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InkWell(
                onTap: _handleBack,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF5F3EF),
                    border: Border.all(
                      color: const Color(0xFFEBE8E3),
                      width: 1.0,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 17,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEDDF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Jnova AI',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDDF),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          '+BETA',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Asisten musik pribadi',
                    style: TextStyle(fontSize: 9.5, color: Color(0xFF8E837D)),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Row(
                        children: [
                          Icon(
                            Icons.history_rounded,
                            color: AppColors.primaryOrange,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Sesi Obrolan Jnova AI',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        'Terdapat ${_messages.length} pesan dalam sesi aktif ini.\n\nApakah Anda ingin memulai obrolan baru dengan Jnova AI?',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5A524D),
                          height: 1.4,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Tutup',
                            style: TextStyle(color: Color(0xFF7E756F)),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            GeminiService.instance.resetChat();
                            setState(() {
                              _initializeDefaultChat();
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Sesi percakapan baru telah dimulai.',
                                ),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            elevation: 0,
                          ),
                          child: const Text(
                            'Obrolan Baru',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(
                  Icons.history_rounded,
                  color: Color(0xFF6E6560),
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8D4315),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEBE7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Hari ini, 14:20 WIB',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7E756F),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(AIChatMessage msg) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${msg.time} ✓✓',
              style: const TextStyle(fontSize: 8.5, color: Color(0xFFB0AAA4)),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(3),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // AI Message
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEDDF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F4F0),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(3),
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textPrimaryDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 36, top: 2),
            child: Text(
              msg.time,
              style: const TextStyle(fontSize: 8.5, color: Color(0xFF8E837D)),
            ),
          ),

          // Chips if present
          if (msg.chips != null && msg.chips!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Row(
                children: msg.chips!.map((chipText) {
                  final isSelected = chipText == msg.selectedChip;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () => _handleChipSelected(chipText),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFEDDF)
                              : const Color(0xFFFAF9F7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryOrange
                                : const Color(0xFFEBE8E3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                Icons.check,
                                size: 12,
                                color: AppColors.primaryOrange,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              chipText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primaryOrange
                                    : const Color(0xFF6E6560),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Product Recommendation Card if present
          if (msg.recommendedProduct != null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: _buildProductRecommendationCard(
                product: msg.recommendedProduct!,
                productName: msg.customProductName,
                productPrice: msg.customProductPrice,
                badge: msg.productBadge ?? 'REKOMENDASI TERBAIK PEMULA',
                originalPrice: msg.productOriginalPrice,
                points: msg.productPoints ?? '+93 Poin Member',
                description:
                    msg.productDescription ??
                    msg.recommendedProduct!.description,
              ),
            ),
          ],
          // Tombol Coba Lagi untuk error jaringan, timeout, atau server
          if (msg.errorCode == 'offline' ||
              msg.errorCode == 'timeout' ||
              msg.errorCode == 'network_error' ||
              msg.errorCode == 'server_error') ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: InkWell(
                onTap: () => _retryLastUserMessage(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F4F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE2DDD8),
                      width: 1.0,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 13,
                        color: Color(0xFF6E6560),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Coba Kirim Ulang',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6E6560),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductRecommendationCard({
    required Product product,
    String? productName,
    String? productPrice,
    required String badge,
    String? originalPrice,
    required String points,
    required String description,
  }) {
    final displayName = productName ?? product.name;
    final displayPrice =
        productPrice ??
        'Rp${product.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDDF),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: Color(0xFFC2410C),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F8F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    product.image,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.music_note_rounded,
                      size: 26,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          displayPrice,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                        if (originalPrice != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            originalPrice,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFFB0AAA4),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEBE7),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        points,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5A524D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFF6E6560),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),

          // Actions
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/product-detail',
                        arguments: product,
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Lihat Produk',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${product.name} ditambahkan ke daftar tersimpan.',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3EF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEBE8E3)),
                  ),
                  child: const Icon(
                    Icons.bookmark_border_rounded,
                    size: 16,
                    color: Color(0xFF6E6560),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAITypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 36, bottom: 12, top: 4),
      child: Row(
        children: [
          Text(
            _typingNote,
            style: const TextStyle(
              fontSize: 9.5,
              fontStyle: FontStyle.italic,
              color: Color(0xFF8E837D),
            ),
          ),
          const SizedBox(width: 4),
          const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Color(0xFFEFECE8), width: 1.0)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            InkWell(
              onTap: () {
                _inputController.text =
                    'Rekomendasi instrumen terbaik untuk rekaman';
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F3EF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: Color(0xFF6E6560),
                ),
              ),
            ),
            const SizedBox(width: 8),

            Expanded(
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE8E5DF)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        onSubmitted: (_) => _sendMessage(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimaryDark,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Tanyakan rekomendasi atau spesifikasi...',
                          hintStyle: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF9E958F),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Perekam suara AI siap mendengarkan.',
                            ),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.mic_none_rounded,
                        size: 17,
                        color: Color(0xFF8E837D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            InkWell(
              onTap: _sendMessage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.primaryOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
