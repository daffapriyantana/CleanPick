import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../../core/error/exceptions.dart';
import '../../domain/entities/payment_checkout.dart';

abstract class PaymentDataSource {
  Future<PaymentCheckout> createCheckout(String orderId);
}

abstract class PaymentStatusDataSource {
  Future<void> refreshPaymentStatus(String orderId);
}

class SupabasePaymentDataSource
    implements PaymentDataSource, PaymentStatusDataSource {
  final FirebaseAuth _auth;
  final http.Client _client;
  final Connectivity _connectivity;
  final String _functionUrl;

  SupabasePaymentDataSource({
    FirebaseAuth? auth,
    http.Client? client,
    Connectivity? connectivity,
    String? functionUrl,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _client = client ?? http.Client(),
        _connectivity = connectivity ?? Connectivity(),
        _functionUrl = functionUrl ??
            const String.fromEnvironment(
              'SUPABASE_CREATE_PAYMENT_URL',
              defaultValue:
                  'https://ahajcmhkhfzvhfhkiisd.supabase.co/functions/v1/create-midtrans-transaction',
            );

  @override
  Future<PaymentCheckout> createCheckout(String orderId) async {
    final user = _auth.currentUser;
    if (user == null) throw const ServerException('Pengguna belum login');
    final connectivity = await _connectivity.checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      throw const ServerException('Pembayaran membutuhkan koneksi internet.');
    }
    if (_functionUrl.isEmpty) {
      throw const ServerException('URL backend pembayaran belum dikonfigurasi');
    }

    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw const ServerException(
        'Token Firebase tidak tersedia. Silakan login ulang.',
      );
    }
    late final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_functionUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'orderId': orderId}),
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const ServerException(
          'Backend pembayaran tidak merespons. Coba lagi.');
    } on http.ClientException {
      throw const ServerException(
          'Tidak dapat terhubung ke backend pembayaran.');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const ServerException('Respons backend pembayaran tidak valid');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final code = body['code']?.toString();
      final message = body['error']?.toString() ??
          body['message']?.toString() ??
          'Gagal membuat transaksi pembayaran';
      throw ServerException(_paymentErrorMessage(
        statusCode: response.statusCode,
        code: code,
        message: message,
      ));
    }

    final snapToken = body['snapToken']?.toString();
    final redirectUrl = body['redirectUrl']?.toString();
    if (snapToken == null || redirectUrl == null) {
      throw ServerException(
        'Respons pembayaran tidak lengkap (HTTP ${response.statusCode}).',
      );
    }
    return PaymentCheckout(
      orderId: body['orderId']?.toString() ?? orderId,
      snapToken: snapToken,
      redirectUrl: redirectUrl,
    );
  }

  @override
  Future<void> refreshPaymentStatus(String orderId) async {
    final user = _auth.currentUser;
    if (user == null) throw const ServerException('Pengguna belum login');
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw const ServerException('Token Firebase tidak tersedia');
    }
    try {
      final response = await _client
          .post(
            Uri.parse(_functionUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'orderId': orderId, 'action': 'verify'}),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const ServerException(
          'Status pembayaran belum dapat diverifikasi',
        );
      }
    } on TimeoutException {
      throw const ServerException('Backend pembayaran tidak merespons');
    } on http.ClientException {
      throw const ServerException(
        'Tidak dapat terhubung ke backend pembayaran',
      );
    }
  }

  String _paymentErrorMessage({
    required int statusCode,
    required String? code,
    required String message,
  }) {
    if (code == 'UNAUTHORIZED_NO_AUTH_HEADER' ||
        code == '401' ||
        (statusCode == 401 &&
            message.toLowerCase().contains('authorization'))) {
      return 'Gateway Supabase menolak request. Matikan Verify JWT pada Edge Function karena aplikasi memakai Firebase Auth.';
    }
    if (code == 'BOOT_ERROR' || statusCode == 503) {
      return 'Edge Function pembayaran gagal start. Periksa deployment dan file firebase.ts.';
    }
    if (statusCode == 401) {
      return 'Sesi Firebase tidak valid atau sudah kedaluwarsa. Silakan login ulang.';
    }
    if (statusCode == 403) {
      return 'Pembayaran ditolak karena order bukan milik akun ini.';
    }
    if (statusCode == 404) {
      return 'Order tidak ditemukan di Firestore.';
    }
    if (statusCode == 422) {
      return 'Nominal order tidak valid atau tidak sesuai Firestore.';
    }
    if (statusCode == 502) {
      return 'Midtrans Sandbox menolak transaksi. Periksa Server Key Sandbox dan nominal order.';
    }
    if (statusCode >= 500) {
      return 'Backend pembayaran gagal memproses transaksi. Periksa log Edge Function.';
    }
    return message;
  }
}
