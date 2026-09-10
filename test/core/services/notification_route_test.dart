import 'package:flutter_test/flutter_test.dart';

import 'package:cleanpick/core/services/notification_service.dart';

void main() {
  test('notification route preserves type and order id', () {
    final route = NotificationRoute.fromData({
      'type': 'order_taken',
      'orderId': 'CP-99C8C6E4',
    });

    expect(route.type, 'order_taken');
    expect(route.orderId, 'CP-99C8C6E4');
    expect(route.toData(), {'type': 'order_taken', 'orderId': 'CP-99C8C6E4'});
  });

  test('notification route ignores missing order id safely', () {
    final route = NotificationRoute.fromData({'type': 'new_order'});

    expect(route.type, 'new_order');
    expect(route.orderId, isNull);
    expect(route.toData(), {'type': 'new_order'});
  });
}
