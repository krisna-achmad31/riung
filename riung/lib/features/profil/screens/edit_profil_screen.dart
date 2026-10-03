import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/avatar_catalog.dart';

/// Ganti nama & avatar. Layar ini tidak ada mockup terpisah di
/// `design/Profil.dc.html` (cuma dirujuk lewat baris "Ganti nama" di
/// Pengaturan) — dibangun mengikuti bahasa visual layar Profil/Pengaturan
/// yang sudah ada (kartu gelap, tombol RiungButton, dsb).
class EditProfilScreen extends StatefulWidget {
  const EditProfilScreen({super.key});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  late final TextEditingController _namaController;
  late String _avatarId;
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    final profile = AppScope.of(context).auth.profile;
    _namaController = TextEditingController(text: profile?.displayName ?? '');
    _avatarId = profile?.avatarId ?? AvatarCatalog.all.first.id;
  }

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final nama = _namaController.text.trim();
    if (nama.isEmpty) return;
    setState(() => _menyimpan = true);
    await AppScope.of(context).auth.updateProfile(
          (current) => current.copyWith(displayName: nama, avatarId: _avatarId),
        );
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.profil;
    final inisial = _namaController.text.trim().isEmpty ? '?' : _namaController.text.trim()[0].toUpperCase();
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
                  Text(t.editTitle, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: AvatarCatalog.byId(_avatarId).colors),
                      ),
                      alignment: Alignment.center,
                      child: Text(inisial, style: AppTextStyles.display.copyWith(fontSize: 32, color: AppColors.latar)),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _namaController,
                      onChanged: (_) => setState(() {}),
                      style: AppTextStyles.body.copyWith(color: AppColors.teksUtama, fontSize: 15),
                      decoration: InputDecoration(
                        labelText: t.nicknameLabel,
                        labelStyle: AppTextStyles.caption,
                        filled: true,
                        fillColor: AppColors.permukaan,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.garis)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.garis)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: const BorderSide(color: AppColors.primer)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(t.pickAvatar, style: AppTextStyles.chipLabel.copyWith(fontSize: 14)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        for (final avatar in AvatarCatalog.all)
                          GestureDetector(
                            onTap: () => setState(() => _avatarId = avatar.id),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: avatar.colors),
                                border: _avatarId == avatar.id ? Border.all(color: AppColors.teksUtama, width: 2.5) : null,
                              ),
                              alignment: Alignment.center,
                              child: _avatarId == avatar.id ? const Icon(Icons.check, color: AppColors.latar) : null,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.lg),
              child: RiungButton(
                label: _menyimpan ? t.saving : context.s.common.simpan,
                onPressed: _menyimpan || _namaController.text.trim().isEmpty ? null : _simpan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
