import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../logic/character_accessory.dart';
import '../logic/character_spec.dart';
import '../screens/kepribadian_hasil_screen.dart';
import '../screens/kepribadian_hub_screen.dart';
import '../screens/kepribadian_quiz_screen.dart';
import 'character_avatar.dart';

/// Kartu "Karaktermu" di Beranda: monster yang sedang dijinakkan (beserta
/// progresnya) dan tiga karakter hasil tes (tipe gaya Jung, temperamen,
/// gaya keterikatan) yang sedang dipakai. Tes yang belum diisi menampilkan
/// ajakan lembut untuk mengisinya.
class KarakterHomeCard extends StatefulWidget {
  const KarakterHomeCard({super.key});

  @override
  State<KarakterHomeCard> createState() => _KarakterHomeCardState();
}

class _KarakterHomeCardState extends State<KarakterHomeCard> {
  Future<void> _buka(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() {}); // hasil/aksesori mungkin berubah
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.kepribadian;
    return ValueListenableBuilder<int>(
      valueListenable: scope.prefs.personalityRevision,
      builder: (context, _, _) {
        final results = scope.prefs.personalityResults;
        final loadout = AccessoryLoadout(scope.prefs);
        return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppGlass.card(radius: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _buka(const KepribadianHubScreen()),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Expanded(child: Text(t.homeTitle, style: AppTextStyles.title.copyWith(fontSize: 18, color: AppColors.teksUtama))),
                Text(t.homeSeeAll, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.primer, fontWeight: FontWeight.w700)),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.primer),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              for (final test in PersonalityTest.values) ...[
                Expanded(
                  child: _CharacterTile(
                    test: test,
                    result: results[test],
                    accessories: loadout.of(test),
                    onTap: () => _buka(results[test] != null ? KepribadianHasilScreen(result: results[test]!) : KepribadianQuizScreen(test: test)),
                  ),
                ),
                if (test != PersonalityTest.values.last) const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ],
      ),
        );
      },
    );
  }
}

class _CharacterTile extends StatelessWidget {
  const _CharacterTile({required this.test, required this.result, required this.accessories, required this.onTap});

  final PersonalityTest test;
  final PersonalityResult? result;
  final List<CharacterAccessory> accessories;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.s.kepribadian;
    final r = result;
    String value;
    Color? color;
    if (r == null) {
      value = t.homeTakeTest;
    } else {
      switch (test) {
        case PersonalityTest.jung:
          value = r.code;
        case PersonalityTest.temperament:
          value = t.temperament(r.code).name;
        case PersonalityTest.attachment:
          value = t.attachment(r.code).name;
      }
      color = CharacterSpec.fromResult(r).base;
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: r == null
                ? Container(
                    decoration: BoxDecoration(color: AppColors.permukaan, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.add_rounded, size: 26, color: AppColors.teksRedup),
                  )
                : CharacterAvatar(spec: CharacterSpec.fromResult(r), size: 64, accessories: accessories),
          ),
          const SizedBox(height: 4),
          Text(t.homeTestShort(test), style: AppTextStyles.caption.copyWith(fontSize: 10)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.chipLabel.copyWith(fontSize: 12, color: color ?? AppColors.primer),
          ),
        ],
      ),
    );
  }
}
