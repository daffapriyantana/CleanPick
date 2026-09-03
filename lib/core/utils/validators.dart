/// Small, pure, unit-testable validation helpers used by both the
/// domain layer (use cases) and the presentation layer (form fields).
class Validators {
  Validators._();

  static bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email.trim());
  }

  static bool isValidPhone(String phone) {
    final regex = RegExp(r'^[0-9]{9,15}$');
    return regex.hasMatch(phone.trim());
  }

  static bool isValidPassword(String password) {
    return password.trim().length >= 6;
  }

  static String? emailError(String? email) {
    email ??= '';
    if (email.trim().isEmpty) return 'Email wajib diisi';
    if (!isValidEmail(email)) return 'Format email tidak valid';
    return null;
  }

  static String? passwordError(String? password) {
    password ??= '';
    if (password.isEmpty) return 'Password wajib diisi';
    if (!isValidPassword(password)) return 'Password minimal 6 karakter';
    return null;
  }

  static String? nameError(String? name) {
    name ??= '';
    if (name.trim().isEmpty) return 'Nama wajib diisi';
    if (name.trim().length < 3) return 'Nama minimal 3 karakter';
    return null;
  }

  static String? phoneError(String? phone) {
    phone ??= '';
    if (phone.trim().isEmpty) return 'Nomor HP wajib diisi';
    if (!isValidPhone(phone)) return 'Nomor HP tidak valid';
    return null;
  }

  static String? addressError(String? address) {
    address ??= '';
    if (address.trim().isEmpty) return 'Alamat wajib diisi';
    return null;
  }

  static String? confirmPasswordError(String password, String confirm) {
    if (confirm.isEmpty) return 'Konfirmasi password wajib diisi';
    if (password != confirm) return 'Konfirmasi password tidak cocok';
    return null;
  }
}
