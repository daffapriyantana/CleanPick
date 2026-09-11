import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'core/theme/app_theme.dart';
import 'data/datasources/firebase_auth_datasource.dart';
import 'data/datasources/firebase_order_datasource.dart';
import 'data/datasources/payment_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/order_repository_impl.dart';
import 'data/repositories/payment_repository_impl.dart';
import 'data/services/firebase_order_sync_service.dart';
import 'core/services/notification_service.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/order_repository.dart';
import 'domain/repositories/payment_repository.dart';
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
import 'presentation/pages/home_page.dart';
import 'presentation/pages/order_detail_page.dart';
import 'presentation/pages/petugas_dashboard_page.dart';

/// Manual, lightweight dependency injection. A dedicated container
/// (get_it, injectable, riverpod, ...) would work equally well here;
/// for a milestone-scoped project a plain composition root keeps the
/// wiring easy to read top-to-bottom: datasource -> repository ->
/// use case -> cubit.
class AppDependencies {
  final OrderRepository orderRepository;
  final PaymentRepository paymentRepository;
  final AuthRepository authRepository;
  final FirebaseOrderSyncService orderSyncService;
  final NotificationService notificationService;

  AppDependencies._({
    required this.orderRepository,
    required this.paymentRepository,
    required this.authRepository,
    required this.orderSyncService,
    required this.notificationService,
  });

  static Future<AppDependencies> build() async {
    final orderDataSource = FirebaseOrderDataSource();
    final orderSyncService = FirebaseOrderSyncService(
      dataSource: orderDataSource,
    );
    final authDataSource = FirebaseAuthDataSource();
    await authDataSource.initialize();
    final notificationService = NotificationService();
    if (authDataSource.currentUser != null) {
      await notificationService.initialize();
    }
    await orderSyncService.start();

    final orderRepository = OrderRepositoryImpl(dataSource: orderDataSource);
    final paymentRepository = PaymentRepositoryImpl(
      dataSource: SupabasePaymentDataSource(),
    );
    final authRepository = AuthRepositoryImpl(dataSource: authDataSource);

    return AppDependencies._(
      orderRepository: orderRepository,
      paymentRepository: paymentRepository,
      authRepository: authRepository,
      orderSyncService: orderSyncService,
      notificationService: notificationService,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await GoogleSignIn.instance.initialize(
    serverClientId:
        '610958959654-5qs735nudpm1v70ucfnl2d6dq0jnd8p3.apps.googleusercontent.com',
  );

  await initializeDateFormatting('id_ID', null);

  runApp(CleanPickApp(dependencies: await AppDependencies.build()));
}

class CleanPickApp extends StatefulWidget {
  final AppDependencies dependencies;
  const CleanPickApp({super.key, required this.dependencies});

  @override
  State<CleanPickApp> createState() => _CleanPickAppState();
}

class _CleanPickAppState extends State<CleanPickApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<NotificationRoute>? _routeSubscription;

  @override
  void initState() {
    super.initState();
    _routeSubscription = widget.dependencies.notificationService.routes.listen(
      _handleRoute,
    );
  }

  @override
  void dispose() {
    _routeSubscription?.cancel();
    super.dispose();
  }

  void _handleRoute(NotificationRoute route) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null || route.orderId == null) return;

    final role = widget.dependencies.authRepository.currentRole;
    if (route.type == 'new_order' && role == 'petugas') {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const PetugasDashboardPage(initialTab: 1),
        ),
        (route) => false,
      );
    } else if ((route.type == 'order_taken' ||
            route.type == 'officer_found' ||
            route.type == 'order_status' ||
            route.type == 'payment_success' ||
            route.type == 'payment_failed') &&
        role == 'customer') {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => OrderDetailPage(orderId: route.orderId!),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(
            loginUseCase: LoginUseCase(widget.dependencies.authRepository),
            loginPetugasUseCase: LoginPetugasUseCase(
              widget.dependencies.authRepository,
            ),
            registerUseCase: RegisterUseCase(
              widget.dependencies.authRepository,
            ),
            registerPetugasUseCase: RegisterPetugasUseCase(
              widget.dependencies.authRepository,
            ),
            resetPasswordUseCase: ResetPasswordUseCase(
              widget.dependencies.authRepository,
            ),
            repository: widget.dependencies.authRepository,
            notificationService: widget.dependencies.notificationService,
          ),
        ),
        BlocProvider<OrderCubit>(
          create: (_) => OrderCubit(
            getOrders: GetOrders(widget.dependencies.orderRepository),
            getOrderDetail: GetOrderDetail(widget.dependencies.orderRepository),
            createOrder: CreateOrder(widget.dependencies.orderRepository),
            assignOrder: AssignOrder(widget.dependencies.orderRepository),
            cancelOrder: CancelOrder(widget.dependencies.orderRepository),
            payOrder: PayOrder(widget.dependencies.paymentRepository),
            paymentRepository: widget.dependencies.paymentRepository,
            completeOrder: CompleteOrder(widget.dependencies.orderRepository),
          ),
        ),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'CleanPick',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashPage(),
      ),
    );
  }
}
