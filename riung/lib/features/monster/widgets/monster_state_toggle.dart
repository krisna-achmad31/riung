import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// Toggle pil Liar/Jinak untuk pratinjau wujud (frame `Toggle state`).
class MonsterStateToggle extends StatelessWidget {
  const MonsterStateToggle({super.key, required this.value, required this.wildLabel, required this.tamedLabel, required this.onChanged});

  final MonsterVisualState value;
  final String wildLabel;
  final String tamedLabel;
  final ValueChanged<MonsterVisualState> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(MonsterVisualState v, String label) {
      final on = v == value;
      return GestureDetector(
        onTap: () => onChanged(v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: on ? AppColors.tinta : AppColors.tinta.withValues(alpha: 0), borderRadius: BorderRadius.circular(AppRadius.pill)),
          child: Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: on ? AppColors.diAtasTinta : AppColors.teksSekunder)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: AppGlass.pill(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [seg(MonsterVisualState.liar, wildLabel), seg(MonsterVisualState.jinak, tamedLabel)],
      ),
    );
  }
}
