library;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Kumpulan widget state terpadu — dipakai di semua layar utama supaya
/// tampilan loading/empty/error KONSISTEN, bukan ad-hoc berbeda-beda
/// per widget. Ini mencegah kesan "app setengah jadi" di mata user,
/// walau sebenarnya hanya satu-dua widget yang belum sempat dipoles.

/// Tampilan loading standar. Selalu pakai ini, JANGAN
/// `CircularProgressIndicator()` polos tanpa context — supaya user tahu
/// sedang menunggu apa, terutama penting di koneksi lemah di lapangan.
class AppLoadingState extends StatelessWidget {
  final String? message;

  const AppLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.green800),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, style: const TextStyle(color: AppColors.gray500, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

/// Tampilan empty state standar dengan ikon + pesan + aksi opsional.
/// `onAction` dan `actionLabel` opsional — kalau diisi, tampilkan tombol
/// (mis. "Coba Lagi" atau "Tambah Data Pertama").
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.gray400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray500, fontSize: 14),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tampilan error state standar — SELALU sediakan tombol retry kalau
/// `onRetry` diisi. User di lapangan dengan koneksi tidak stabil akan
/// sering menemui error sementara (timeout, dll), jadi retry harus
/// mudah diakses tanpa perlu restart app.
class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Banner kecil non-blocking untuk kondisi "menunggu sinkronisasi awal" —
/// dipakai khusus untuk kasus `SyncReadiness.belumPernahSync` (lihat
/// sync_readiness_provider.dart). Berbeda dari AppEmptyState karena ini
/// TIDAK menyiratkan "tidak ada data" — hanya "belum bisa dipastikan".
class PendingFirstSyncBanner extends StatelessWidget {
  const PendingFirstSyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.blueBg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_sync_outlined, color: AppColors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Belum bisa memastikan data karena belum pernah terhubung '
              'ke server. Sambungkan ke internet minimal sekali untuk '
              'mengunduh data yang sudah ada sebelumnya.',
              style: TextStyle(fontSize: 12, color: AppColors.blue.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}
