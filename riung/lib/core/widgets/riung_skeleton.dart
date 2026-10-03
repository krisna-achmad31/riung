import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Placeholder shimmer buat list/card yang lagi loading — dipakai
/// daripada spinner polos supaya bentuk layout kelihatan lebih cepat.
class RiungSkeleton extends StatefulWidget {
  const RiungSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = AppRadius.sm,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<RiungSkeleton> createState() => _RiungSkeletonState();
}

class _RiungSkeletonState extends State<RiungSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.35 + _controller.value * 0.25;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.kartu.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Kartu skeleton siap pakai — ukuran mendekati kartu konten Riung
/// (ikon + 2 baris teks), dipakai di list Meditasi/Tidur/Toko dsb saat
/// data belum termuat.
class RiungSkeletonCard extends StatelessWidget {
  const RiungSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          const RiungSkeleton(width: 44, height: 44, borderRadius: 14),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                RiungSkeleton(width: 140, height: 13),
                SizedBox(height: 8),
                RiungSkeleton(width: 90, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
