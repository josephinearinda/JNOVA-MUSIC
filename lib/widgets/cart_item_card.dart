import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/product.dart';

/// Kartu item horizontal di halaman Keranjang Saya sesuai desain Figma
class CartItemCard extends StatelessWidget {
  final CartItem item;
  final ValueChanged<bool?> onToggleSelect;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onToggleSelect,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox oranye khusus
          Padding(
            padding: const EdgeInsets.only(top: 14.0),
            child: GestureDetector(
              onTap: () => onToggleSelect(!item.isSelected),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: item.isSelected
                      ? AppColors.primaryOrange
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: item.isSelected
                        ? AppColors.primaryOrange
                        : const Color(0xFFCCCCCC),
                    width: 1.5,
                  ),
                ),
                child: item.isSelected
                    ? const Icon(
                        Icons.check,
                        size: 13,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Thumbnail Produk
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 52,
              height: 52,
              color: const Color(0xFFF7F6F4),
              child: Image.asset(
                item.product.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_not_supported_rounded,
                  color: AppColors.placeholder,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Detail Produk
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris Brand & Tombol Hapus (X)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.brand.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF9E4D1D),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onRemove,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6, bottom: 4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ),
                  ],
                ),

                // Nama Produk
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                // Varian / Subtitle
                if (item.product.variant.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.product.variant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7E756F),
                      fontSize: 9.5,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Baris Harga & Stepper Kuantitas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatRupiah(item.product.price),
                      style: const TextStyle(
                        color: AppColors.primaryOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    // Stepper (- 1 +)
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F2F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStepperButton(
                            icon: Icons.remove,
                            onTap: onDecrement,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryDark,
                              ),
                            ),
                          ),
                          _buildStepperButton(
                            icon: Icons.add,
                            onTap: onIncrement,
                          ),
                        ],
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

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 22,
        height: 24,
        child: Icon(
          icon,
          size: 13,
          color: AppColors.textPrimaryDark,
        ),
      ),
    );
  }
}
