import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/ai_chat_message.dart';
import '../models/product.dart';
import '../services/ai_chat_service.dart';
import '../services/gemini_service.dart';
import '../widgets/app_bottom_nav.dart';

export '../models/ai_chat_message.dart';

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

  List<AIChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    if (AIChatService.instance.messages.isNotEmpty) {
      _messages = List.from(AIChatService.instance.messages);
    }
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final loaded = await AIChatService.instance.loadMessages();
    if (!mounted) return;
    setState(() {
      _messages = List.from(loaded);
    });
    _scrollToBottom();
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

  Future<void> _handleChipSelected(String chipText, {String? messageId}) async {
    if (_isAITyping) return;

    if (messageId != null) {
      final msgIdx = _messages.indexWhere((m) => m.id == messageId);
      if (msgIdx != -1) {
        final updated = _messages[msgIdx].copyWith(selectedChip: chipText);
        setState(() {
          _messages[msgIdx] = updated;
        });
        AIChatService.instance.updateMessage(updated);
      }
    }

    final queryText = chipText == 'Gitar Elektrik'
        ? 'Saya lebih tertarik dengan gitar elektrik.'
        : 'Saya lebih tertarik dengan gitar akustik.';

    final userMsg = AIChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: true,
      text: queryText,
      time: _formatCurrentTime(),
    );

    setState(() {
      _messages.add(userMsg);
      _isAITyping = true;
      _typingNote = 'Jnova AI mencari rekomendasi $chipText...';
    });
    _scrollToBottom();

    await AIChatService.instance.addMessage(userMsg);

    final response = await GeminiService.instance.sendMessage(queryText);
    if (!mounted) return;

    final aiMsg = AIChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
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
    );

    setState(() {
      _isAITyping = false;
      _messages.add(aiMsg);
    });
    _scrollToBottom();

    await AIChatService.instance.addMessage(aiMsg);
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
    final userMsg = AIChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: true,
      text: query,
      time: nowTime,
    );

    setState(() {
      _messages.add(userMsg);
      _inputController.clear();
      _isAITyping = true;
      _typingNote = 'Jnova AI sedang memproses...';
    });
    _scrollToBottom();

    await AIChatService.instance.addMessage(userMsg);

    final response = await GeminiService.instance.sendMessage(query);
    if (!mounted) return;

    final aiMsg = AIChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
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
    );

    setState(() {
      _isAITyping = false;
      _messages.add(aiMsg);
    });
    _scrollToBottom();

    await AIChatService.instance.addMessage(aiMsg);
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

  void _showResetQuotaDialog() {
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
              Icons.bolt_rounded,
              color: AppColors.primaryOrange,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Reset Kuota & Obrolan AI',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF059669),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Status: Respon Cepat & Tanpa Batas',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Fitur ini akan menyetel ulang batas kuota dan membersihkan riwayat percakapan agar Jnova AI dapat langsung menjawab setiap pertanyaan tanpa hambatan limit.',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF5A524D),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF7E756F)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              GeminiService.instance.resetQuotaAndChat();
              await AIChatService.instance.resetChat();
              final resetMessages =
                  await AIChatService.instance.loadMessages(forceReload: true);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              setState(() {
                _messages = List.from(resetMessages);
              });
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '✅ Kuota dan sesi obrolan Jnova AI berhasil direset! AI siap menjawab langsung.',
                  ),
                  backgroundColor: Color(0xFF222222),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text(
              'Reset Sekarang',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
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
              // Tombol Cepat Reset Kuota AI
              InkWell(
                onTap: _showResetQuotaDialog,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2EB),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: const Color(0xFFFFD1B3), width: 0.9),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: AppColors.primaryOrange,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Reset Kuota',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Sesi & Reset Kuota',
                onPressed: _showResetQuotaDialog,
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
                      onTap: () =>
                          _handleChipSelected(chipText, messageId: msg.id),
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
          // Tombol Coba Lagi / Reset Kuota untuk error atau pesan pembatasan
          if (msg.errorCode != null ||
              msg.text.contains('tidak tersedia') ||
              msg.text.contains('kuota') ||
              msg.text.contains('limit')) ...[
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
                    color: const Color(0xFFFFF2EB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFFD1B3),
                      width: 1.0,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: AppColors.primaryOrange,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '⚡ Jawab Langsung (Reset Kuota)',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryOrange,
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
