import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

class _CrisisLine {
  const _CrisisLine({required this.name, required this.sub, required this.action, required this.icon, this.url, this.tel});
  final String name;
  final IconData icon;
  final String sub;
  final String action;
  final String? url;
  final String? tel;
}

/// Selalu bisa diakses dari Pengaturan, TIDAK PERNAH dilog analytics —
/// lihat CLAUDE.md aturan #4 "layar krisis selalu bisa diakses & tidak
/// dilog". Implement persis `design/Profil.dc.html` § "Bantuan krisis".
class BantuanKrisisScreen extends StatelessWidget {
  const BantuanKrisisScreen({super.key});

  List<_CrisisLine> _lines(BuildContext context) {
    final t = context.s.profil;
    return [
      _CrisisLine(name: 'SEJIWA', sub: t.sejiwaSub, action: t.actionCall, icon: Icons.phone_outlined, tel: '1198'),
      _CrisisLine(name: 'Into The Light Indonesia', sub: t.intoTheLightSub, action: t.actionOpenSite, icon: Icons.language_rounded, url: 'https://intothelightid.org'),
      _CrisisLine(name: 'IPK Indonesia', sub: t.ipkSub, action: t.actionSearch, icon: Icons.search_rounded, url: 'https://ipkindonesia.or.id'),
    ];
  }

  Future<void> _telepon(String nomor) => launchUrl(Uri(scheme: 'tel', path: nomor));

  Future<void> _bukaUrl(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final t = context.s.profil;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
          child: Column(
            children: [
              RiungGlassHeader(title: t.crisisScreenTitle),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xl),
                  children: [
                    SizedBox(
                      height: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 160,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)]),
                            ),
                          ),
                          const RiungIcon3D(RiungIcon.bantuan, size: 130),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(t.crisisIntro, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.55, fontWeight: FontWeight.w500, color: AppColors.teksUtama)),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.aksenHangatLembut, AppColors.aksenHangatMuda]),
                        border: Border.all(color: AppColors.aksenHangat.withValues(alpha: 0.5), width: AppGlass.edgeWidth),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.crisisEmergencyLabel, style: AppTextStyles.caption.copyWith(color: AppColors.aksenHangatGelap, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.5)),
                          const SizedBox(height: 8),
                          Text(t.crisisMinistry, style: AppTextStyles.title.copyWith(fontSize: 18)),
                          const SizedBox(height: AppSpacing.md),
                          Material(
                            color: AppColors.aksenHangatGelap,
                            shape: const StadiumBorder(),
                            child: InkWell(
                              customBorder: const StadiumBorder(),
                              onTap: () => _telepon('1198'),
                              child: SizedBox(
                                height: 54,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 18, color: AppColors.diAtasTinta),
                                    const SizedBox(width: 8),
                                    Text(t.crisisCallButton, style: AppTextStyles.buttonLabel.copyWith(fontSize: 16, color: AppColors.diAtasTinta)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final line in _lines(context)) ...[
                      _CrisisRow(line: line, onTap: () => line.tel != null ? _telepon(line.tel!) : _bukaUrl(line.url!)),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: AppColors.primerLembut.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(18)),
                      child: Row(
                        children: [
                          const Icon(Icons.visibility_off_outlined, size: 16, color: AppColors.primer),
                          const SizedBox(width: 10),
                          Expanded(child: Text(t.crisisPrivacyNote, style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.primer))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrisisRow extends StatelessWidget {
  const _CrisisRow({required this.line, required this.onTap});

  final _CrisisLine line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RiungGlassCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama)),
                const SizedBox(height: 2),
                Text(line.sub, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.teksSekunder)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.permukaanPadat.withValues(alpha: 0.8),
                border: Border.all(color: AppColors.garis),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(line.icon, size: 14, color: AppColors.teksUtama),
                  const SizedBox(width: 6),
                  Text(line.action, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
