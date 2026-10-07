import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/avatar_catalog.dart';
import '../widgets/profil_avatar.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
          child: Column(
            children: [
              RiungGlassHeader(title: t.editTitle),
              Expanded(
                child: RiungBleedListView(
                  padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.md),
                  children: [
                    Center(child: ProfilAvatar(avatar: AvatarCatalog.byId(_avatarId), size: 130)),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      decoration: BoxDecoration(
                        color: AppColors.permukaan,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.nicknameLabel, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.teksRedup)),
                          TextField(
                            controller: _namaController,
                            onChanged: (_) => setState(() {}),
                            cursorColor: AppColors.primer,
                            style: AppTextStyles.chipLabel.copyWith(fontSize: 16, color: AppColors.teksUtama),
                            decoration: const InputDecoration(
                              isDense: true,
                              filled: false,
                              contentPadding: EdgeInsets.symmetric(vertical: 6),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(t.pickAvatar, style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama)),
                    const SizedBox(height: AppSpacing.md),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 109 / 96,
                      children: [
                        for (final avatar in AvatarCatalog.all)
                          _AvatarOptionTile(avatar: avatar, selected: _avatarId == avatar.id, onTap: () => setState(() => _avatarId = avatar.id)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              RiungButton(
                label: _menyimpan ? t.saving : context.s.common.simpan,
                onPressed: _menyimpan || _namaController.text.trim().isEmpty ? null : _simpan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opsi avatar (frame `Opsi avatar`): kartu kaca, bingkai primer saat dipilih.
class _AvatarOptionTile extends StatelessWidget {
  const _AvatarOptionTile({required this.avatar, required this.selected, required this.onTap});

  final AvatarOption avatar;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? AppColors.permukaanPadat.withValues(alpha: 0.9) : AppColors.kartu,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: selected ? AppColors.primer : AppColors.garis, width: selected ? 2.5 : AppGlass.edgeWidth),
        ),
        alignment: Alignment.center,
        child: RiungMonster(monsterId: avatar.monsterId, state: MonsterVisualState.jinak, size: 76, applyBossScale: false),
      ),
    );
  }
}
