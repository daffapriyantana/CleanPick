import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/error/exceptions.dart';
import '../models/user_model.dart';
import 'auth_local_datasource.dart';

class FirebaseAuthDataSource implements AuthLocalDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  UserModel? _currentUser;

  FirebaseAuthDataSource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  UserModel? get currentUser => _currentUser;

  Future<UserModel> _getUserProfile(String uid) async {
    final document = await _firestore.collection('users').doc(uid).get();

    if (!document.exists) {
      throw const AuthException(
        'Data profil pengguna tidak ditemukan',
      );
    }

    final data = document.data();

    if (data == null) {
      throw const AuthException(
        'Data profil pengguna kosong',
      );
    }

    return UserModel(
      id: uid,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
    );
  }

  Future<void> initialize() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      _currentUser = null;
      return;
    }

    try {
      _currentUser = await _getUserProfile(firebaseUser.uid);
    } catch (_) {
      _currentUser = null;
    }
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw const AuthException(
          'Gagal mendapatkan data pengguna',
        );
      }

      final user = await _getUserProfile(firebaseUser.uid);
      _currentUser = user;
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'Terjadi kesalahan saat login',
      );
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw const AuthException(
          'Gagal membuat akun',
        );
      }

      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'name': name.trim(),
        'email': normalizedEmail,
        'phone': phone.trim(),
        'address': address.trim(),
        'role': 'customer',
      });

      final user = UserModel(
        id: firebaseUser.uid,
        name: name.trim(),
        email: normalizedEmail,
        phone: phone.trim(),
        address: address.trim(),
      );
      _currentUser = user;
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'Terjadi kesalahan saat membuat akun',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUser = null;
    } catch (_) {
      throw const AuthException(
        'Gagal melakukan logout',
      );
    }
  }

  @override
  Future<UserModel> loginPetugas({
    required String id,
    required String password,
  }) async {
    throw const AuthException(
      'Login petugas belum dimigrasikan ke Firebase',
    );
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email atau password salah';
      case 'email-already-in-use':
        return 'Email sudah terdaftar';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'weak-password':
        return 'Password terlalu lemah';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Silakan coba lagi nanti';
      case 'network-request-failed':
        return 'Tidak dapat terhubung ke internet';
      default:
        return e.message ?? 'Terjadi kesalahan autentikasi';
    }
  }
}
