import 'dart:async';
import 'package:control/src/util/linked_mutex.dart';

void main() async {
  final mutex = LinkedMutex();
  var counter = 0;
  
  print('Starting race condition test...');
  
  // Запускаем 1000 конкурентных задач
  final futures = List.generate(1000, (i) {
    return mutex.synchronize(() async {
      final value = counter;
      // Имитируем асинхронную работу
      await Future<void>.delayed(Duration.zero);
      counter = value + 1;
    });
  });
  
  await Future.wait(futures);
  
  print('Expected: 1000');
  print('Actual: $counter');
  print('Mutex locked: ${mutex.locked}');
  
  if (counter != 1000) {
    print('❌ RACE CONDITION DETECTED!');
  } else {
    print('✅ Test passed');
  }
}
