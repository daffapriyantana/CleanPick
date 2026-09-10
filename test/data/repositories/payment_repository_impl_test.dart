import 'package:flutter_test/flutter_test.dart';
import 'package:cleanpick/core/error/exceptions.dart';
import 'package:cleanpick/core/error/failures.dart';
import 'package:cleanpick/data/datasources/payment_datasource.dart';
import 'package:cleanpick/data/repositories/payment_repository_impl.dart';
import 'package:cleanpick/domain/entities/payment_checkout.dart';

class _FakePaymentDataSource implements PaymentDataSource {
  bool shouldThrow = false;

  @override
  Future<PaymentCheckout> createCheckout(String orderId) async {
    if (shouldThrow) throw const ServerException('backend unavailable');
    return PaymentCheckout(
      orderId: orderId,
      snapToken: 'sandbox-token',
      redirectUrl:
          'https://app.sandbox.midtrans.com/snap/v2/vtweb/sandbox-token',
    );
  }
}

void main() {
  late _FakePaymentDataSource dataSource;
  late PaymentRepositoryImpl repository;

  setUp(() {
    dataSource = _FakePaymentDataSource();
    repository = PaymentRepositoryImpl(dataSource: dataSource);
  });

  test('meneruskan order ID dan mengembalikan checkout dari backend', () async {
    final checkout = await repository.createCheckout('CP-001');

    expect(checkout.orderId, 'CP-001');
    expect(checkout.snapToken, 'sandbox-token');
  });

  test('menerjemahkan error datasource menjadi ServerFailure', () async {
    dataSource.shouldThrow = true;

    expect(
      () => repository.createCheckout('CP-001'),
      throwsA(isA<ServerFailure>()),
    );
  });
}
