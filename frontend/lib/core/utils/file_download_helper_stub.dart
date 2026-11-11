/// Helper tải file cho các nền tảng native (Mobile / Desktop).
void downloadFile({
  required String content,
  required String fileName,
  String mimeType = 'text/html;charset=utf-8',
}) {
  // Trên mobile/desktop, có thể tích hợp path_provider nếu cần ghi file vào bộ nhớ
}

/// Helper in trang / xuất PDF trên native
void printPage() {
  // Không khả dụng trực tiếp trên native nếu không có thư viện in ấn chuyên dụng
}

