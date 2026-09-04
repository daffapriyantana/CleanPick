import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/auth_local_datasource.dart';
import 'data/datasources/order_local_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/order_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/order_repository.dart';
import 'domain/usecases/cancel_order.dart';
import 'domain/usecases/create_order.dart';
import 'domain/usecases/get_order_detail.dart';
import 'domain/usecases/get_orders.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/pay_order.dart';
import 'domain/usecases/register_usecase.dart';
import 'presentation/bloc/auth/auth_cubit.dart';
import 'presentation/bloc/order/order_cubit.dart';
import 'presentation/pages/splash_page.dart';

/// Manual, lightweight dependency injection. A dedicated container
/// (get_it, injectable, riverpod, ...) would work equally well here;
/// for a milestone-scoped project a plain composition root keeps the
/// wiring easy to read top-to-bottom: datasource -> repository ->
/// use case -> cubit.
class AppDependencies {
  final OrderRepository orderRepository;
  final AuthRepository authRepository;

  AppDependencies._(
      {required this.orderRepository, required this.authRepository});

  factory AppDependencies.build() {
    final orderDataSource = OrderLocalDataSourceImpl();
    final authDataSource = AuthLocalDataSourceImpl();

    final orderRepository = OrderRepositoryImpl(dataSource: orderDataSource);
    final authRepository = AuthRepositoryImpl(dataSource: authDataSource);

    return AppDependencies._(
        orderRepository: orderRepository, authRepository: authRepository);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(CleanPickApp(dependencies: AppDependencies.build()));
}

class CleanPickApp extends StatelessWidget {
  final AppDependencies dependencies;
  const CleanPickApp({super.key, required this.dependencies});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(
            loginUseCase: LoginUseCase(dependencies.authRepository),
            loginPetugasUseCase:
                LoginPetugasUseCase(dependencies.authRepository),
            registerUseCase: RegisterUseCase(dependencies.authRepository),
          ),
        ),
        BlocProvider<OrderCubit>(
          create: (_) => OrderCubit(
            getOrders: GetOrders(dependencies.orderRepository),
            getOrderDetail: GetOrderDetail(dependencies.orderRepository),
            createOrder: CreateOrder(dependencies.orderRepository),
            cancelOrder: CancelOrder(dependencies.orderRepository),
            payOrder: PayOrder(dependencies.orderRepository),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'CleanPick',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashPage(),
      ),
    );
  }
}
