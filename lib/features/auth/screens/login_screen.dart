import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../auth_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Screen login — sengaja minimal: email + password saja.
/// Tidak ada "lupa password", "login dengan Google", dll di MVP ini.
/// Kalau dibutuhkan nanti, tambahkan SETELAH rilis pertama, bukan sekarang.
///
/// Struktur (hero hijau + body putih) diselaraskan dengan
/// `.login-hero` + `.login-body` di mockup AgroMin Manager.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authControllerProvider.notifier).signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    // Tampilkan error sebagai SnackBar — cara paling sederhana dan
    // cukup untuk MVP, tidak perlu dialog custom.
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString()), backgroundColor: AppColors.red),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
          child: Text(
            'TrashIn © 2026\nDikembangkan oleh Ridho - Proker PKN POLITANI Kelompok 14',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey, 
              height: 1.5,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero hijau — sesuai .login-hero di mockup
              Container(
                padding: const EdgeInsets.fromLTRB(28, 40, 28, 36),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.green900, AppColors.green700],
                    begin: Alignment(-0.7, -1),
                    end: Alignment(0.7, 1),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const FaIcon(FontAwesomeIcons.recycle, size: 36, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'TrashIn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sistem Pencatatan Bank Sampah',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Body putih — sesuai .login-body di mockup
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Masuk ke Akun Anda',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Silakan masuk untuk melanjutkan ke dashboard.',
                        style: TextStyle(fontSize: 13, color: AppColors.gray500),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline, size: 20),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email wajib diisi';
                          }
                          if (!value.contains('@')) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Kata Sandi',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kata sandi wajib diisi';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 8),

                      // Pengingat penting: login pertama kali butuh koneksi.
                      // Ini mencegah user bingung kalau mencoba login pertama
                      // kali saat offline di lokasi tanpa sinyal.
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 14, color: AppColors.gray500),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Login pertama kali memerlukan koneksi internet',
                                style: TextStyle(fontSize: 11, color: AppColors.gray500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      FilledButton.icon(
                        onPressed: isLoading ? null : _submit,
                        icon: isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login, size: 18),
                        label: Text(isLoading ? 'Memproses...' : 'Masuk'),
                      ),
                      const SizedBox(height: 16),

                      // TIDAK ADA tombol "Daftar" publik — SENGAJA
                      // dihapus. Aplikasi ini memakai SATU akun bersama
                      // untuk pengurus (sekretaris & bendahara), bukan
                      // akun per-orang. Membiarkan pendaftaran terbuka
                      // ke publik berarti siapa pun yang install app
                      // ini bisa membuat akun sendiri dan mendapat akses
                      // PENUH baca/tulis semua data — lubang keamanan
                      // yang tidak perlu untuk kasus satu-akun-bersama
                      // seperti ini. Lihat README.md bagian "Setup Akun
                      // Bersama" untuk cara membuat akun awal.
                      const Center(
                        child: Text(
                          'Lupa kata sandi atau butuh akses?\nHubungi pengurus bank sampah.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.gray500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
