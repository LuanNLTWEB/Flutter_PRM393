import 'package:url_launcher/url_launcher.dart';

/// Dọn chuỗi địa chỉ trước khi gửi cho Google Maps geocode.
///
/// Chỉ cắt hậu tố liên hệ ` (Tên - 0912345678)` (được nối vào field `address`
/// khi tạo yêu cầu) — phần địa chỉ giữ nguyên.
String cleanAddressForMaps(String address) {
  var cleaned = address.trim();
  // Cắt nhóm ngoặc cuối chứa số điện thoại: " (Phúc An - 0912345678)"
  cleaned = cleaned.replaceFirst(RegExp(r'\s*\([^()]*\d{6,}[^()]*\)\s*$'), '');
  return cleaned.trim();
}

/// Mở Google Maps (app hoặc web) chỉ đường tới nhà khách — UC-WRK-02.
///
/// Ưu tiên tọa độ [latitude]/[longitude] nếu có; không thì dùng [address]
/// (Google Maps tự geocode — không bắt buộc phải có GPS).
Future<bool> openGoogleMapsDirections({
  double? latitude,
  double? longitude,
  String? address,
}) async {
  String? destination;
  if (latitude != null && longitude != null) {
    destination = '$latitude,$longitude';
  } else if (address != null && address.trim().isNotEmpty) {
    final cleaned = cleanAddressForMaps(address);
    if (cleaned.isEmpty) return false;
    destination = Uri.encodeComponent(cleaned);
  }
  if (destination == null) return false;

  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=$destination&region=vn&travelmode=driving',
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
