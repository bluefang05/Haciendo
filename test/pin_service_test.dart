import 'package:flutter_test/flutter_test.dart';
import 'package:haciendo/data/services/pin_service.dart';

void main() {
  const service = PinService();

  test('PIN hash is stable per project', () {
    final first = service.hashPin('project-a', '123456');
    final second = service.hashPin('project-a', '123456');
    expect(first, second);
    expect(service.verify(projectId: 'project-a', pin: '123456', storedHash: first), isTrue);
  });

  test('same PIN has a different hash in another project', () {
    expect(
      service.hashPin('project-a', '1234'),
      isNot(service.hashPin('project-b', '1234')),
    );
  });

  test('rejects invalid PIN', () {
    expect(() => service.hashPin('project', '12ab'), throwsFormatException);
  });
}
