import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/payment_checkout.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentDataSource dataSource;
  const PaymentRepositoryImpl({required this.dataSource});

  @override
  Future<PaymentCheckout> createCheckout(String orderId) async {
    try {
      return await dataSource.createCheckout(orderId);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    }
  }
}
