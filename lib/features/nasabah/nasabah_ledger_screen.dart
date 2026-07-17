import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/jenis_barang_model.dart';
import '../../models/nasabah_model.dart';
import '../../models/setoran_model.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../shared/widgets/app_state_widgets.dart';
import '../bank_sampah/rekap_sampah_provider.dart' show PeriodeRekap, PeriodeRekapLabel, dalamPeriode;
import 'setoran_repository.dart';

/// Halaman "Buku Tabungan" nasabah — MIRIP buku tabungan fisik yang
/// disebutkan di skenario: tabel Tanggal, Nama Item, Jumlah, dan Total
/// nilai per kunjungan, plus GRAND TOTAL nilai pada periode terpilih.
///
/// Filter periode (Hari Ini/Minggu Ini/Bulan Ini/Semua) — SAMA persis
/// konsep dengan tab Riwayat & Rekap utama, tapi di sini DIPERSEMPIT ke
/// SATU nasabah saja. Default "Semua" (BEDA dari tab utama yang default
/// "Minggu Ini") karena buku tabungan secara alami lebih wajar
/// menampilkan seluruh riwayat nasabah itu lebih dulu, bukan cuma
/// minggu berjalan — mirip cara kerja buku tabungan fisik yang dibuka
/// dari halaman pertama.
///
/// SENGAJA HANYA riwayat + total (murni pencatatan) — TIDAK ADA fitur
/// penarikan/pencairan saldo, sesuai keputusan: itu sudah ditangani
/// buku fisik terpisah dengan tanda tangan, di luar scope aplikasi ini.
class NasabahLedgerScreen extends ConsumerStatefulWidget {
  final NasabahModel nasabah;

  const NasabahLedgerScreen({super.key, required this.nasabah});

  @override
  ConsumerState<NasabahLedgerScreen> createState() => _NasabahLedgerScreenState();
}

class _NasabahLedgerScreenState extends ConsumerState<NasabahLedgerScreen> {
  PeriodeRekap _periode = PeriodeRekap.semua;

  @override
  Widget build(BuildContext context) {
    final asyncSetoran = ref.watch(setoranStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.gray100,
      appBar: AppBar(title: Text(widget.nasabah.nama)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: PeriodeRekap.values.map((p) {
                  final selected = _periode == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(p.label),
                      selected: selected,
                      selectedColor: AppColors.green900,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : AppColors.gray700,
                      ),
                      onSelected: (_) => setState(() => _periode = p),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: asyncSetoran.when(
              loading: () => const AppLoadingState(message: 'Memuat riwayat...'),
              error: (_, __) => const AppErrorState(message: 'Gagal memuat riwayat setoran.'),
              data: (result) {
                final riwayatNasabah = result.items
                    .where((s) => s.nasabahId == widget.nasabah.id && dalamPeriode(s.tanggal, _periode))
                    .toList();

                if (riwayatNasabah.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: _periode == PeriodeRekap.semua
                        ? 'Nasabah ini belum pernah menyetor barang.'
                        : 'Tidak ada setoran pada periode "${_periode.label}".',
                  );
                }

                final totalPeriode = riwayatNasabah.fold<double>(0, (sum, s) => sum + s.totalNilai);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.green900, AppColors.green700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatRupiah(totalPeriode),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Total Nilai • ${_periode.label}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${riwayatNasabah.length} kali setor',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Ini murni catatan riwayat — belum termasuk penarikan/'
                        'pencairan (dicatat terpisah di buku fisik).',
                        style: TextStyle(fontSize: 11, color: AppColors.gray500),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...riwayatNasabah.map((s) => _SetoranCard(setoran: s)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SetoranCard extends StatelessWidget {
  final SetoranModel setoran;

  const _SetoranCard({required this.setoran});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${setoran.tanggal.day}/${setoran.tanggal.month}/${setoran.tanggal.year}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const Spacer(),
              Text(
                formatRupiah(setoran.totalNilai),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.green800,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          ...setoran.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(item.jenisBarang, style: const TextStyle(fontSize: 12)),
                    ),
                    Expanded(
                      child: Text(
                        item.satuan == SatuanBarang.kg
                            ? '${item.jumlah.toStringAsFixed(1)} kg'
                            : item.satuan == SatuanBarang.liter
                                ? '${item.jumlah.toStringAsFixed(1)} liter'
                                : '${item.jumlah.toStringAsFixed(0)} buah',
                        style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        formatRupiah(item.subtotal),
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              )),
          if (setoran.catatan != null && setoran.catatan!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              setoran.catatan!,
              style: const TextStyle(fontSize: 11, color: AppColors.gray400, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}
