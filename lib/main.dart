import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/firebase_auth_datasource.dart';
import 'data/datasources/order_local_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/order_repository_impl.dart';
import 'data/services/offline_sync_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/order_repository.dart';
import 'domain/usecases/cancel_order.dart';
import 'domain/usecases/create_order.dart';
import 'domain/usecases/complete_order.dart';
import 'domain/usecases/assign_order.dart';
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
  final OfflineSyncService offlineSyncService;

  AppDependencies._(
      {required this.orderRepository,
      required this.authRepository,
      required this.offlineSyncService});

  static Future<AppDependencies> build() async {
    final preferences = await SharedPreferences.getInstance();
    final orderDataSource = OrderLocalDataSourceImpl(preferences: preferences);
    final authDataSource = FirebaseAuthDataSource();
    await authDataSource.initialize();

    final offlineSyncService =
        OfflineSyncService(orderDataSource: orderDataSource);
    await offlineSyncService.start();

    final orderRepository = OrderRepositoryImpl(dataSource: orderDataSource);
    final authRepository = AuthRepositoryImpl(dataSource: authDataSource);

    return AppDependencies._(
        orderRepository: orderRepository,
        authRepository: authRepository,
        offlineSyncService: offlineSyncService);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('id_ID', null);

  runApp(
    CleanPickApp(
      dependencies: await AppDependencies.build(),
    ),
  );
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
            resetPasswordUseCase:
                ResetPasswordUseCase(dependencies.authRepository),
          ),
        ),
        BlocProvider<OrderCubit>(
          create: (_) => OrderCubit(
            getOrders: GetOrders(dependencies.orderRepository),
            getOrderDetail: GetOrderDetail(dependencies.orderRepository),
            createOrder: CreateOrder(dependencies.orderRepository),
            assignOrder: AssignOrder(dependencies.orderRepository),
            cancelOrder: CancelOrder(dependencies.orderRepository),
            payOrder: PayOrder(dependencies.orderRepository),
            completeOrder: CompleteOrder(dependencies.orderRepository),
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
