import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class GameSelectionPage extends StatelessWidget {
  const GameSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimaryDark,
        title: const Text(
          'Pilih Game',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'JNOVAMUSIC ARCADE',
              style: TextStyle(
                color: AppColors.primaryOrange,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Mainkan game, kumpulkan poin!',
              style: TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            _GameCard(
              title: 'JNova Beat Tilt',
              description:
                  'Ikuti beat dan kumpulkan poin dengan menggoyangkan HP.',
              icon: Icons.graphic_eq_rounded,
              color: AppColors.primaryOrange,
              onTap: () => Navigator.pushNamed(context, '/game-permission'),
            ),
            const SizedBox(height: 14),
            _GameCard(
              title: 'JNova Dodge',
              description: 'Miringkan HP untuk menghindari balok dan raih skor tertinggi.',
              icon: Icons.sports_esports_rounded,
              color: const Color(0xFF06B6D4),
              onTap: () => Navigator.pushNamed(context, '/game2'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 29),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondaryBrown,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
