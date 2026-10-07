import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/onboarding_controller.dart';

/// Layar pembuka funnel — intro konsep monster + CTA mulai. Implement
/// persis `design/Onboarding.dc.html` § Welcome.
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.controller, required this.onMasuk});

  final OnboardingController controller;
  final VoidCallback onMasuk;

  @override
  Widget build(BuildContext context) {
    final t = context.s.onboarding;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, AppSpacing.sm, 24, AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 5, 14, 5),
                  decoration: BoxDecoration(color: AppColors.permukaan, border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth), borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.primerTerang, AppColors.sekunderTerang])),
                      ),
                      const SizedBox(width: 6),
                      Text('Riung', style: AppTextStyles.title.copyWith(fontSize: 14)),
                    ],
                  ),
                ),
                const Spacer(),
                // Pilihan bahasa menggantikan "Lewati" di desain — onboarding
                // tidak bisa dilewati (skoring butuh jawaban), bahasa harus bisa dipilih.
                GestureDetector(
                  onTap: () => showBahasaSheet(context),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      const Icon(Icons.language_rounded, size: 16, color: AppColors.teksSekunder),
                      const SizedBox(width: 4),
                      Text(context.s.language.nativeName, style: AppTextStyles.caption.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.teksSekunder)),
                    ],
                  ),
                ),
              ],
            ),
            const Expanded(child: Center(child: _WelcomeHero())),
            Text(t.welcomeTitle, style: AppTextStyles.display.copyWith(fontSize: 34, height: 1.15)),
            const SizedBox(height: AppSpacing.md),
            Text(t.welcomeBody, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(width: 26, height: 8, decoration: BoxDecoration(color: AppColors.primer, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 6),
                for (var i = 0; i < 2; i++) ...[
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            RiungButton(label: t.welcomeStart, onPressed: controller.next),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: GestureDetector(
                onTap: onMasuk,
                behavior: HitTestBehavior.opaque,
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.teksSekunder),
                    children: [
                      TextSpan(text: t.haveAccountPrefix),
                      TextSpan(text: t.signInLink, style: const TextStyle(color: AppColors.primer, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hero sambutan (frame `Hero`): cincin kaca, Si Kabut di tengah, lima
/// monster kecil di orb kaca mengelilinginya.
class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 360,
        height: 400,
        child: Stack(
          children: [
            Positioned(
              left: 10,
              top: 40,
              child: Container(width: 340, height: 340, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.permukaan, width: AppGlass.edgeWidth))),
            ),
            Positioned(
              left: 60,
              top: 90,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppColors.permukaanPadat, AppColors.permukaan.withValues(alpha: 0.2)]),
                  border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
                ),
              ),
            ),
            const Positioned(left: 80, top: 100, child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 200, applyBossScale: false)),
            const Positioned(left: 7, top: 40, child: _Orb(monsterId: 'waswas', size: 92)),
            const Positioned(left: 265, top: 70, child: _Orb(monsterId: 'cermin', size: 84)),
            const Positioned(left: 1, top: 290, child: _Orb(monsterId: 'meronta', size: 80)),
            const Positioned(left: 270, top: 280, child: _Orb(monsterId: 'mengelak', size: 88)),
            const Positioned(left: 145, top: 330, child: _Orb(monsterId: 'sempurna', size: 70)),
            const Positioned(left: 125, top: 40, child: Icon(Icons.auto_awesome, size: 20, color: AppColors.permukaanPadat)),
            const Positioned(left: 285, top: 200, child: Icon(Icons.auto_awesome, size: 14, color: AppColors.permukaanPadat)),
            const Positioned(left: 45, top: 200, child: Icon(Icons.auto_awesome, size: 12, color: AppColors.permukaanPadat)),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.monsterId, required this.size});

  final String monsterId;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.kartu, border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth)),
      alignment: Alignment.center,
      child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: size * 0.86, applyBossScale: false),
    );
  }
}
