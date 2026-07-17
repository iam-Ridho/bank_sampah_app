import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/nasabah_model.dart';
import 'nasabah_repository.dart';

/// Bottom sheet tambah/edit nasabah — dipakai untuk DUA mode (tambah
/// baru kalau `existing` null, edit kalau `existing` terisi).
///
/// Return `NasabahModel` yang baru dibuat/diubah (dengan `id` terisi),
/// supaya pemanggil (mis. picker saat input setoran) bisa langsung
/// memakainya tanpa perlu query ulang.
Future<NasabahModel?> showNasabahFormSheet(BuildContext context, {NasabahModel? existing}) {
  return showModalBottomSheet<NasabahModel>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _NasabahFormSheet(existing: existing),
  );
}

class _NasabahFormSheet extends ConsumerStatefulWidget {
  final NasabahModel? existing;

  const _NasabahFormSheet({this.existing});

  @override
  ConsumerState<_NasabahFormSheet> createState() => _NasabahFormSheetState();
}

class _NasabahFormSheetState extends ConsumerState<_NasabahFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _alamatController;
  late final TextEditingController _noHpController;
  bool _isSaving = false;

  bool get _isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _namaController = TextEditingController(text: e?.nama ?? '');
    _alamatController = TextEditingController(text: e?.alamat ?? '');
    _noHpController = TextEditingController(text: e?.noHp ?? '');
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _noHpController.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final repo = ref.read(nasabahRepositoryProvider);
    final nama = _namaController.text.trim();
    final alamat = _alamatController.text.trim().isEmpty ? null : _alamatController.text.trim();
    final noHp = _noHpController.text.trim().isEmpty ? null : _noHpController.text.trim();

    try {
      if (_isEditMode) {
        await repo.ubahNasabah(widget.existing!.id, {
          'nama': nama,
          'alamat': alamat,
          'noHp': noHp,
        });
        if (mounted) {
          Navigator.of(context).pop(
            NasabahModel(
              id: widget.existing!.id,
              nama: nama,
              alamat: alamat,
              noHp: noHp,
              createdAt: widget.existing!.createdAt,
            ),
          );
        }
      } else {
        final id = await repo.tambahNasabah(nama: nama, alamat: alamat, noHp: noHp);
        if (mounted) {
          Navigator.of(context).pop(
            NasabahModel(id: id, nama: nama, alamat: alamat, noHp: noHp, createdAt: DateTime.now()),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
              child: Row(
                children: [
                  Text(
                    _isEditMode ? 'Edit Nasabah' : 'Tambah Nasabah Baru',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _namaController,
                        decoration: const InputDecoration(labelText: 'Nama Nasabah *'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                        autofocus: !_isEditMode,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _alamatController,
                        decoration: const InputDecoration(labelText: 'Alamat (opsional)'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _noHpController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'No. HP/WA (opsional)'),
                      ),
                    ],
                  ),
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
                      : Text(_isEditMode ? 'Simpan Perubahan' : 'Tambah Nasabah'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
