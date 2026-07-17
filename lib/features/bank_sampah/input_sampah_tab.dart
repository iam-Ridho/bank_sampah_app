import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/jenis_barang_model.dart';
import '../../models/nasabah_model.dart';
import '../../models/setoran_model.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/currency_formatter.dart';
import '../auth/auth_provider.dart';
import '../nasabah/nasabah_picker_sheet.dart';
import '../nasabah/setoran_repository.dart';
import 'edit_setoran_sheet.dart';
import 'jenis_barang_picker_sheet.dart';

/// Tab Input — gaya "KERANJANG": pilih SATU nasabah dulu, lalu tambah
/// BANYAK item sekaligus (sesuai skenario: "Pak Budi bawa botol kaca
/// 4 buah, botol plastik 0.3kg, kardus 2kg, hvs 1kg" — semua dicatat
/// dalam SATU kunjungan/setoran, bukan satu-satu entri terpisah).
///
/// Subtotal tiap item DIHITUNG OTOMATIS (jumlah x harga jenis barang
/// saat ini) — menghilangkan langkah manual "hitung pakai kalkulator"
/// yang jadi keluhan di alur kerja lama (buku besar -> buku tabungan).
class InputSampahTab extends ConsumerStatefulWidget {
  const InputSampahTab({super.key});

  @override
  ConsumerState<InputSampahTab> createState() => _InputSampahTabState();
}

class _InputSampahTabState extends ConsumerState<InputSampahTab> with AutomaticKeepAliveClientMixin {
  NasabahModel? _nasabah;
  DateTime _tanggal = DateTime.now();
  final List<SetoranItem> _keranjang = [];
  final _catatanController = TextEditingController();
  bool _isSaving = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  double get _totalNilai => _keranjang.fold<double>(0, (sum, i) => sum + i.subtotal);

  Future<void> _pilihNasabah() async {
    // PENGAMANAN 1: kalau keranjang saat ini SUDAH ADA ISI (belum
    // disimpan) dan petugas mencoba ganti nasabah, PERINGATKAN dulu —
    // tanpa ini, item yang belum tersimpan bisa hilang diam-diam, atau
    // lebih parah, salah teratribusi ke nasabah yang berbeda kalau
    // petugas lupa item itu sebenarnya milik nasabah sebelumnya.
    //
    // Skenario nyata: Nasabah A datang, petugas mulai catat 2 item,
    // lalu Nasabah B tiba-tiba datang duluan sebelum A selesai. Petugas
    // TIDAK PERLU membuat B menunggu — tapi HARUS diberi pilihan jelas
    // dulu: simpan dulu punya A (walau baru sebagian), baru layani B.
    if (_keranjang.isNotEmpty && mounted) {
      final lanjut = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ada Item Belum Disimpan'),
          content: Text(
            'Ada ${_keranjang.length} item untuk ${_nasabah?.nama ?? "nasabah ini"} '
            'yang BELUM disimpan (${formatRupiah(_totalNilai)}). Mengganti nasabah '
            'akan MENGHAPUS item-item ini dari layar.\n\n'
            'Simpan dulu setoran ini kalau nasabah tersebut sudah selesai/mau '
            'pergi, atau lanjutkan mengisi keranjangnya nanti kalau dia balik lagi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal, Tetap di Sini'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ganti & Hapus Item'),
            ),
          ],
        ),
      );
      if (lanjut != true || !mounted) return;
    }

    final hasil = await showNasabahPickerSheet(context);
    if (hasil == null || !mounted) return;

    // PENGAMANAN 2: cek apakah nasabah ini SUDAH punya setoran HARI
    // INI — kalau iya, tawarkan untuk MELANJUTKAN setoran itu (lewat
    // sheet edit yang sudah ada), bukan bikin setoran baru terpisah.
    // Ini yang menjawab skenario "nasabah pulang-balik ambil sisa
    // barang di rumahnya": TIDAK PERLU dibatalkan — simpan dulu
    // sebagian, nanti saat balik, sistem otomatis menawarkan untuk
    // menambah ke setoran yang sama hari itu.
    final setoranSemua = ref.read(setoranStreamProvider).value?.items ?? [];
    final sekarang = DateTime.now();
    final setoranHariIniNasabah = setoranSemua.where((s) {
      return s.nasabahId == hasil.id &&
          s.tanggal.year == sekarang.year &&
          s.tanggal.month == sekarang.month &&
          s.tanggal.day == sekarang.day;
    }).toList();

    if (setoranHariIniNasabah.isNotEmpty && mounted) {
      final existing = setoranHariIniNasabah.first;
      final lanjutkanYangLama = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sudah Ada Setoran Hari Ini'),
          content: Text(
            '${hasil.nama} sudah tercatat ${existing.items.length} jenis barang '
            'hari ini (${formatRupiah(existing.totalNilai)}). Kemungkinan ini '
            'kunjungan lanjutan (mis. baru pulang ambil sisa barang).\n\n'
            'Tambahkan ke setoran yang sama, atau buat setoran terpisah?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Buat Terpisah'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Tambahkan ke Situ'),
            ),
          ],
        ),
      );

      if (lanjutkanYangLama == true && mounted) {
        // Buka sheet edit setoran yang SUDAH ADA — pakai ulang UI yang
        // sama persis dengan "tap untuk edit" di tab Riwayat, supaya
        // tidak menduplikasi logic tambah-item di dua tempat berbeda.
        await showEditSetoranSheet(context, existing);
        // Keranjang di tab Input TETAP KOSONG setelah ini — petugas
        // baru saja menambahkan item lewat sheet edit, bukan lewat
        // form ini, jadi tidak perlu set _nasabah di sini.
        return;
      }
      // Kalau pilih "Buat Terpisah", lanjut normal ke bawah (assign
      // nasabah baru, keranjang kosong, mulai setoran baru untuk hari
      // yang sama — sengaja diizinkan, mungkin memang ada alasan
      // petugas ingin mencatatnya terpisah).
    }

    setState(() {
      _nasabah = hasil;
      _keranjang.clear();
    });
  }

  Future<void> _pilihTanggal() async {
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (hasil != null) setState(() => _tanggal = hasil);
  }

  Future<void> _tambahItem() async {
    final jenis = await showJenisBarangPickerSheet(context);
    if (jenis == null || !mounted) return;

    // Peringatkan kalau jenis barang belum diberi harga (harga = 0) —
    // menambah item begini akan menghasilkan subtotal Rp0 yang keliru.
    if (jenis.harga <= 0) {
      final lanjut = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Harga Belum Diatur'),
          content: Text(
            'Jenis "${jenis.nama}" belum punya harga (Rp0). Subtotalnya '
            'akan tercatat Rp0. Atur harga dulu lewat menu Kelola Jenis '
            'Barang, atau lanjutkan (bisa diperbaiki nanti).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      );
      if (lanjut != true || !mounted) return;
    }

    final jumlah = await _tanyaJumlah(jenis);
    if (jumlah == null || !mounted) return;

    setState(() {
      // Kalau jenis yang sama SUDAH ada di keranjang, GABUNGKAN
      // jumlahnya (bukan bikin baris duplikat) — mis. petugas ingat
      // ada tambahan kardus lagi setelah sempat menambahkan kardus
      // sebelumnya di kunjungan yang sama.
      final indexAda = _keranjang.indexWhere((i) => i.jenisBarang == jenis.nama);
      if (indexAda != -1) {
        final lama = _keranjang[indexAda];
        _keranjang[indexAda] = SetoranItem(
          jenisBarang: lama.jenisBarang,
          satuan: lama.satuan,
          jumlah: lama.jumlah + jumlah,
          harga: jenis.harga, // pakai harga TERBARU kalau sempat diubah
        );
      } else {
        _keranjang.add(SetoranItem(
          jenisBarang: jenis.nama,
          satuan: jenis.satuan,
          jumlah: jumlah,
          harga: jenis.harga,
        ));
      }
    });
  }

  Future<double?> _tanyaJumlah(JenisBarangModel jenis) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Jumlah ${jenis.nama}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: jenis.satuan == SatuanBarang.buah
                ? TextInputType.number
                : const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: jenis.satuan == SatuanBarang.kg
                  ? 'Jumlah (kg)'
                  : jenis.satuan == SatuanBarang.liter
                      ? 'Jumlah (liter)'
                      : 'Jumlah (buah)',
              suffixText: '@ ${formatRupiah(jenis.harga)} / ${jenis.satuan.label}',
            ),
            validator: (v) {
              final n = double.tryParse((v ?? '').replaceAll(',', '.'));
              if (n == null || n <= 0) {
                return jenis.satuan == SatuanBarang.buah
                    ? 'Masukkan jumlah buah yang valid'
                    : jenis.satuan == SatuanBarang.liter
                        ? 'Masukkan jumlah liter yang valid'
                        : 'Masukkan jumlah kg yang valid';
              }
              if (jenis.satuan == SatuanBarang.buah && n != n.roundToDouble()) {
                return 'Jumlah buah harus bilangan bulat';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final n = double.parse(controller.text.replaceAll(',', '.'));
              Navigator.of(context).pop(n);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _hapusItem(int index) {
    setState(() => _keranjang.removeAt(index));
  }

  Future<void> _simpanSetoran() async {
    if (_nasabah == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih nasabah terlebih dahulu')),
      );
      return;
    }
    if (_keranjang.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal satu item')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final currentUser = ref.read(authStateProvider).value;

    try {
      final setoran = SetoranModel.baru(
        nasabahId: _nasabah!.id,
        nasabahNama: _nasabah!.nama,
        tanggal: _tanggal,
        items: List.of(_keranjang),
        catatan: _catatanController.text.trim().isEmpty ? null : _catatanController.text.trim(),
        createdBy: currentUser?.uid ?? 'unknown',
        createdByEmail: currentUser?.email,
      );
      await ref.read(setoranRepositoryProvider).catatSetoran(setoran);

      if (mounted) {
        final namaTersimpan = _nasabah!.nama;
        final totalTersimpan = _totalNilai;
        setState(() {
          _nasabah = null;
          _keranjang.clear();
          _catatanController.clear();
          // Tanggal SENGAJA TIDAK direset — kunjungan berikutnya
          // kemungkinan besar masih di hari yang sama.
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Setoran $namaTersimpan tercatat (${formatRupiah(totalTersimpan)})',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              InkWell(
                onTap: _pilihNasabah,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Nasabah *',
                    suffixIcon: Icon(Icons.search, size: 20),
                  ),
                  child: Text(
                    _nasabah?.nama ?? 'Ketuk untuk pilih nasabah',
                    style: TextStyle(color: _nasabah == null ? AppColors.gray400 : null),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pilihTanggal,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Tanggal'),
                  child: Text('${_tanggal.day}/${_tanggal.month}/${_tanggal.year}'),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Item Dibawa',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  OutlinedButton.icon(
                    onPressed: _tambahItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Item'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_keranjang.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Belum ada item. Tekan "Tambah Item" untuk mulai mencatat.',
                    style: TextStyle(fontSize: 13, color: AppColors.gray500),
                  ),
                )
              else
                ..._keranjang.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Dismissible(
                    key: ValueKey('${item.jenisBarang}-$index'),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _hapusItem(index),
                    background: Container(
                      color: AppColors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        boxShadow: AppShadows.card,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.satuan == SatuanBarang.kg
                                ? Icons.scale_outlined
                                : item.satuan == SatuanBarang.liter
                                    ? Icons.water_drop_outlined
                                    : Icons.tag_outlined,
                            size: 16,
                            color: AppColors.gray400,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.jenisBarang, style: const TextStyle(fontSize: 13)),
                                Text(
                                  item.satuan == SatuanBarang.buah
                                      ? '${item.jumlah.toStringAsFixed(0)} buah x ${formatRupiah(item.harga)}'
                                      : item.satuan == SatuanBarang.liter
                                          ? '${item.jumlah.toStringAsFixed(1)} liter x ${formatRupiah(item.harga)}'
                                          : '${item.jumlah.toStringAsFixed(1)} kg x ${formatRupiah(item.harga)}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.gray500),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatRupiah(item.subtotal),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.green800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 14),
              TextField(
                controller: _catatanController,
                decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 11, color: AppColors.gray500)),
                    Text(
                      formatRupiah(_totalNilai),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.green900,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _isSaving ? null : _simpanSetoran,
                icon: _isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check, size: 18),
                label: const Text('Simpan Setoran'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
