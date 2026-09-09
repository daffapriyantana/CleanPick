import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/error/exceptions.dart';
import '../models/user_model.dart';
import 'auth_local_datasource.dart';

class FirebaseAuthDataSource implements AuthLocalDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FlutterSecureStorage _storage;

  static const _sessionKey = 'cleanpick_firebase_session';
  static const _roleKey = 'cleanpick_firebase_role';
  static const _subscriptionKey = 'cleanpick_subscription_status';

  UserModel? _currentUser;

  FirebaseAuthDataSource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FlutterSecureStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? const FlutterSecureStorage();

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

    final user = UserModel(
      id: uid,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
    );
    await _persistSession(user, data['role']?.toString() ?? 'customer');
    return user;
  }

  Future<void> _persistSession(UserModel user, String role) async {
    await _storage.write(key: _sessionKey, value: jsonEncode(user.toJson()));
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(
      key: _subscriptionKey,
      value: await _storage.read(key: _subscriptionKey) ?? 'free',
    );
  }

  Future<UserModel?> _readCachedProfile(String uid) async {
    final encoded = await _storage.read(key: _sessionKey);
    if (encoded == null) return null;
    try {
      final profile = UserModel.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      return profile.id == uid ? profile : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      _currentUser = null;
      return;
    }

    _currentUser = await _readCachedProfile(firebaseUser.uid) ??
        UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? '',
          email: firebaseUser.email ?? '',
          phone: '',
          address: '',
        );

    try {
      _currentUser = await _getUserProfile(firebaseUser.uid);
    } catch (_) {}
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
      await _persistSession(user, 'customer');
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
    User? createdFirebaseUser;

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

      createdFirebaseUser = firebaseUser;

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
      await _persistSession(user, 'customer');
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e));
    } on AuthException {
      rethrow;
    } catch (_) {
      if (createdFirebaseUser != null) {
        try {
          await createdFirebaseUser.delete();
        } catch (_) {}
      }

      throw const AuthException(
        'Akun berhasil dibuat, tetapi profil pengguna gagal disimpan. Silakan coba lagi.',
      );
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e));
    } catch (_) {
      throw const AuthException(
        'Terjadi kesalahan saat mengirim email reset password',
      );
    }
  }

  @override
  Future<UserModel> registerPetugas({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    User? createdFirebaseUser;

    try {
      final normalizedEmail = email.trim().toLowerCase();
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw const AuthException('Gagal membuat akun petugas');
      }

      createdFirebaseUser = firebaseUser;

      final officerName = name.trim();

      await _firestore.collection('officers').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'officerId': firebaseUser.uid,
        'name': officerName,
        'email': normalizedEmail,
        'phone': phone.trim(),
        'status': 'aktif',
      });

      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'name': officerName,
        'email': normalizedEmail,
        'phone': phone.trim(),
        'address': '',
        'role': 'petugas',
      }, SetOptions(merge: true));

      final user = UserModel(
        id: firebaseUser.uid,
        name: officerName,
        email: normalizedEmail,
        phone: phone.trim(),
        address: '',
      );

      _currentUser = user;
      await _persistSession(user, 'petugas');
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e));
    } on AuthException {
      rethrow;
    } catch (_) {
      if (createdFirebaseUser != null) {
        try {
          await createdFirebaseUser.delete();
        } catch (_) {}
      }

      throw const AuthException(
        'Akun petugas berhasil dibuat, tetapi profil gagal disimpan. Silakan coba lagi.',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      await _storage.delete(key: _sessionKey);
      await _storage.delete(key: _roleKey);
      await _storage.delete(key: _subscriptionKey);
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
    try {
      final normalizedEmail = id.trim().toLowerCase();
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw const AuthException('Gagal mendapatkan data petugas');
      }

      final officerSnapshot = await _firestore
          .collection('officers')
          .where('uid', isEqualTo: firebaseUser.uid)
          .limit(1)
          .get();

      if (officerSnapshot.docs.isEmpty) {
        await _auth.signOut();
        throw const AuthException(
          'Akun petugas tidak ditemukan di data officer',
        );
      }

      final officerData = officerSnapshot.docs.first.data();
      final status = officerData['status']?.toString() ?? 'nonaktif';
      if (status != 'aktif') {
        await _auth.signOut();
        throw const AuthException('Akun petugas tidak aktif');
      }

      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'name':
            officerData['name']?.toString() ?? firebaseUser.displayName ?? '',
        'email': officerData['email']?.toString() ?? firebaseUser.email ?? '',
        'phone': officerData['phone']?.toString() ?? '',
        'address': '',
        'role': 'petugas',
      }, SetOptions(merge: true));

      final user = UserModel(
        id: firebaseUser.uid,
        name: officerData['name']?.toString() ?? firebaseUser.displayName ?? '',
        email: officerData['email']?.toString() ?? firebaseUser.email ?? '',
        phone: officerData['phone']?.toString() ?? '',
        address: '',
      );

      _currentUser = user;
      await _persistSession(user, 'petugas');
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Terjadi kesalahan saat login petugas');
    }
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
