import 'package:flutter_test/flutter_test.dart';
import 'package:riung/core/services/device_time_zone.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('zona terdeteksi selalu lokasi IANA yang valid dengan offset perangkat', () {
    final zone = DeviceTimeZone.detect();
    final location = tz.getLocation(zone);
    final now = DateTime.now();
    expect(location.timeZone(now.toUtc().millisecondsSinceEpoch).offset.inMinutes, now.timeZoneOffset.inMinutes);
  });
}
