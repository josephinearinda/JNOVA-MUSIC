import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Komponen Bottom Navigation Bar resmi JNOVAMUSIC sesuai desain Figma
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const AppBottomNav({
    super.key,
    this.currentIndex = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.storefront_outlined,
                activeIcon: Icons.storefront_rounded,
                label: 'Beranda',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.grid_view_rounded,
                activeIcon: Icons.grid_view_rounded,
                label: 'Kategori',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.military_tech_outlined,
                activeIcon: Icons.military_tech_rounded,
                label: 'Membership',
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Pesanan',
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isActive = index == currentIndex;
    final Color color = isActive ? AppColors.primaryOrange : const Color(0xFF6E6560);

    return Expanded(
      child: InkWell(
        onTap: () => onTap?.call(index),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 21,
                color: color,
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
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
