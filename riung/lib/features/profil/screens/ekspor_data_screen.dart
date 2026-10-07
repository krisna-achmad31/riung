import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/services.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// "Unduh semua dataku" — bukan mockup terpisah di desain (dirujuk lewat
/// baris di Pengaturan). Isi data disusun [DataExportBuilder]; isi jurnal
/// SENGAJA tidak disertakan (terenkripsi di perangkat, CLAUDE.md aturan #5).
class EksporDataScreen extends StatefulWidget {
  const EksporDataScreen({super.key});

  @override
  State<EksporDataScreen> createState() => _EksporDataScreenState();
}

class _EksporDataScreenState extends State<EksporDataScreen> {
  String? _json;

  @override
  void initState() {
    super.initState();
    _susun();
  }

  Future<void> _susun() async {
    final scope = AppScope.of(context);
    final uid = scope.auth.uid;
    if (uid == null) return;
    final data = await DataExportBuilder(userRepository: scope.userRepository, prefs: scope.prefs)
        .build(uid: uid, note: AppStrings.of(scope.language.language).profil.exportNote);
    if (!mounted) return;
    setState(() => _json = const JsonEncoder.withIndent('  ').convert(data));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.profil;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              RiungGlassHeader(title: t.downloadData),
              Expanded(
                child: _json == null
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primer))
                    : RiungBleedListView(
                        padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
                        children: [
                          Text(t.exportIntro, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.tinta.withValues(alpha: 0.9),
                              border: Border.all(color: AppColors.diAtasTinta.withValues(alpha: 0.2), width: AppGlass.edgeWidth),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: SelectableText(
                              _json!,
                              style: AppTextStyles.caption.copyWith(fontSize: 12, fontFamily: 'monospace', height: 1.6, color: AppColors.diAtasTinta.withValues(alpha: 0.88)),
                            ),
                          ),
                        ],
                      ),
              ),
              if (_json != null) ...[
                const SizedBox(height: AppSpacing.sm),
                RiungButton(
                  label: t.exportCopy,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _json!));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.exportCopied)));
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
