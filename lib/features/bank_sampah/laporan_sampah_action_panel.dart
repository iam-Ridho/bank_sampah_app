import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import 'laporan_sampah_service.dart';
import 'rekap_sampah_provider.dart';

/// Panel aksi laporan — tiga tombol (Preview, Cetak, Export) di tab
/// Riwayat & Rekap. Laporan MENGHORMATI filter periode DAN pencarian
/// yang sedang aktif (lewat filteredSetoranProvider terpusat) — kalau
/// sekretaris sedang lihat "Minggu Ini" dan mencari "kardus", laporan
/// yang dicetak/dibagikan juga hanya berisi data itu, sesuai konteks
/// yang sedang dilihat di layar saat itu.
///
/// Pola SAMA dengan laporan_action_panel.dart milik Gapoktan, untuk
/// konsistensi UX di seluruh aplikasi.
class LaporanSampahActionPanel extends ConsumerWidget {
  const LaporanSampahActionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRekap = ref.watch(rekapSampahProvider);
    final asyncRiwayat = ref.watch(filteredSetoranProvider);
    final periode = ref.watch(selectedPeriodeRekapProvider);
    final searchQuery = ref.watch(searchQuerySampahProvider).trim();
    final currentUser = ref.watch(authStateProvider).value;

    return asyncRekap.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (rekap) {
        if (rekap.isEmpty) return const SizedBox.shrink();

        final riwayat = asyncRiwayat.value ?? [];
        final sekarang = DateTime.now();
        final formatTanggal = DateFormat('dd MMM yyyy', 'id_ID');
        String baseLabel = '';

        switch (periode) {
          case PeriodeRekap.hariIni:
            baseLabel = formatTanggal.format(sekarang);
            break;
          case PeriodeRekap.mingguIni:
            final awalMinggu = sekarang.subtract(Duration(days: sekarang.weekday - 1));
            baseLabel = '${formatTanggal.format(awalMinggu)} - ${formatTanggal.format(sekarang)}';
            break;
          case PeriodeRekap.bulanIni:
            baseLabel = DateFormat('MMMM yyyy', 'id_ID').format(sekarang);
            break;
          case PeriodeRekap.semua:
            if (riwayat.isEmpty) {
              baseLabel = 'Semua Waktu';
            } else {
              DateTime minDate = riwayat.first.tanggal;
              DateTime maxDate = riwayat.first.tanggal;
              for (final s in riwayat) {
                if (s.tanggal.isBefore(minDate)) minDate = s.tanggal;
                if (s.tanggal.isAfter(maxDate)) maxDate = s.tanggal;
              }
              baseLabel = '${formatTanggal.format(minDate)} - ${formatTanggal.format(maxDate)}';
            }
            break;
        }

        final labelPeriode =
            searchQuery.isEmpty ? baseLabel : '$baseLabel (cari: "$searchQuery")';

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => LaporanSampahService.previewLaporan(
                    rekap: rekap,
                    riwayat: riwayat,
                    labelPeriode: labelPeriode,
                    namaPenyusun: currentUser?.email,
                  ),
                  icon: const Icon(Icons.preview, size: 18),
                  label: const Text('Preview'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final berhasil = await LaporanSampahService.cetakLaporan(
                      rekap: rekap,
                      riwayat: riwayat,
                      labelPeriode: labelPeriode,
                      namaPenyusun: currentUser?.email,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            berhasil ? 'Laporan dikirim ke printer' : 'Cetak dibatalkan',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Cetak'),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Bagikan / Export',
                icon: const Icon(Icons.share),
                onSelected: (format) async {
                  if (format == 'pdf') {
                    await LaporanSampahService.simpanPdfLokal(
                      rekap: rekap,
                      riwayat: riwayat,
                      labelPeriode: labelPeriode,
                      namaPenyusun: currentUser?.email,
                    );
                  } else if (format == 'excel') {
                    await LaporanSampahService.exportExcel(
                      rekap: rekap,
                      riwayat: riwayat,
                      labelPeriode: labelPeriode,
                    );
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.red),
                        SizedBox(width: 10),
                        Text('Bagikan PDF'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'excel',
                    child: Row(
                      children: [
                        Icon(Icons.table_chart_outlined, size: 18, color: AppColors.green700),
                        SizedBox(width: 10),
                        Text('Export Excel'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
