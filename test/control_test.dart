// ignore_for_file: unnecessary_lambdas

import 'package:flutter_test/flutter_test.dart';

import 'widget/state_scope_test.dart' as state_scope_test;

void main() {
  group('unit', () {
    test('placeholder', () {
      expect(true, isTrue);
    });
  });
  group('widget', () {
    state_scope_test.main();
  });
}
