import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';

class _CrisisLine {
  const _CrisisLine({required this.name, required this.sub, required this.action, this.url, this.tel});
  final String name;
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
      _CrisisLine(name: 'SEJIWA', sub: t.sejiwaSub, action: t.actionCall, tel: '1198'),
      _CrisisLine(name: 'Into The Light Indonesia', sub: t.intoTheLightSub, action: t.actionOpenSite, url: 'https://intothelightid.org'),
      _CrisisLine(name: 'IPK Indonesia', sub: t.ipkSub, action: t.actionSearch, url: 'https://ipkindonesia.or.id'),
    ];
  }

  Future<void> _telepon(String nomor) => launchUrl(Uri(scheme: 'tel', path: nomor));

  Future<void> _bukaUrl(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final t = context.s.profil;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.teksSekunder),
                  ),
                  Text(t.crisisScreenTitle, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.crisisIntro,
                      style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.6),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 1.5),
                        borderRadius: BorderRadius.circular(AppRadius.xxl),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.crisisEmergencyLabel, style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.6)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(t.crisisMinistry, style: AppTextStyles.title.copyWith(fontSize: 16)),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: 52,
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _telepon('1198'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: AppColors.latar,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.call_rounded, size: 18),
                              label: Text(t.crisisCallButton, style: AppTextStyles.buttonLabel.copyWith(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (final line in _lines(context)) ...[
                      _CrisisRow(
                        line: line,
                        onTap: () => line.tel != null ? _telepon(line.tel!) : _bukaUrl(line.url!),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.permukaan,
                        border: Border.all(color: AppColors.garis),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lock_rounded, size: 16, color: AppColors.sukses),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              t.crisisPrivacyNote,
                              style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name, style: AppTextStyles.chipLabel.copyWith(fontSize: 13)),
                const SizedBox(height: 2),
                Text(line.sub, style: AppTextStyles.caption.copyWith(fontSize: 11)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(border: Border.all(color: AppColors.garis), borderRadius: BorderRadius.circular(11)),
              child: Text(line.action, style: AppTextStyles.chipLabel.copyWith(color: AppColors.primer, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
