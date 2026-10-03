/// Prompt CBT jurnal — panduan menulis terarah, satu per monster. Statis
/// (bukan dari [ContentRepository]) karena `docs/dummy-data-seed.json`
/// belum punya konten prompt jurnal tersendiri; nama monster & warna tetap
/// diambil dari [Saboteur] lewat `monsterId`. Judul, subjudul, dan
/// pertanyaan panduan ada di `JurnalStrings.prompt(id)` (per bahasa).
class JournalPrompt {
  const JournalPrompt({required this.id, required this.monsterId});

  final String id;
  final String monsterId;
}

const journalPrompts = <JournalPrompt>[
  JournalPrompt(
    id: 'p_hakim',
    monsterId: 'hakim',
  ),
  JournalPrompt(
    id: 'p_kabut',
    monsterId: 'kabut',
  ),
  JournalPrompt(
    id: 'p_cermin',
    monsterId: 'cermin',
  ),
  JournalPrompt(
    id: 'p_waswas',
    monsterId: 'waswas',
  ),
  JournalPrompt(
    id: 'p_mengelak',
    monsterId: 'mengelak',
  ),
];
