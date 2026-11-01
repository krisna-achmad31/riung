import 'package:flutter_test/flutter_test.dart';
import 'package:riung/core/config/app_data.dart';

void main() {
  test('default memakai live', () {
    expect(AppData.resolveMode(modeOverride: '', isRelease: false), AppMode.live);
    expect(AppData.baseUrl, AppData.baseUrlProd);
  });

  test('dev hanya berlaku di luar build rilis', () {
    expect(AppData.resolveMode(modeOverride: 'dev', isRelease: false), AppMode.dev);
    expect(AppData.resolveMode(modeOverride: 'dev', isRelease: true), AppMode.live);
  });
}
