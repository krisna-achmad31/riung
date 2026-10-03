import 'package:flutter/material.dart';

import '../../../core/config/economy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/meditation_catalog.dart';
import 'meditasi_player_screen.dart';

/// Detail sesi meditasi. Implement persis `design/Meditasi.dc.html`
/// § Detail sesi.
class MeditasiDetailScreen extends StatefulWidget {
  const MeditasiDetailScreen({super.key, required this.session});

  final MeditationSession session;

  @override
  State<MeditasiDetailScreen> createState() => _MeditasiDetailScreenState();
}

class _MeditasiDetailScreenState extends State<MeditasiDetailScreen> {
  late int _durationIndex = widget.session.defaultDurationIndex;

  void _mulaiSesi() {
    final free = MeditationCatalog.isSessionFree(widget.session.id);
    final scope = AppScope.of(context);
    final premiumActive = scope.auth.profile?.premiumNow ?? false;
    if (!free && !premiumActive) {
      final t = scope.language.strings.meditasi;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PremiumLockedScreen(
            title: t.session(widget.session.id).title,
            freeTierNote: t.freeTierNote(EconomyFreeTier.meditasi),
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MeditasiPlayerScreen(
          session: widget.session,
          durationMinutes: widget.session.durations[_durationIndex],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final t = context.s.meditasi;
    final text = t.session(session.id);
    final monsterName = context.s.common.monsterName(session.targetMonsterId);

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: RiungGlowBackground(
        glowColor: session.color,
        alignment: const Alignment(0, -1.1),
        opacity: 0.14,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, color: AppColors.teksSekunder),
                    ),
                    GestureDetector(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.alreadyOffline))),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.kartu,
                          border: Border.all(color: AppColors.garis),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.download_done_rounded, size: 14, color: AppColors.teksSekunder),
                            const SizedBox(width: 6),
                            Text(t.download, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 120,
                        height: 126,
                        child: RiungMonster(monsterId: session.targetMonsterId, state: MonsterVisualState.liar, size: 120),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        t.fighting(monsterName),
                        style: AppTextStyles.caption.copyWith(color: session.color, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 10),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(text.title, textAlign: TextAlign.center, style: AppTextStyles.display.copyWith(fontSize: 23, height: 1.3)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(text.description, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.55)),
                      const SizedBox(height: AppSpacing.lg),
                      if (session.durations.length > 1) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(t.duration, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 13)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            for (var i = 0; i < session.durations.length; i++)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: i == session.durations.length - 1 ? 0 : AppSpacing.sm),
                                  child: GestureDetector(
                                    onTap: () => setState(() => _durationIndex = i),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: i == _durationIndex ? session.color : AppColors.garis, width: 1.5),
                                        color: i == _durationIndex ? session.color.withValues(alpha: 0.12) : Colors.transparent,
                                      ),
                                      child: Text(
                                        t.minutes(session.durations[i]),
                                        style: AppTextStyles.chipLabel.copyWith(
                                          fontSize: 14,
                                          color: i == _durationIndex ? session.color : AppColors.teksSekunder,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.permukaan,
                          border: Border.all(color: AppColors.garis),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [AppColors.primer, AppColors.monsterCermin]),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.graphic_eq, size: 20, color: AppColors.latar),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.ambientTitle, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 13)),
                                  Text(t.ambientNote, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _StatBox(icon: Icons.monetization_on, iconColor: AppColors.aksenHangat, value: '+${EconomyEarn.meditasi} ${t.coins}', label: t.whenDone),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _StatBox(icon: Icons.pest_control, iconColor: AppColors.monsterWaswas, value: '+3%', label: t.tame(monsterName)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
                child: SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _mulaiSesi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: session.color,
                      foregroundColor: AppColors.latar,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                    ),
                    icon: const Icon(Icons.play_arrow, size: 17),
                    label: Text(t.startSession, style: AppTextStyles.buttonLabel.copyWith(color: AppColors.latar)),
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

class _StatBox extends StatelessWidget {
  const _StatBox({required this.icon, required this.iconColor, required this.value, required this.label});

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.chipLabel.copyWith(color: iconColor, fontSize: 13)),
          Text(label, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
