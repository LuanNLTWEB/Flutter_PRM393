import 'package:url_launcher/url_launcher.dart';

/// Mở Google Maps (app hoặc web) chỉ đường tới nhà khách — UC-MAP-01.
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
    destination = Uri.encodeComponent(address.trim());
  }
  if (destination == null) return false;

  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=$destination&region=vn&travelmode=driving',
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
