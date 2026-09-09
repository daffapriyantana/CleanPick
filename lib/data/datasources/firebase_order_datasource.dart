import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/exceptions.dart';
import '../models/order_model.dart';
import 'order_local_datasource.dart';

class FirebaseOrderDataSource implements OrderLocalDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SharedPreferences? _providedPreferences;

  static const _cacheKey = 'cleanpick_firestore_orders_cache';
  static const _queueKey = 'cleanpick_firestore_orders_queue';

  FirebaseOrderDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    SharedPreferences? preferences,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _providedPreferences = preferences;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  @override
  Future<List<OrderModel>> getOrders() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw const ServerException('Pengguna belum login');
      }

      final profile =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      final isOfficer = profile.data()?['role'] == 'petugas';
      final query = isOfficer
          ? _orders.orderBy('createdAt', descending: true)
          : _orders.where('customerId', isEqualTo: firebaseUser.uid);
      final snapshot = await query.get();
      final orders = snapshot.docs.map(_fromDocument).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _saveCachedOrders(orders);
      return orders;
    } on ServerException {
      rethrow;
    } on FirebaseException {
      final cached = await _readCachedOrders();
      return cached;
    } catch (_) {
      throw const ServerException('Gagal memuat pesanan');
    }
  }

  @override
  Future<OrderModel> getOrderDetail(String orderId) async {
    try {
      final document = await _orders.doc(orderId).get();
      if (!document.exists || document.data() == null) {
        throw ServerException('Pesanan dengan ID $orderId tidak ditemukan');
      }
      return _fromDocument(document);
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Gagal memuat detail pesanan');
    } catch (_) {
      throw const ServerException('Gagal memuat detail pesanan');
    }
  }

  @override
  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw const ServerException('Pengguna belum login');
      }

      final orderForStorage = OrderModel.fromEntity(
        order.copyWith(
          customerId: firebaseUser.uid,
          officerId: null,
          officerName: null,
        ),
      );
      await _orders.doc(orderForStorage.id).set(_toFirestore(orderForStorage));
      await _saveCachedOrders([
        ...(await _readCachedOrders()),
        orderForStorage,
      ]);
      return orderForStorage;
    } on FirebaseException catch (e) {
      if (_isOfflineError(e)) {
        final pending = OrderModel.fromEntity(
          order.copyWith(syncStatus: 'pending'),
        );
        await _cachePendingOrder(pending);
        return pending;
      }
      throw ServerException(e.message ?? 'Gagal membuat pesanan');
    } catch (_) {
      throw const ServerException('Gagal membuat pesanan');
    }
  }

  @override
  Future<OrderModel> assignOrder({
    required String orderId,
    required String officerName,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw const ServerException('Petugas belum login');
    }

    return _updateOrder(
      orderId,
      (order) {
        if (order.status != OrderStatus.menunggu) {
          throw const ServerException('Pesanan sudah diambil petugas lain');
        }
        return OrderModel.fromEntity(
          order.copyWith(
            status: OrderStatus.diproses,
            officerId: firebaseUser.uid,
            officerName: officerName,
          ),
        );
      },
      'Gagal mengambil pesanan',
    );
  }

  @override
  Future<OrderModel> cancelOrder(String orderId) async {
    return _updateOrder(
      orderId,
      (order) => OrderModel.fromEntity(
        order.copyWith(status: OrderStatus.dibatalkan),
      ),
      'Gagal membatalkan pesanan',
    );
  }

  @override
  Future<OrderModel> payOrder(String orderId) async {
    return _updateOrder(
      orderId,
      (order) => OrderModel.fromEntity(
        order.copyWith(paymentStatus: PaymentStatus.lunas),
      ),
      'Gagal memproses pembayaran',
    );
  }

  @override
  Future<OrderModel> completeOrder(String orderId) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw const ServerException('Petugas belum login');
    }

    return _updateOrder(
      orderId,
      (order) {
        if (order.officerId != firebaseUser.uid) {
          throw const ServerException(
            'Anda tidak berwenang menyelesaikan pesanan ini',
          );
        }
        return OrderModel.fromEntity(
          order.copyWith(status: OrderStatus.selesai),
        );
      },
      'Gagal menyelesaikan pesanan',
    );
  }

  Future<OrderModel> _updateOrder(
    String orderId,
    OrderModel Function(OrderModel order) update,
    String fallbackMessage,
  ) async {
    try {
      final reference = _orders.doc(orderId);
      final updated =
          await _firestore.runTransaction<OrderModel>((transaction) async {
        final snapshot = await transaction.get(reference);
        if (!snapshot.exists || snapshot.data() == null) {
          throw ServerException('Pesanan dengan ID $orderId tidak ditemukan');
        }
        final nextOrder = update(_fromDocument(snapshot));
        transaction.set(reference, _toFirestore(nextOrder));
        return nextOrder;
      });
      return updated;
    } on ServerException {
      rethrow;
    } on FirebaseException catch (e) {
      final cached = await _findCachedOrder(orderId);
      if (cached == null) {
        throw ServerException(e.message ?? fallbackMessage);
      }
      final updated = update(cached);
      final pending = OrderModel.fromEntity(
        updated.copyWith(syncStatus: 'pending'),
      );
      await _cachePendingOrder(pending);
      return pending;
    } catch (_) {
      throw ServerException(fallbackMessage);
    }
  }

  OrderModel _fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw const ServerException('Data pesanan kosong');
    }

    return OrderModel(
      id: data['id']?.toString() ?? document.id,
      wasteType: _wasteType(data['wasteType']),
      weightKg: _doubleValue(data['weightKg']),
      address: data['address']?.toString() ?? '',
      pickupDate: _timestamp(data['pickupDate']),
      vehicleType: _vehicleType(data['vehicleType']),
      baseFee: _doubleValue(data['baseFee']),
      distanceFee: _doubleValue(data['distanceFee']),
      weightFee: _doubleValue(data['weightFee']),
      totalPrice: _doubleValue(data['totalPrice']),
      status: _orderStatus(data['status']),
      paymentStatus: _paymentStatus(data['paymentStatus']),
      createdAt: _timestamp(data['createdAt']),
      note: data['note'] as String?,
      customerId: data['customerId'] as String?,
      customerName: data['customerName'] as String?,
      officerId: data['officerId'] as String?,
      officerName: data['officerName'] as String?,
      photoPath: data['photoPath'] as String?,
      latitude: _nullableDouble(data['latitude']),
      longitude: _nullableDouble(data['longitude']),
      paymentMethod: _paymentMethod(data['paymentMethod']),
    );
  }

  Map<String, dynamic> _toFirestore(OrderModel order) => {
        'id': order.id,
        'wasteType': order.wasteType.name,
        'weightKg': order.weightKg,
        'address': order.address,
        'pickupDate': Timestamp.fromDate(order.pickupDate),
        'vehicleType': order.vehicleType.name,
        'baseFee': order.baseFee.toInt(),
        'distanceFee': order.distanceFee.toInt(),
        'weightFee': order.weightFee.toInt(),
        'totalPrice': order.totalPrice.toInt(),
        'status': order.status.name,
        'paymentStatus': order.paymentStatus.name,
        'createdAt': Timestamp.fromDate(order.createdAt),
        'note': order.note,
        'customerId': order.customerId,
        'customerName': order.customerName,
        'officerId': order.officerId,
        'officerName': order.officerName,
        'photoPath': order.photoPath,
        'latitude': order.latitude,
        'longitude': order.longitude,
        'paymentMethod': order.paymentMethod.name,
      };

  Future<SharedPreferences> get _preferences async =>
      _providedPreferences ?? await SharedPreferences.getInstance();

  Future<List<OrderModel>> _readCachedOrders() async {
    final encoded = (await _preferences).getString(_cacheKey);
    if (encoded == null) return <OrderModel>[];
    try {
      return (jsonDecode(encoded) as List<dynamic>)
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <OrderModel>[];
    }
  }

  Future<void> _saveCachedOrders(List<OrderModel> orders) async {
    final incomingIds = orders.map((order) => order.id).toSet();
    final existingPending = (await _readCachedOrders()).where(
      (order) =>
          order.syncStatus == 'pending' && !incomingIds.contains(order.id),
    );
    final unique = <String, OrderModel>{
      for (final order in [...existingPending, ...orders]) order.id: order,
    };
    await (await _preferences).setString(
      _cacheKey,
      jsonEncode(unique.values.map((order) => order.toJson()).toList()),
    );
  }

  Future<OrderModel?> _findCachedOrder(String orderId) async {
    for (final order in await _readCachedOrders()) {
      if (order.id == orderId) return order;
    }
    return null;
  }

  Future<void> _cachePendingOrder(OrderModel order) async {
    await _saveCachedOrders([...(await _readCachedOrders()), order]);
    final preferences = await _preferences;
    final queue = preferences.getStringList(_queueKey) ?? <String>[];
    queue.removeWhere((item) {
      try {
        return (jsonDecode(item) as Map<String, dynamic>)['id'] == order.id;
      } catch (_) {
        return false;
      }
    });
    queue.add(jsonEncode({'id': order.id, 'order': order.toJson()}));
    await preferences.setStringList(_queueKey, queue);
  }

  Future<int> syncPendingOperations() async {
    final preferences = await _preferences;
    final queue = preferences.getStringList(_queueKey) ?? <String>[];
    var synced = 0;
    final remaining = <String>[];
    for (final item in queue) {
      try {
        final encoded = jsonDecode(item) as Map<String, dynamic>;
        final order = OrderModel.fromJson(
          Map<String, dynamic>.from(encoded['order'] as Map),
        );
        await _orders.doc(order.id).set(_toFirestore(order));
        final syncedOrder = OrderModel.fromEntity(
          order.copyWith(syncStatus: 'synced'),
        );
        await _saveCachedOrders([
          ...(await _readCachedOrders())
              .where((cached) => cached.id != order.id),
          syncedOrder,
        ]);
        synced++;
      } catch (_) {
        remaining.add(item);
      }
    }
    await preferences.setStringList(_queueKey, remaining);
    return synced;
  }

  bool _isOfflineError(FirebaseException exception) =>
      exception.code == 'unavailable' ||
      exception.code == 'deadline-exceeded' ||
      exception.code == 'network-request-failed';

  DateTime _timestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    throw const ServerException('Format tanggal pesanan tidak valid');
  }

  double _doubleValue(Object? value) {
    if (value is num) return value.toDouble();
    throw const ServerException('Format angka pesanan tidak valid');
  }

  double? _nullableDouble(Object? value) =>
      value is num ? value.toDouble() : null;

  WasteType _wasteType(Object? value) =>
      WasteType.values.byName(value.toString());

  VehicleType _vehicleType(Object? value) =>
      VehicleType.values.byName(value.toString());

  OrderStatus _orderStatus(Object? value) =>
      OrderStatus.values.byName(value.toString());

  PaymentStatus _paymentStatus(Object? value) =>
      PaymentStatus.values.byName(value.toString());

  PaymentMethod _paymentMethod(Object? value) => PaymentMethod.values
      .byName(value?.toString() ?? PaymentMethod.codTunai.name);
}
