import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:redmaestra1/core/services/hive_encryption_service.dart';

void main() {
  late Directory dir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    HiveEncryptionService.instance.resetForTest();
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
        await HiveEncryptionService.instance.openBox<String>(boxName);
    expect(encrypted.get('user'), 'ana');
    await encrypted.close();
  });

  test('guarda y relee resultados de cuestionario con la misma clave', () async {
    final boxName = '${HiveEncryptionService.quizResultsBox}_test2';
    final box = await HiveEncryptionService.instance.openBox<String>(boxName);
    await box.put('score', '9');
    await box.close();

    HiveEncryptionService.instance.resetForTest();
    final again =
        await HiveEncryptionService.instance.openBox<String>(boxName);
    expect(again.get('score'), '9');
  });
}
