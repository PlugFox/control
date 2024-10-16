// ignore_for_file: unnecessary_lambdas

import 'package:flutter_test/flutter_test.dart';

import 'unit/handler_context_test.dart' as handler_context_test;
import 'unit/state_controller_test.dart' as state_controller_test;
import 'widget/controller_scope_test.dart' as state_scope_test;
import 'widget/state_consumer_test.dart' as state_consumer_test;

void main() {
  group('unit', () {
    state_controller_test.main();
    handler_context_test.main();
  });

  group('widget', () {
    state_scope_test.main();
    state_consumer_test.main();
  });
}
