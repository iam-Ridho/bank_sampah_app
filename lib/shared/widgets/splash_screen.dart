import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Splash screen sederhana — murni kosmetik, tidak ada logic inisialisasi
/// di sini (Firebase.initializeApp tetap di main() sebelum runApp, BUKAN
/// dipindah ke sini, supaya tidak ada race condition aneh).
///
/// Gradient & branding diselaraskan dengan `.login-hero` di mockup
/// `agri_mineral_figma_mockup_with_login.html` (tema "AgroMin Manager").
///
/// Dipakai sebagai layar transisi singkat sebelum AuthGate menentukan
/// arah navigasi (login vs home) — lihat pemakaian di main.dart.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // Sesuai `linear-gradient(160deg, --green-900, --green-700)`
            colors: [AppColors.green900, AppColors.green700],
            begin: Alignment(-0.7, -1),
            end: Alignment(0.7, 1),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco_outlined, size: 56, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'AgroMin Manager',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Bibit • Pupuk • Peternakan • Perkebunan • Sawit • Emas • Nikel',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
