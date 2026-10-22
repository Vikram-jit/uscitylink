import 'package:flutter_test/flutter_test.dart';
import 'package:uscitylink/utils/roles.dart';

void main() {
  test('admin counts as staff, drivers and others do not', () {
    expect(isStaffRole('staff'), isTrue);
    expect(isStaffRole('admin'), isTrue);
    expect(isStaffRole('Staff'), isTrue); // stored/typed with a capital before
    expect(isStaffRole(' ADMIN '), isTrue);
    expect(isStaffRole('driver'), isFalse);
    expect(isStaffRole('security'), isFalse);
    expect(isStaffRole(''), isFalse);
    expect(isStaffRole(null), isFalse);
  });
}
