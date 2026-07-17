import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/app_state_widgets.dart';
import '../../shared/widgets/splash_screen.dart';
import 'auth_provider.dart';
import 'screens/login_screen.dart';

/// Gate utama aplikasi — root widget yang menentukan apakah user melihat
/// LoginScreen atau konten utama, berdasarkan authStateProvider.
///
/// CATATAN OFFLINE-FIRST: Firebase Auth menyimpan sesi login di device
/// secara persisten, jadi setelah login pertama kali, `authStateChanges()`
/// akan tetap mengembalikan user yang sama walau device offline saat
/// dibuka — user TIDAK perlu online setiap kali membuka app, hanya saat
/// login PERTAMA KALI atau setelah logout eksplisit.
class AuthGate extends ConsumerWidget {
  final Widget homeWidget;

  const AuthGate({super.key, required this.homeWidget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      // SplashScreen dipakai khusus di sini — transisi PALING AWAL
      // sebelum status login diketahui. Loading state lain di app
      // (list data, dst) tetap pakai AppLoadingState yang lebih netral.
      loading: () => const SplashScreen(),
      error: (err, st) => Scaffold(
        body: AppErrorState(
          message: 'Gagal memeriksa status login. Coba buka ulang aplikasi.',
        ),
      ),
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }
        return homeWidget;
      },
    );
  }
}
