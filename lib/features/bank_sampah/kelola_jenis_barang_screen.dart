import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/jenis_barang_model.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../shared/widgets/app_state_widgets.dart';
import '../nasabah/setoran_repository.dart';
import 'jenis_barang_repository.dart';

/// Halaman Kelola Jenis Barang — menutup celah "salah input jenis
/// barang sejak awal" (nama typo, salah pilih satuan, atau harga perlu
/// disesuaikan mengikuti harga pasar mingguan). Diakses lewat ikon di
/// header picker jenis barang.
class KelolaJenisBarangScreen extends ConsumerWidget {
  const KelolaJenisBarangScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResult = ref.watch(jenisBarangStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.gray100,
      appBar: AppBar(title: const Text('Kelola Jenis Barang')),
      body: asyncResult.when(
        loading: () => const AppLoadingState(),
        error: (_, __) => const AppErrorState(message: 'Gagal memuat daftar jenis barang.'),
        data: (result) {
          if (result.items.isEmpty) {
            return const AppEmptyState(
              icon: Icons.recycling_outlined,
              message: 'Belum ada jenis barang.\nTambahkan lewat tab Input saat mencatat setoran.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: result.items.length,
            itemBuilder: (context, index) => _JenisBarangItem(jenis: result.items[index]),
          );
        },
      ),
    );
  }
}

class _JenisBarangItem extends ConsumerWidget {
  final JenisBarangModel jenis;

  const _JenisBarangItem({required this.jenis});

  Future<void> _hapus(BuildContext context, WidgetRef ref) async {
    // Cek dulu apakah jenis ini MASIH DIPAKAI di setoran yang sudah
    // tercatat — karena item setoran EMBEDDED di dalam array tiap
    // dokumen (bukan koleksi terpisah yang bisa di-query langsung),
    // pengecekan dilakukan di MEMORI atas data yang sudah di-stream,
    // konsisten dengan pola filter-di-memori di seluruh aplikasi.
    final asyncSetoran = ref.read(setoranStreamProvider).value;
    final jumlahTerpakai = asyncSetoran?.items
            .where((s) => s.items.any((item) => item.jenisBarang == jenis.nama))
            .length ??
        0;

    final pesanKonfirmasi = jumlahTerpakai > 0
        ? 'Jenis "${jenis.nama}" sudah dipakai di $jumlahTerpakai setoran. '
            'Setoran lama TIDAK akan terhapus, tapi jenis ini tidak akan '
            'muncul lagi di pilihan untuk setoran baru. Lanjutkan?'
        : 'Jenis "${jenis.nama}" akan dihapus dari daftar pilihan.';

    final hasil = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jenis Barang?'),
        content: Text(pesanKonfirmasi),
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

    if (hasil == true) {
      await ref.read(jenisBarangRepositoryProvider).hapusJenisBarang(jenis.id);
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final namaController = TextEditingController(text: jenis.nama);
    final hargaController = TextEditingController(text: jenis.harga.toStringAsFixed(0));
    var satuanTerpilih = jenis.satuan;

    final hasil = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Jenis Barang'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: namaController,
                  decoration: const InputDecoration(labelText: 'Nama'),
                ),
                const SizedBox(height: 16),
                const Text('Satuan', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                const SizedBox(height: 6),
                SegmentedButton<SatuanBarang>(
                  segments: const [
                    ButtonSegment(value: SatuanBarang.kg, label: Text('Kg')),
                    ButtonSegment(value: SatuanBarang.buah, label: Text('Buah')),
                    ButtonSegment(value: SatuanBarang.liter, label: Text('Liter')),
                  ],
                  selected: {satuanTerpilih},
                  onSelectionChanged: (baru) =>
                      setDialogState(() => satuanTerpilih = baru.first),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hargaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Harga per ${satuanTerpilih.label} (Rp)',
                    prefixText: 'Rp ',
                  ),
                ),
                if (satuanTerpilih != jenis.satuan ||
                    double.tryParse(hargaController.text) != jenis.harga)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      'Perubahan satuan/harga HANYA berlaku untuk setoran BARU. '
                      'Setoran lama tetap memakai satuan & harga aslinya saat itu.',
                      style: TextStyle(fontSize: 11, color: AppColors.orange),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: namaController.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).pop(true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (hasil == true && context.mounted) {
      final namaBaru = namaController.text.trim();
      final hargaBaru = double.tryParse(hargaController.text.replaceAll(',', '.')) ?? jenis.harga;
      final adaPerubahanNama = namaBaru != jenis.nama;

      // Kalau NAMA diubah, tampilkan indikator proses karena batch
      // update ke semua setoran terkait bisa makan waktu sedikit lebih
      // lama dibanding update satu dokumen biasa (perlu ambil semua
      // setoran dulu untuk dicek di memori).
      if (adaPerubahanNama) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memperbarui nama di semua setoran terkait...')),
        );
      }

      await ref.read(jenisBarangRepositoryProvider).ubahJenisBarang(
            id: jenis.id,
            namaLama: jenis.nama,
            namaBaru: namaBaru,
            satuanBaru: satuanTerpilih,
            hargaBaru: hargaBaru,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jenis barang diperbarui')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: AppShadows.card,
      ),
      child: ListTile(
        leading: Icon(
          jenis.satuan == SatuanBarang.kg
              ? Icons.scale_outlined
              : jenis.satuan == SatuanBarang.liter
                  ? Icons.water_drop_outlined
                  : Icons.tag_outlined,
          color: AppColors.green700,
        ),
        title: Text(jenis.nama),
        subtitle: Text(
          '${formatRupiah(jenis.harga)} / ${jenis.satuan.label}',
          style: const TextStyle(fontSize: 11, color: AppColors.green800),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _edit(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.red),
              onPressed: () => _hapus(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
