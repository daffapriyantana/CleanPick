import '../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> loginPetugas(
      {required String id, required String password});
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
  });
  Future<void> logout();
  UserModel? get currentUser;
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  /// Dummy account seeded per the spec (Budi / budi@email.com) plus
  /// an in-memory "password store" and registered-user list, so
  /// register() -> login() works end to end without a backend.
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

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<UserModel> login(
      {required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final normalizedEmail = email.trim().toLowerCase();
    final storedPassword = _passwords[normalizedEmail];
    if (storedPassword == null || storedPassword != password) {
      throw const AuthException('Email atau password salah');
    }
    final user =
        _users.firstWhere((u) => u.email.toLowerCase() == normalizedEmail);
    _currentUser = user;
    return user;
  }

  @override
  Future<UserModel> loginPetugas(
      {required String id, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final normalizedId = id.trim().toUpperCase();
    final storedPassword = _petugasPasswords[normalizedId];
    if (storedPassword == null || storedPassword != password) {
      throw const AuthException('ID petugas atau password salah');
    }
    final user = _petugas.firstWhere((petugas) => petugas.id == normalizedId);
    _currentUser = user;
    return user;
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
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
    _currentUser = newUser;
    return newUser;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }
}
