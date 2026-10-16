import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'riung_skeleton.dart';

/// Loading standar layar data: beberapa [RiungSkeletonCard] bertumpuk,
/// menggantikan spinner polos (lihat [RiungStateView]).
class RiungSkeletonList extends StatelessWidget {
  const RiungSkeletonList({super.key, this.count = 4, this.padding = const EdgeInsets.all(AppSpacing.xl)});

  final int count;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) => const RiungSkeletonCard(),
    );
  }
}
