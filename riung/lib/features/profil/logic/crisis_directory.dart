/// Satu layanan krisis nasional. [tel] = yang didial, [number] = yang tampil.
class CrisisContact {
  const CrisisContact({required this.country, required this.name, required this.tel, required this.number});

  /// Nama negara dalam bahasa setempat, supaya mudah dikenali di pemilih.
  final String country;
  final String name;
  final String tel;
  final String number;
}

/// Data bawaan app supaya tetap tersedia offline. Tiap nomor wajib dicek ulang
/// berkala ke situs resmi layanannya. Negara di luar daftar memakai cadangan
/// nomor darurat setempat, bukan nomor negara lain.
abstract final class CrisisDirectory {
  static const indonesia = 'ID';
  static const findAHelplineUrl = 'https://findahelpline.com';

  /// Nama lain untuk pencarian (Indonesia/Inggris), di luar [CrisisContact.country].
  static const Map<String, String> searchNames = {
    'US': 'amerika serikat usa',
    'GB': 'inggris britania uk england',
    'NZ': 'selandia baru',
    'IE': 'irlandia',
    'PH': 'filipina',
    'JP': 'jepang japan',
    'KR': 'korea selatan south korea',
    'DE': 'jerman germany',
    'FR': 'prancis perancis',
    'ES': 'spanyol spain',
    'IT': 'italy',
    'NL': 'belanda netherlands',
    'BR': 'brazil',
    'MX': 'meksiko mexico',
    'SG': 'singapura',
  };

  static bool matches(String code, String query) {
    final q = query.trim().toLowerCase();
    final names = '${contacts[code]?.country ?? ''} ${searchNames[code] ?? ''}'.toLowerCase();
    return names.contains(q);
  }

  static const Map<String, CrisisContact> contacts = {
    indonesia: CrisisContact(country: 'Indonesia', name: 'Kemenkes', tel: '119,8', number: '119 ext. 8'),
    'US': CrisisContact(country: 'United States', name: '988 Suicide & Crisis Lifeline', tel: '988', number: '988'),
    'GB': CrisisContact(country: 'United Kingdom', name: 'Samaritans', tel: '116123', number: '116 123'),
    'CA': CrisisContact(country: 'Canada', name: '9-8-8 Suicide Crisis Helpline', tel: '988', number: '988'),
    'AU': CrisisContact(country: 'Australia', name: 'Lifeline', tel: '131114', number: '13 11 14'),
    'NZ': CrisisContact(country: 'New Zealand', name: '1737 Need to Talk?', tel: '1737', number: '1737'),
    'IE': CrisisContact(country: 'Ireland', name: 'Samaritans', tel: '116123', number: '116 123'),
    'IN': CrisisContact(country: 'India', name: 'Tele-MANAS', tel: '14416', number: '14416'),
    'PH': CrisisContact(country: 'Philippines', name: 'NCMH Crisis Hotline', tel: '1553', number: '1553'),
    'MY': CrisisContact(country: 'Malaysia', name: 'Talian HEAL', tel: '15555', number: '15555'),
    'SG': CrisisContact(country: 'Singapore', name: 'Samaritans of Singapore', tel: '1767', number: '1767'),
    'JP': CrisisContact(country: '日本', name: '#いのちSOS', tel: '0120061338', number: '0120 061 338'),
    'KR': CrisisContact(country: '대한민국', name: '자살예방 상담전화', tel: '109', number: '109'),
    'DE': CrisisContact(country: 'Deutschland', name: 'TelefonSeelsorge', tel: '116123', number: '116 123'),
    'FR': CrisisContact(country: 'France', name: 'Numéro national de prévention du suicide', tel: '3114', number: '3114'),
    'ES': CrisisContact(country: 'España', name: 'Línea 024', tel: '024', number: '024'),
    'IT': CrisisContact(country: 'Italia', name: 'Telefono Amico', tel: '0299777', number: '02 99777'),
    'NL': CrisisContact(country: 'Nederland', name: '113 Zelfmoordpreventie', tel: '113', number: '113'),
    'BR': CrisisContact(country: 'Brasil', name: 'CVV', tel: '188', number: '188'),
    'MX': CrisisContact(country: 'México', name: 'SAPTEL', tel: '5552598121', number: '55 5259 8121'),
  };
}
