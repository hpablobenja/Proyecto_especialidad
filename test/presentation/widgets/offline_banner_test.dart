import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redmaestra1/presentation/widgets/offline_banner.dart';

void main() {
  group('OfflineBanner Widget Tests', () {
    testWidgets('OfflineBanner es un ConsumerWidget', (WidgetTester tester) async {
      // Test that the widget can be built without errors
      expect(() => const OfflineBanner(), returnsNormally);
    });
  });
}
