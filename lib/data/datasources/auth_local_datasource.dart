import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> signInWithGoogle();
  Future<void> resetPassword({required String email});
  Future<UserModel> loginPetugas(
      {required String id, required String password});
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
  });
  Future<UserModel> registerPetugas({
    required String name,
    required String email,
    required String phone,
    required String password,
  });
  Future<void> logout();
  UserModel? get currentUser;
  String? get currentRole;
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const _usersKey = 'cleanpick_users';
  static const _sessionKey = 'cleanpick_session';
  static const _roleKey = 'cleanpick_role';
  static const _subscriptionKey = 'cleanpick_subscription_status';

  final FlutterSecureStorage _storage;
  final Map<String, String> _passwords = {'budi@email.com': 'password123'};
  final List<UserModel> _users = [
    const UserModel(
      id: 'usr-001',
      name: 'Budi',
      email: 'budi@email.com',
      phone: '081234567890',
      address: 'Jl. Melati No. 12, Jakarta',
    ),
  ];

  final Map<String, String> _petugasPasswords = {'PTG-001': 'password123'};
  final List<UserModel> _petugas = [
    const UserModel(
      id: 'PTG-001',
      name: 'Ahmad',
      email: 'ahmad@cleanpick.id',
      phone: '081234567891',
      address: 'Pool CleanPick, Jakarta',
    ),
  ];

  UserModel? _currentUser;
  String? _currentRole;
  String _subscriptionStatus = 'free';
  late final Future<void> _initialization = _restore();

  AuthLocalDataSourceImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> initialize() => _initialization;

  Future<void> _restore() async {
    final usersJson = await _storage.read(key: _usersKey);
    final sessionJson = await _storage.read(key: _sessionKey);
    _currentRole = await _storage.read(key: _roleKey);
    _subscriptionStatus = await _storage.read(key: _subscriptionKey) ?? 'free';

    if (usersJson != null) {
      final users = (jsonDecode(usersJson) as List<dynamic>)
          .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
          .toList();
      _users
        ..clear()
        ..addAll(users);
    }
    if (sessionJson != null) {
      _currentUser =
          UserModel.fromJson(jsonDecode(sessionJson) as Map<String, dynamic>);
    }
  }

  Future<void> _persistUsers() async {
    await _storage.write(
      key: _usersKey,
      value: jsonEncode(_users.map((user) => user.toJson()).toList()),
    );
  }

  Future<void> _persistSession(UserModel user, String role) async {
    _currentUser = user;
    _currentRole = role;
    await _storage.write(key: _sessionKey, value: jsonEncode(user.toJson()));
    await _storage.write(key: _roleKey, value: role);
  }

  @override
  UserModel? get currentUser => _currentUser;

  @override
  String? get currentRole => _currentRole;

  String get subscriptionStatus => _subscriptionStatus;

  Future<void> setSubscriptionStatus(String status) async {
    await _initialization;
    _subscriptionStatus = status;
    await _storage.write(key: _subscriptionKey, value: status);
  }

  @override
  Future<UserModel> login(
      {required String email, required String password}) async {
    await _initialization;
    await Future.delayed(const Duration(milliseconds: 700));
    final normalizedEmail = email.trim().toLowerCase();
    final storedPassword = _passwords[normalizedEmail];
    if (storedPassword == null || storedPassword != password) {
      throw const AuthException('Email atau password salah');
    }
    final user =
        _users.firstWhere((u) => u.email.toLowerCase() == normalizedEmail);
    await _persistSession(user, 'customer');
    return user;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    throw const AuthException(
      'Login Google hanya tersedia saat Firebase aktif',
    );
  }

  @override
  Future<UserModel> loginPetugas(
      {required String id, required String password}) async {
    await _initialization;
    await Future.delayed(const Duration(milliseconds: 700));
    final normalizedId = id.trim().toUpperCase();
    final storedPassword = _petugasPasswords[normalizedId];
    if (storedPassword == null || storedPassword != password) {
      throw const AuthException('ID petugas atau password salah');
    }
    final user = _petugas.firstWhere((petugas) => petugas.id == normalizedId);
    await _persistSession(user, 'petugas');
    return user;
  }

  @override
  Future<void> resetPassword({required String email}) async {
    throw const AuthException(
      'Reset password hanya tersedia untuk akun Firebase',
    );
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    await _initialization;
    await Future.delayed(const Duration(milliseconds: 900));
    final normalizedEmail = email.trim().toLowerCase();
    if (_passwords.containsKey(normalizedEmail)) {
      throw const AuthException('Email sudah terdaftar');
    }
    final newUser = UserModel(
      id: 'usr-${_users.length + 1}'.padLeft(3, '0'),
      name: name.trim(),
      email: normalizedEmail,
      phone: phone.trim(),
      address: address.trim(),
    );
    _users.add(newUser);
    _passwords[normalizedEmail] = password;
    await _persistUsers();
    await _persistSession(newUser, 'customer');
    return newUser;
  }

  @override
  Future<UserModel> registerPetugas({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _initialization;
    await Future.delayed(const Duration(milliseconds: 900));
    final normalizedEmail = email.trim().toLowerCase();
    final officerId = 'PTG-${_petugas.length + 1}'.padLeft(3, '0');
    final newOfficer = UserModel(
      id: officerId,
      name: name.trim(),
      email: normalizedEmail,
      phone: phone.trim(),
      address: '',
    );
    _petugas.add(newOfficer);
    _petugasPasswords[officerId] = password;
    await _persistSession(newOfficer, 'petugas');
    return newOfficer;
  }

  @override
  Future<void> logout() async {
    await _initialization;
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _currentRole = null;
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _roleKey);
  }
}
