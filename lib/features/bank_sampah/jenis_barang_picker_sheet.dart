import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/jenis_barang_model.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/currency_formatter.dart';
import '../../shared/widgets/app_state_widgets.dart';
import 'jenis_barang_repository.dart';
import 'kelola_jenis_barang_screen.dart';

/// Bottom sheet pencarian + pilih jenis barang — BERBEDA dari
/// nasabah_picker_sheet.dart karena di sini user BISA MENAMBAH jenis
/// baru langsung dari pencarian. Perbedaan ini disengaja: jenis barang
/// sampah memang dirancang dinamis dan low-friction untuk ditambah
/// petugas kapan saja.
///
/// Return `JenisBarangModel` LENGKAP (bukan cuma nama) — form input
/// setoran butuh tahu SATUAN dan HARGA jenis yang dipilih supaya bisa
/// menghitung subtotal otomatis.
Future<JenisBarangModel?> showJenisBarangPickerSheet(BuildContext context) {
  return showModalBottomSheet<JenisBarangModel>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const _JenisBarangPickerSheet(),
  );
}

class _JenisBarangPickerSheet extends ConsumerStatefulWidget {
  const _JenisBarangPickerSheet();

  @override
  ConsumerState<_JenisBarangPickerSheet> createState() => _JenisBarangPickerSheetState();
}

class _JenisBarangPickerSheetState extends ConsumerState<_JenisBarangPickerSheet> {
  String _kataKunci = '';
  bool _sedangMenambah = false;

  /// Tanya satuan DAN harga sekaligus lewat dialog kecil sebelum jenis
  /// baru benar-benar dibuat — dialog, bukan sheet baru, supaya tidak
  /// terasa berlapis.
  Future<void> _tambahJenisBaru(String nama) async {
    final hasil = await showDialog<({SatuanBarang satuan, double harga})>(
      context: context,
      builder: (context) => _DialogTambahJenis(nama: nama),
    );
    if (hasil == null || !mounted) return; // dibatalkan

    setState(() => _sedangMenambah = true);
    try {
      await ref
          .read(jenisBarangRepositoryProvider)
          .tambahJenisBarang(nama, hasil.satuan, hasil.harga);
      if (mounted) {
        Navigator.of(context).pop(
          JenisBarangModel(
            id: '',
            nama: nama.trim(),
            satuan: hasil.satuan,
            harga: hasil.harga,
            createdAt: DateTime.now(),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sedangMenambah = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncResult = ref.watch(jenisBarangStreamProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Text('Pilih Jenis Barang',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Kelola jenis barang (edit nama/satuan/harga, hapus)',
                    icon: const Icon(Icons.settings_outlined, size: 20),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const KelolaJenisBarangScreen()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: false,
                decoration: const InputDecoration(
                  hintText: 'Cari atau ketik jenis baru...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _kataKunci = v),
              ),
            ),
            Expanded(
              child: asyncResult.when(
                loading: () => const AppLoadingState(),
                error: (_, __) => const AppErrorState(message: 'Gagal memuat daftar jenis barang.'),
                data: (result) {
                  final query = _kataKunci.trim().toLowerCase();
                  final items = query.isEmpty
                      ? result.items
                      : result.items.where((j) => j.nama.toLowerCase().contains(query)).toList();

                  // Cek apakah kata kunci yang diketik PERSIS cocok
                  // (case-insensitive) dengan jenis yang sudah ada —
                  // kalau cocok, jangan tawarkan "tambah baru" supaya
                  // tidak membuat duplikat nyaris-identik.
                  final sudahAdaPersisSama =
                      result.items.any((j) => j.nama.toLowerCase() == query);
                  final bisaTambahBaru = query.isNotEmpty && !sudahAdaPersisSama;

                  return ListView(
                    controller: scrollController,
                    children: [
                      if (bisaTambahBaru)
                        ListTile(
                          leading: _sedangMenambah
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add_circle_outline, color: AppColors.green700),
                          title: Text('Tambah jenis baru: "${_kataKunci.trim()}"'),
                          onTap: _sedangMenambah ? null : () => _tambahJenisBaru(_kataKunci.trim()),
                        ),
                      if (items.isEmpty && !bisaTambahBaru)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: AppEmptyState(
                            icon: Icons.search_off,
                            message: 'Belum ada jenis barang. Ketik nama untuk menambah yang baru.',
                          ),
                        ),
                      ...items.map(
                        (jenis) => ListTile(
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
                          onTap: () => Navigator.of(context).pop(jenis),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Dialog kecil untuk input satuan + harga saat membuat jenis baru.
/// Dipisah jadi StatefulWidget sendiri karena butuh state lokal untuk
/// pilihan satuan dan input harga sebelum dikonfirmasi bersamaan.
class _DialogTambahJenis extends StatefulWidget {
  final String nama;

  const _DialogTambahJenis({required this.nama});

  @override
  State<_DialogTambahJenis> createState() => _DialogTambahJenisState();
}

class _DialogTambahJenisState extends State<_DialogTambahJenis> {
  SatuanBarang _satuan = SatuanBarang.kg;
  final _hargaController = TextEditingController();

  @override
  void dispose() {
    _hargaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Jenis Baru: "${widget.nama}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Satuan', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
          const SizedBox(height: 6),
          SegmentedButton<SatuanBarang>(
            segments: const [
              ButtonSegment(value: SatuanBarang.kg, label: Text('Kg')),
              ButtonSegment(value: SatuanBarang.buah, label: Text('Buah')),
              ButtonSegment(value: SatuanBarang.liter, label: Text('Liter')),
            ],
            selected: {_satuan},
            onSelectionChanged: (baru) => setState(() => _satuan = baru.first),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _hargaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Harga per ${_satuan.label} (Rp)',
              prefixText: 'Rp ',
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final harga = double.tryParse(_hargaController.text.replaceAll(',', '.')) ?? 0;
            Navigator.of(context).pop((satuan: _satuan, harga: harga));
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
