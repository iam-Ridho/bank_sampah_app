import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/jenis_barang_model.dart';
import '../../models/setoran_model.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/currency_formatter.dart';
import '../nasabah/nasabah_picker_sheet.dart';
import '../nasabah/setoran_repository.dart';
import 'jenis_barang_picker_sheet.dart';

/// Bottom sheet EDIT satu setoran yang sudah tercatat — bisa ubah
/// nasabah, tanggal, catatan, DAN rincian item (tambah/hapus/ubah
/// jumlah). Dipanggil dengan TAP pada kartu setoran di Riwayat
/// (swipe tetap untuk hapus seluruh setoran).
///
/// Menutup celah: sebelumnya satu-satunya cara memperbaiki salah input
/// (mis. salah pilih nasabah, atau item terlewat/salah jumlah) adalah
/// hapus seluruh setoran lalu input ulang dari awal.
Future<void> showEditSetoranSheet(BuildContext context, SetoranModel setoran) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _EditSetoranSheet(setoran: setoran),
  );
}

class _EditSetoranSheet extends ConsumerStatefulWidget {
  final SetoranModel setoran;

  const _EditSetoranSheet({required this.setoran});

  @override
  ConsumerState<_EditSetoranSheet> createState() => _EditSetoranSheetState();
}

class _EditSetoranSheetState extends ConsumerState<_EditSetoranSheet> {
  late String _nasabahId;
  late String _nasabahNama;
  late DateTime _tanggal;
  late List<SetoranItem> _items;
  late final TextEditingController _catatanController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nasabahId = widget.setoran.nasabahId;
    _nasabahNama = widget.setoran.nasabahNama;
    _tanggal = widget.setoran.tanggal;
    _items = List.of(widget.setoran.items);
    _catatanController = TextEditingController(text: widget.setoran.catatan ?? '');
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  double get _totalNilai => _items.fold<double>(0, (sum, i) => sum + i.subtotal);

  Future<void> _gantiNasabah() async {
    final hasil = await showNasabahPickerSheet(context);
    if (hasil != null) {
      setState(() {
        _nasabahId = hasil.id;
        _nasabahNama = hasil.nama;
      });
    }
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

    final jumlah = await _tanyaJumlah(jenis);
    if (jumlah == null || !mounted) return;

    setState(() {
      final indexAda = _items.indexWhere((i) => i.jenisBarang == jenis.nama);
      if (indexAda != -1) {
        final lama = _items[indexAda];
        _items[indexAda] = SetoranItem(
          jenisBarang: lama.jenisBarang,
          satuan: lama.satuan,
          jumlah: lama.jumlah + jumlah,
          harga: jenis.harga,
        );
      } else {
        _items.add(SetoranItem(
          jenisBarang: jenis.nama,
          satuan: jenis.satuan,
          jumlah: jumlah,
          harga: jenis.harga,
        ));
      }
    });
  }

  Future<double?> _tanyaJumlah(JenisBarangModel jenis, {double? nilaiAwal}) async {
    final controller = TextEditingController(
      text: nilaiAwal != null
          ? (jenis.satuan == SatuanBarang.buah ? nilaiAwal.toStringAsFixed(0) : nilaiAwal.toString())
          : '',
    );
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
              if (n == null || n <= 0) return 'Masukkan jumlah yang valid';
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
              Navigator.of(context).pop(double.parse(controller.text.replaceAll(',', '.')));
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _editJumlahItem(int index) async {
    final item = _items[index];
    // Bangun JenisBarangModel sementara dari data item (untuk dialog
    // jumlah) — harga yang dipakai tetap harga ASLI item ini (bukan
    // harga jenis barang terkini), supaya tidak diam-diam mengubah
    // nilai transaksi lama hanya karena mengedit jumlahnya saja.
    final jenisSementara = JenisBarangModel(
      id: '',
      nama: item.jenisBarang,
      satuan: item.satuan,
      harga: item.harga,
      createdAt: DateTime.now(),
    );
    final jumlahBaru = await _tanyaJumlah(jenisSementara, nilaiAwal: item.jumlah);
    if (jumlahBaru == null) return;

    setState(() {
      _items[index] = SetoranItem(
        jenisBarang: item.jenisBarang,
        satuan: item.satuan,
        jumlah: jumlahBaru,
        harga: item.harga,
      );
    });
  }

  void _hapusItem(int index) {
    setState(() => _items.removeAt(index));
  }

  Future<void> _simpan() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setoran harus punya minimal satu item')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(setoranRepositoryProvider).ubahSetoran(widget.setoran.id, {
        'nasabahId': _nasabahId,
        'nasabahNama': _nasabahNama,
        'tanggal': Timestamp.fromDate(_tanggal),
        'items': _items.map((i) => i.toMap()).toList(),
        'totalNilai': _totalNilai,
        'catatan': _catatanController.text.trim().isEmpty ? null : _catatanController.text.trim(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setoran diperbarui')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
              child: Row(
                children: [
                  Text('Edit Setoran', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: _gantiNasabah,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Nasabah'),
                        child: Text(_nasabahNama),
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
                        Text('Item', style: Theme.of(context).textTheme.titleMedium),
                        OutlinedButton.icon(
                          onPressed: _tambahItem,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _editJumlahItem(index),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.jenisBarang, style: const TextStyle(fontSize: 13)),
                                    Text(
                                      item.satuan == SatuanBarang.kg
                                          ? '${item.jumlah.toStringAsFixed(1)} kg x ${formatRupiah(item.harga)}'
                                          : '${item.jumlah.toStringAsFixed(0)} buah x ${formatRupiah(item.harga)}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.gray500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              formatRupiah(item.subtotal),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                              onPressed: () => _hapusItem(index),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _catatanController,
                      decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          formatRupiah(_totalNilai),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.green900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _simpan,
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan Perubahan'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
