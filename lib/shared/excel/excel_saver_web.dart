import 'dart:html' as html;

Future<void> saveAndShareExcel({
  required List<int> bytes,
  required String filename,
  required String judulLaporan,
}) async {
  final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  html.AnchorElement(href: url)
    ..setAttribute("download", filename)
    ..click();
    
  html.Url.revokeObjectUrl(url);
}
