// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

/// Helper tải file trực tiếp trên trình duyệt Web bằng Blob và AnchorElement.
void downloadFile({
  required String content,
  required String fileName,
  String mimeType = 'text/html;charset=utf-8',
}) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

/// Helper kích hoạt hộp thoại in / xuất PDF của trình duyệt web (Ctrl + P)
void printPage() {
  html.window.print();
}

