/// Tipe latihan tiap sesi — dipakai buat label kecil di kartu & layar
/// detail (label per bahasa: `BettermeStrings.typeLabel(tipe.name)`). Bukan
/// mengubah konten, cuma menandai pendekatannya.
enum BetterMeSessionType { psikoedukasi, latihan, restrukturisasi, aktivasiPerilaku }

class BetterMeSession {
  const BetterMeSession({
    required this.id,
    required this.level,
    required this.tipe,
    required this.estimasiMenit,
  });

  final String id;
  final int level;
  final BetterMeSessionType tipe;
  final int estimasiMenit;
}

class BetterMeLevel {
  const BetterMeLevel({required this.number, required this.sessions});

  final int number;
  final List<BetterMeSession> sessions;
}

/// Struktur Better Me — 22 sesi, 3 level. Teks (judul, isi, pertanyaan
/// refleksi) ada di `BettermeStrings` per bahasa. Tone: teman yang
/// menemani, bukan modul kursus. CLAUDE.md M6: tanpa em-dash, sapaan "kamu".
final List<BetterMeLevel> betterMeLevels = [
  BetterMeLevel(
    number: 1,
    sessions: [
      const BetterMeSession(
        id: 'l1_s1',
        level: 1,
        tipe: BetterMeSessionType.psikoedukasi,
        estimasiMenit: 4,
      ),
      const BetterMeSession(
        id: 'l1_s2',
        level: 1,
        tipe: BetterMeSessionType.latihan,
        estimasiMenit: 5,
      ),
      const BetterMeSession(
        id: 'l1_s3',
        level: 1,
        tipe: BetterMeSessionType.latihan,
        estimasiMenit: 5,
      ),
      const BetterMeSession(
        id: 'l1_s4',
        level: 1,
        tipe: BetterMeSessionType.restrukturisasi,
        estimasiMenit: 6,
      ),
      const BetterMeSession(
        id: 'l1_s5',
        level: 1,
        tipe: BetterMeSessionType.restrukturisasi,
        estimasiMenit: 6,
      ),
      const BetterMeSession(
        id: 'l1_s6',
        level: 1,
        tipe: BetterMeSessionType.latihan,
        estimasiMenit: 5,
      ),
      const BetterMeSession(
        id: 'l1_s7',
        level: 1,
        tipe: BetterMeSessionType.latihan,
        estimasiMenit: 4,
      ),
    ],
  ),
  BetterMeLevel(
    number: 2,
    sessions: [
      const BetterMeSession(
        id: 'l2_s1',
        level: 2,
        tipe: BetterMeSessionType.restrukturisasi,
        estimasiMenit: 6,
      ),
      const BetterMeSession(
        id: 'l2_s2',
        level: 2,
        tipe: BetterMeSessionType.aktivasiPerilaku,
        estimasiMenit: 5,
      ),
      const BetterMeSession(
        id: 'l2_s3',
        level: 2,
        tipe: BetterMeSessionType.latihan,
        estimasiMenit: 5,
      ),
      const BetterMeSession(
        id: 'l2_s4',
        level: 2,
        tipe: BetterMeSessionType.latihan,
        estimasiMenit: 4,
      ),
      const BetterMeSession(
        id: 'l2_s5',
        level: 2,
        tipe: BetterMeSessionType.psikoedukasi,
        estimasiMenit: 4,
      ),
      const BetterMeSession(
        id: 'l2_s6',
        level: 2,
        tipe: BetterMeSessionType.restrukturisasi,
        estimasiMenit: 6,
      ),
      const BetterMeSession(
        id: 'l2_s7',
        level: 2,
        tipe: BetterMeSessionType.latihan,
        estimasiMenit: 4,
      ),
    ],
  ),
  BetterMeLevel(
    number: 3,
    sessions: [
      const BetterMeSession(
        id: 'l3_s1',
        level: 3,
        tipe: BetterMeSessionType.psikoedukasi,
        estimasiMenit: 5,
      ),
      const BetterMeSession(
        id: 'l3_s2',
        level: 3,
        tipe: BetterMeSessionType.latihan,
        estimasiMenit: 6,
      ),
      const BetterMeSession(
        id: 'l3_s3',
        level: 3,
        tipe: BetterMeSessionType.latihan,
        estimasiMenit: 6,
      ),
      const BetterMeSession(
        id: 'l3_s4',
        level: 3,
        tipe: BetterMeSessionType.latihan,
        estimasiMenit: 5,
      ),
      const BetterMeSession(
        id: 'l3_s5',
        level: 3,
        tipe: BetterMeSessionType.psikoedukasi,
        estimasiMenit: 5,
      ),
      const BetterMeSession(
        id: 'l3_s6',
        level: 3,
        tipe: BetterMeSessionType.restrukturisasi,
        estimasiMenit: 5,
      ),
      const BetterMeSession(
        id: 'l3_s7',
        level: 3,
        tipe: BetterMeSessionType.latihan,
        estimasiMenit: 7,
      ),
      const BetterMeSession(
        id: 'l3_s8',
        level: 3,
        tipe: BetterMeSessionType.psikoedukasi,
        estimasiMenit: 4,
      ),
    ],
  ),
];

BetterMeSession? betterMeSessionById(String id) {
  for (final level in betterMeLevels) {
    for (final session in level.sessions) {
      if (session.id == id) return session;
    }
  }
  return null;
}

int get betterMeTotalSessions => betterMeLevels.fold(0, (sum, l) => sum + l.sessions.length);
