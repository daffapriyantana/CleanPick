import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  String? _currentRole;

  FirebaseAuthDataSource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FlutterSecureStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? const FlutterSecureStorage();

  @override
  UserModel? get currentUser => _currentUser;

  @override
  String? get currentRole => _currentRole;

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

    final role = data['role']?.toString() ?? 'customer';
    _currentRole = role;
    final user = UserModel(
      id: uid,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
    );
    await _persistSession(user, role);
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
      _currentRole = null;
      return;
    }

    _currentRole = await _storage.read(key: _roleKey);

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
      if (await _storage.read(key: _roleKey) == 'petugas') {
        await _auth.signOut();
        _currentUser = null;
        throw const AuthException(
          'Akun ini adalah akun petugas. Gunakan login petugas.',
        );
      }
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
  Future<UserModel> signInWithGoogle() async {
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException('Token Google tidak tersedia');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await _auth.signInWithCredential(credential);
      final firebaseUser = result.user;
      if (firebaseUser == null) {
        throw const AuthException('Gagal mendapatkan akun Google');
      }

      final profileReference =
          _firestore.collection('users').doc(firebaseUser.uid);
      final profileSnapshot = await profileReference.get();
      final existingData = profileSnapshot.data();
      final role = existingData?['role']?.toString() ?? 'customer';
      if (role == 'petugas') {
        await _auth.signOut();
        throw const AuthException(
          'Akun petugas harus masuk melalui halaman login petugas.',
        );
      }

      final name = existingData?['name']?.toString().trim().isNotEmpty == true
          ? existingData!['name'].toString()
          : (firebaseUser.displayName ?? account.displayName ?? 'Pengguna');
      final email = existingData?['email']?.toString() ??
          firebaseUser.email ??
          account.email;
      final phone =
          existingData?['phone']?.toString() ?? firebaseUser.phoneNumber ?? '';
      final address = existingData?['address']?.toString() ?? '';

      if (!profileSnapshot.exists) {
        await profileReference.set({
          'name': name,
          'email': email,
          'phone': phone,
          'address': address,
          'role': 'customer',
        });
      }

      final user = UserModel(
        id: firebaseUser.uid,
        name: name,
        email: email,
        phone: phone,
        address: address,
      );
      _currentUser = user;
      _currentRole = 'customer';
      await _persistSession(user, 'customer');
      return user;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('Login dengan Google dibatalkan');
      }
      throw const AuthException('Login dengan Google gagal');
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e));
    } on AuthException {
      rethrow;
    } on FirebaseException {
      throw const AuthException('Profil pengguna tidak dapat dimuat');
    } catch (_) {
      throw const AuthException('Periksa koneksi internet Anda');
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
      _currentRole = 'petugas';
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
      _currentRole = null;
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

      final officers = _firestore.collection('officers');
      DocumentSnapshot<Map<String, dynamic>>? officerDocument;

      final documentByUid = await officers.doc(firebaseUser.uid).get();
      if (documentByUid.exists) {
        officerDocument = documentByUid;
      } else {
        final officerSnapshot = await officers
            .where('uid', isEqualTo: firebaseUser.uid)
            .limit(1)
            .get();
        if (officerSnapshot.docs.isNotEmpty) {
          officerDocument = officerSnapshot.docs.first;
        } else {
          final legacyOfficerSnapshot = await officers
              .where('officerid', isEqualTo: firebaseUser.uid)
              .limit(1)
              .get();
          if (legacyOfficerSnapshot.docs.isNotEmpty) {
            officerDocument = legacyOfficerSnapshot.docs.first;
          }
        }
      }

      if (officerDocument == null) {
        await _auth.signOut();
        throw const AuthException(
          'Akun petugas tidak ditemukan di data officer',
        );
      }

      final officerData = officerDocument.data();
      if (officerData == null) {
        await _auth.signOut();
        throw const AuthException('Data petugas kosong');
      }
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
