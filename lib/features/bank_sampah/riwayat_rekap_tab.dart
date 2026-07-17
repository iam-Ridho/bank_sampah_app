import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/jenis_barang_model.dart';
import '../../models/setoran_model.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../shared/widgets/app_state_widgets.dart';
import 'edit_setoran_sheet.dart';
import 'laporan_sampah_action_panel.dart';
import 'rekap_sampah_provider.dart';
import '../nasabah/setoran_repository.dart';

/// Tab Riwayat & Rekap — DIGABUNG jadi satu tab supaya petugas tidak
/// perlu bolak-balik untuk lihat "total nilai berapa" DAN "kunjungan
/// mana saja yang masuk hitungan itu".
///
/// Riwayat SEKARANG per SETORAN (satu kunjungan nasabah, bisa berisi
/// banyak item) — bukan lagi per baris barang tunggal seperti
/// sebelumnya. Tap satu kartu setoran untuk lihat rincian item +
/// edit/hapus seluruh kunjungan itu.
class RiwayatRekapTab extends ConsumerStatefulWidget {
  const RiwayatRekapTab({super.key});

  @override
  ConsumerState<RiwayatRekapTab> createState() => _RiwayatRekapTabState();
}

class _RiwayatRekapTabState extends ConsumerState<RiwayatRekapTab> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final periode = ref.watch(selectedPeriodeRekapProvider);
    final searchQuery = ref.watch(searchQuerySampahProvider);
    final asyncTotalNilai = ref.watch(totalNilaiPeriodeProvider);
    final asyncRekap = ref.watch(rekapSampahProvider);
    final asyncSetoran = ref.watch(filteredSetoranProvider);
    final adaPencarianAktif = searchQuery.trim().isNotEmpty;

    return Column(
      children: [
        // Search box — mencari di NAMA NASABAH, jenis barang, atau
        // catatan (mis. cari "Budi" atau cari "kardus").
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama nasabah, jenis barang, catatan...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: adaPencarianAktif
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchQuerySampahProvider.notifier).state = '';
                      },
                    )
                  : null,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (v) => ref.read(searchQuerySampahProvider.notifier).state = v,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: PeriodeRekap.values.map((p) {
                final selected = periode == p;
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
                    onSelected: (_) => ref.read(selectedPeriodeRekapProvider.notifier).state = p,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const LaporanSampahActionPanel(),
        Expanded(
          child: asyncSetoran.when(
            loading: () => const AppLoadingState(message: 'Memuat data...'),
            error: (_, __) => const AppErrorState(message: 'Gagal memuat riwayat.'),
            data: (daftarSetoran) {
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  12,
                  0,
                  12,
                  12 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  asyncTotalNilai.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (total) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.green900, AppColors.green700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatRupiah(total),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Total Nilai • ${periode.label}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.payments_outlined, color: Colors.white, size: 30),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Rekap per Jenis', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  asyncRekap.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (daftarRekap) {
                      if (daftarRekap.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            adaPencarianAktif
                                ? 'Tidak ada hasil untuk pencarian ini.'
                                : 'Belum ada data pada periode ini.',
                            style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                          ),
                        );
                      }
                      return Column(
                        children: daftarRekap
                            .map((r) => Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    boxShadow: AppShadows.card,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        r.satuan == SatuanBarang.kg
                                            ? Icons.scale_outlined
                                            : r.satuan == SatuanBarang.liter
                                                ? Icons.water_drop_outlined
                                                : Icons.tag_outlined,
                                        size: 16,
                                        color: AppColors.gray400,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(r.jenisBarang,
                                            style: const TextStyle(fontSize: 13)),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            r.satuan == SatuanBarang.kg
                                                ? '${r.totalJumlah.toStringAsFixed(1)} kg'
                                                : r.satuan == SatuanBarang.liter
                                                    ? '${r.totalJumlah.toStringAsFixed(1)} liter'
                                                    : '${r.totalJumlah.toStringAsFixed(0)} buah',
                                            style: const TextStyle(fontSize: 11, color: AppColors.gray500),
                                          ),
                                          Text(
                                            formatRupiah(r.totalNilai),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.green800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Riwayat Setoran', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (daftarSetoran.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: AppEmptyState(
                        icon: adaPencarianAktif ? Icons.search_off : Icons.receipt_long_outlined,
                        message: adaPencarianAktif
                            ? 'Tidak ada setoran yang cocok dengan pencarian ini.'
                            : 'Belum ada riwayat setoran.\nCatat lewat tab Input.',
                      ),
                    )
                  else
                    ...daftarSetoran.map((s) => _SetoranListItem(setoran: s)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SetoranListItem extends ConsumerWidget {
  final SetoranModel setoran;

  const _SetoranListItem({required this.setoran});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(setoran.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final hasil = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Setoran?'),
            content: Text(
              'Seluruh catatan setoran "${setoran.nasabahNama}" '
              '(${formatRupiah(setoran.totalNilai)}) akan dihapus permanen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
        return hasil ?? false;
      },
      onDismissed: (_) async {
        await ref.read(setoranRepositoryProvider).hapusSetoran(setoran.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Setoran dihapus')),
          );
        }
      },
      background: Container(
        color: AppColors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.card,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => showEditSetoranSheet(context, setoran),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.green100,
                      child: Text(
                        setoran.nasabahNama.isNotEmpty
                            ? setoran.nasabahNama[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.green900,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(setoran.nasabahNama,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(
                            '${setoran.tanggal.day}/${setoran.tanggal.month}/${setoran.tanggal.year} • '
                            '${setoran.items.length} jenis barang',
                            style: const TextStyle(fontSize: 11, color: AppColors.gray500),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatRupiah(setoran.totalNilai),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.green800,
                      ),
                    ),
                  ],
                ),
                if (setoran.catatan != null && setoran.catatan!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    setoran.catatan!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.gray400, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
