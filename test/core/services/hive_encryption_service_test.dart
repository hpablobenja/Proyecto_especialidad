import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:redmaestra1/core/services/hive_encryption_service.dart';
import 'package:redmaestra1/core/services/crashlytics_service.dart';

import 'hive_encryption_service_test.mocks.dart';

@GenerateMocks([CrashlyticsService])
void main() {
  late Directory dir;
  late HiveEncryptionService encryptionService;
  late MockCrashlyticsService mockCrashlyticsService;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    mockCrashlyticsService = MockCrashlyticsService();
    encryptionService = HiveEncryptionService.forTesting(
      crashlyticsService: mockCrashlyticsService,
    );
    encryptionService.resetForTest();
    dir = await Directory.systemTemp.createTemp('hive_aes_');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });

  test('migra una caja en claro a AES-256 y conserva los datos', () async {
    final boxName = '${HiveEncryptionService.userDataBox}_test1';
    final plain = await Hive.openBox<String>(boxName);
    await plain.put('user', 'ana');
    await plain.close();

    final encrypted =
        await encryptionService.openBox<String>(boxName);
    expect(encrypted.get('user'), 'ana');
    await encrypted.close();
  });

  test('guarda y relee resultados de cuestionario con la misma clave', () async {
    final boxName = '${HiveEncryptionService.quizResultsBox}_test2';
    final box = await encryptionService.openBox<String>(boxName);
    await box.put('score', '9');
    await box.close();

    encryptionService.resetForTest();
    final again =
        await encryptionService.openBox<String>(boxName);
    expect(again.get('score'), '9');
  });
}
