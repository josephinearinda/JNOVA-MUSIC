import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/product.dart';

/// Kartu produk favorit dalam layout 2-kolom sesuai desain Figma
class ProductFavoriteCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAddToCart;
  final VoidCallback? onTap;

  const ProductFavoriteCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onAddToCart,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF0EFEB), width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Area Foto & Badge & Tombol Favorit
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: Container(
                  height: 118,
                  width: double.infinity,
                  color: const Color(0xFFF7F7F7),
                  child: Stack(
                    children: [
                      // Gambar Produk dengan BoxFit.contain agar tidak terdistorsi/terpotong
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Image.asset(
                            product.image,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFF7F7F7),
                              child: const Icon(
                                Icons.music_note_rounded,
                                color: AppColors.placeholder,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Badge ORIGINAL / BEST SELLER
                      if (product.isOriginal)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ORIGINAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        )
                      else if (product.isBestSeller)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2A29),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'BEST SELLER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),

                      // Tombol Hati (Favorit)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: const CircleBorder(),
                          elevation: 1.5,
                          shadowColor: Colors.black.withValues(alpha: 0.12),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onToggleFavorite,
                            child: Padding(
                              padding: const EdgeInsets.all(5.5),
                              child: Icon(
                                isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 15,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Detail Produk dengan layout Expanded agar tidak terjadi RenderFlex overflow
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama Merek
                      Text(
                        product.brand.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF8E837D),
                          fontSize: 9.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Nama Produk (maksimal 2 baris rapi dan proporsional)
                      SizedBox(
                        height: 32,
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimaryDark,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Rating & Review
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: product.reviewCount > 0
                              ? [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 13,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    product.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimaryDark,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '(${product.reviewCount})',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ]
                              : const [
                                  Text(
                                    'Belum ada ulasan',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                        ),
                      ),

                      // Spacer memastikan harga dan tombol selalu sejajar di bagian bawah kartu
                      const Spacer(),

                      // Harga Produk (Oranye JNOVA)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatRupiah(product.price),
                          maxLines: 1,
                          style: const TextStyle(
                            color: AppColors.primaryOrange,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Tombol "+ Keranjang"
                      SizedBox(
                        width: double.infinity,
                        height: 30,
                        child: ElevatedButton(
                          onPressed: onAddToCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: 13.0,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '+ Keranjang',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
