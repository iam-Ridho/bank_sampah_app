import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Instance FirebaseAuth.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

/// Stream auth state — dipakai untuk menentukan apakah user sudah login.
/// Dengarkan ini di root widget untuk routing login vs home.
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

/// Notifier sederhana untuk aksi login/register/logout.
/// Sengaja dibuat minimal — sesuai rekomendasi: auth dasar saja,
/// jangan masuk ke RBAC kompleks di MVP 3 minggu.
class AuthController extends StateNotifier<AsyncValue<void>> {
  final FirebaseAuth _auth;

  AuthController(this._auth) : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(_pesanError(e), st);
    }
  }

  /// Registrasi user baru. Untuk MVP, siapa pun bisa daftar sendiri —
  /// kontrol akses lebih ketat (mis. hanya admin yang bisa tambah user)
  /// sengaja ditunda, sesuai rekomendasi hindari RBAC kompleks di awal.
  Future<void> register(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(_pesanError(e), st);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Terjemahkan FirebaseAuthException jadi pesan berbahasa Indonesia
  /// yang dimengerti user lapangan — pesan default Firebase teknis
  /// dan berbahasa Inggris, tidak cocok ditampilkan langsung.
  String _pesanError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'Email tidak terdaftar';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email atau kata sandi salah';
        case 'email-already-in-use':
          return 'Email sudah terdaftar, silakan login';
        case 'weak-password':
          return 'Kata sandi terlalu pendek (minimal 6 karakter)';
        case 'invalid-email':
          return 'Format email tidak valid';
        case 'network-request-failed':
          return 'Tidak ada koneksi internet. Login memerlukan koneksi pertama kali.';
        default:
          return 'Terjadi kesalahan: ${e.message ?? e.code}';
      }
    }
    return 'Terjadi kesalahan tidak terduga';
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(firebaseAuthProvider));
});
