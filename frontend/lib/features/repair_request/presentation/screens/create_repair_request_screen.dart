import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/service_category_model.dart';
import '../widgets/image_picker_box_widget.dart';
import '../widgets/schedule_time_slot_picker.dart';
import 'request_preview_screen.dart';

/// Màn hình tạo yêu cầu sửa chữa (Mô tả triệu chứng & Mức độ khẩn cấp)
class CreateRepairRequestScreen extends StatefulWidget {
  final ServiceCategoryModel preselectedCategory;

  const CreateRepairRequestScreen({
    super.key,
    required this.preselectedCategory,
  });

  @override
  State<CreateRepairRequestScreen> createState() => _CreateRepairRequestScreenState();
}

class _CreateRepairRequestScreenState extends State<CreateRepairRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  String _urgency = 'medium';
  DateTime? _preferredTime;
  List<XFile> _selectedImages = [];

  static const String _addressStorageKey = 'homefix_saved_repair_addresses';
  List<Map<String, dynamic>> _savedAddressBook = [];

  static const List<Map<String, dynamic>> _urgencyOptions = [
    {
      'value': 'low',
      'label': 'Thấp',
      'icon': Icons.schedule_outlined,
      'color': Color(0xFF10B981),
      'desc': 'Không gấp, xử lý khi thuận tiện',
    },
    {
      'value': 'medium',
      'label': 'Bình thường',
      'icon': Icons.info_outline,
      'color': Color(0xFF2563EB),
      'desc': 'Cần sửa trong 1-2 ngày tới',
    },
    {
      'value': 'high',
      'label': 'Khẩn cấp',
      'icon': Icons.priority_high_rounded,
      'color': Color(0xFFF59E0B),
      'desc': 'Cần thợ đến kiểm tra ngay trong ngày',
    },
    {
      'value': 'emergency',
      'label': 'Cấp cứu',
      'icon': Icons.warning_amber_rounded,
      'color': Color(0xFFDC2626),
      'desc': 'Nguy hiểm, chập cháy, cần xử lý tức thì',
    },
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = '';
    _loadSavedAddresses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Đọc danh sách địa chỉ thực tế đã lưu từ SharedPreferences
  Future<void> _loadSavedAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_addressStorageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr);
        if (mounted) {
          setState(() {
            _savedAddressBook = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          });
        }
      }
    } catch (_) {}
  }

  /// Ghi danh sách địa chỉ vào bộ nhớ SharedPreferences
  Future<void> _saveAddressesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_addressStorageKey, jsonEncode(_savedAddressBook));
    } catch (_) {}
  }

  /// Xóa địa chỉ khỏi danh bạ và cập nhật đồng thời modal lẫn màn hình chính
  void _deleteSavedAddress(int index, void Function(void Function()) setModalState) {
    final item = _savedAddressBook[index];
    final recipientName = item['name'] as String? ?? 'người nhận';

    setState(() {
      _savedAddressBook.removeAt(index);
    });
    setModalState(() {});
    _saveAddressesToStorage();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã xóa địa chỉ của "$recipientName" khỏi danh bạ'),
        backgroundColor: Colors.grey.shade800,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Kiểm tra chuỗi spam, lặp ký tự liên tiếp hoặc quá ít ký tự phân biệt
  bool _isSpamContent(String text) {
    final clean = text.replaceAll(RegExp(r'\s+'), '');
    if (clean.isEmpty) return true;

    // Ký tự lặp lại liên tiếp từ 4 lần trở lên (vd: aaaa, 1111)
    if (RegExp(r'(.)\1{3,}').hasMatch(clean)) return true;

    // Chuỗi dài từ 6 ký tự trở lên nhưng chỉ có dưới 3 ký tự khác nhau
    final uniqueLetters = clean.toLowerCase().split('').toSet();
    if (clean.length >= 6 && uniqueLetters.length < 3) return true;

    return false;
  }


  /// Danh sách 34 tỉnh / thành phố thực hiện sắp xếp, sáp nhập ĐVHC theo Nghị quyết của Quốc hội
  static final List<Map<String, dynamic>> _mergedProvinces = [
    {'code': 79, 'name': 'Thành phố Hồ Chí Minh'},
    {'code': 1, 'name': 'Thành phố Hà Nội'},
    {'code': 48, 'name': 'Thành phố Đà Nẵng'},
    {'code': 31, 'name': 'Thành phố Hải Phòng'},
    {'code': 92, 'name': 'Thành phố Cần Thơ'},
    {'code': 77, 'name': 'Tỉnh Bà Rịa - Vũng Tàu'},
    {'code': 24, 'name': 'Tỉnh Bắc Giang'},
    {'code': 27, 'name': 'Tỉnh Bắc Ninh'},
    {'code': 83, 'name': 'Tỉnh Bến Tre'},
    {'code': 52, 'name': 'Tỉnh Bình Định'},
    {'code': 74, 'name': 'Tỉnh Bình Dương'},
    {'code': 60, 'name': 'Tỉnh Bình Thuận'},
    {'code': 96, 'name': 'Tỉnh Cà Mau'},
    {'code': 66, 'name': 'Tỉnh Đắk Lắk'},
    {'code': 75, 'name': 'Tỉnh Đồng Nai'},
    {'code': 87, 'name': 'Tỉnh Đồng Tháp'},
    {'code': 64, 'name': 'Tỉnh Gia Lai'},
    {'code': 33, 'name': 'Tỉnh Hưng Yên'},
    {'code': 56, 'name': 'Tỉnh Khánh Hòa'},
    {'code': 68, 'name': 'Tỉnh Lâm Đồng'},
    {'code': 80, 'name': 'Tỉnh Long An'},
    {'code': 36, 'name': 'Tỉnh Nam Định'},
    {'code': 40, 'name': 'Tỉnh Nghệ An'},
    {'code': 37, 'name': 'Tỉnh Ninh Bình'},
    {'code': 25, 'name': 'Tỉnh Phú Thọ'},
    {'code': 44, 'name': 'Tỉnh Quảng Bình'},
    {'code': 49, 'name': 'Tỉnh Quảng Nam'},
    {'code': 51, 'name': 'Tỉnh Quảng Ngãi'},
    {'code': 22, 'name': 'Tỉnh Quảng Ninh'},
    {'code': 45, 'name': 'Tỉnh Quảng Trị'},
    {'code': 34, 'name': 'Tỉnh Thái Bình'},
    {'code': 19, 'name': 'Tỉnh Thái Nguyên'},
    {'code': 82, 'name': 'Tỉnh Tiền Giang'},
    {'code': 86, 'name': 'Tỉnh Vĩnh Long'},
  ];

  /// Danh mục Phường / Xã cơ sở sau sắp xếp theo tỉnh (dự phòng tức thì offline)
  static final Map<int, List<String>> _defaultWardsByProvince = {
    79: [
      'Phường Bến Nghé (Quận 1)',
      'Phường Bến Thành (Quận 1)',
      'Phường Tân Định (Quận 1)',
      'Phường Đa Kao (Quận 1)',
      'Phường Phạm Ngũ Lão (Quận 1)',
      'Phường Võ Thị Sáu (Quận 3)',
      'Phường 1 (Quận 3)',
      'Phường 2 (Quận 3)',
      'Phường 1 (Quận 5)',
      'Phường 2 (Quận 5)',
      'Phường 5 (Quận 5)',
      'Phường An Khánh (TP. Thủ Đức)',
      'Phường Thảo Điền (TP. Thủ Đức)',
      'Phường Hiệp Phú (TP. Thủ Đức)',
      'Phường Linh Trung (TP. Thủ Đức)',
      'Phường 1 (Quận Tân Bình)',
      'Phường 2 (Quận Tân Bình)',
      'Phường 1 (Quận Bình Thạnh)',
      'Phường 11 (Quận Bình Thạnh)',
      'Phường 1 (Quận Gò Vấp)',
      'Phường 3 (Quận Gò Vấp)',
    ],
    1: [
      'Phường Tràng Tiền (Quận Hoàn Kiếm)',
      'Phường Hàng Bạc (Quận Hoàn Kiếm)',
      'Phường Hàng Đào (Quận Hoàn Kiếm)',
      'Phường Kim Mã (Quận Ba Đình)',
      'Phường Giảng Võ (Quận Ba Đình)',
      'Phường Liễu Giai (Quận Ba Đình)',
      'Phường Dịch Vọng (Quận Cầu Giấy)',
      'Phường Dịch Vọng Hậu (Quận Cầu Giấy)',
      'Phường Trung Hòa (Quận Cầu Giấy)',
      'Phường Khương Đình (Quận Thanh Xuân)',
      'Phường Quang Trung (Quận Đống Đa)',
      'Phường Hà Đông (Quận Hà Đông)',
      'Phường Hoàng Mai (Quận Hoàng Mai)',
    ],
    48: [
      'Phường Hải Châu 1 (Quận Hải Châu)',
      'Phường Hải Châu 2 (Quận Hải Châu)',
      'Phường Thạch Thang (Quận Hải Châu)',
      'Phường Thanh Khê Đông (Quận Thanh Khê)',
      'Phường An Hải Bắc (Quận Sơn Trà)',
      'Phường Mỹ An (Quận Ngũ Hành Sơn)',
      'Phường Hòa Khánh Bắc (Quận Liên Chiểu)',
      'Phường Khuê Trung (Quận Cẩm Lệ)',
    ],
    31: [
      'Phường Hoàng Văn Thụ (Quận Hồng Bàng)',
      'Phường Hạ Lý (Quận Hồng Bàng)',
      'Phường Lạc Viên (Quận Ngô Quyền)',
      'Phường Cầu Đất (Quận Ngô Quyền)',
      'Phường An Dương (Quận Lê Chân)',
      'Phường Đổng Quốc Bình (Quận Ngô Quyền)',
    ],
    92: [
      'Phường Tân An (Quận Ninh Kiều)',
      'Phường An Lạc (Quận Ninh Kiều)',
      'Phường Xuân Khánh (Quận Ninh Kiều)',
      'Phường Hưng Lợi (Quận Ninh Kiều)',
      'Phường Trà Nóc (Quận Bình Thủy)',
      'Phường Lê Bình (Quận Cái Răng)',
    ],
    74: [
      'Phường Phú Cường (TP. Thủ Dầu Một)',
      'Phường Hiệp Thành (TP. Thủ Dầu Một)',
      'Phường Chánh Nghĩa (TP. Thủ Dầu Một)',
      'Phường Dĩ An (TP. Dĩ An)',
      'Phường Lái Thiêu (TP. Thuận An)',
      'Phường Bến Cát (TP. Bến Cát)',
      'Phường Tân Uyên (TP. Tân Uyên)',
    ],
    75: [
      'Phường Biên Hòa',
      'Phường Quyết Thắng (TP. Biên Hòa)',
      'Phường Tân Phong (TP. Biên Hòa)',
      'Phường Hố Nai (TP. Biên Hòa)',
      'Phường Long Khánh (TP. Long Khánh)',
    ],
    77: [
      'Phường 1 (TP. Vũng Tàu)',
      'Phường 2 (TP. Vũng Tàu)',
      'Phường Thắng Tam (TP. Vũng Tàu)',
      'Phường Phước Trung (TP. Bà Rịa)',
      'Phường Long Toàn (TP. Bà Rịa)',
    ],
    56: [
      'Phường Lộc Thọ (TP. Nha Trang)',
      'Phường Phước Tiến (TP. Nha Trang)',
      'Phường Vĩnh Hải (TP. Nha Trang)',
      'Phường Cam Ranh (TP. Cam Ranh)',
    ],
    68: [
      'Phường 1 (TP. Đà Lạt)',
      'Phường 2 (TP. Đà Lạt)',
      'Phường 10 (TP. Đà Lạt)',
      'Phường B\'Lao (TP. Bảo Lộc)',
    ],
    22: [
      'Phường Bạch Đằng (TP. Hạ Long)',
      'Phường Hồng Gai (TP. Hạ Long)',
      'Phường Bãi Cháy (TP. Hạ Long)',
      'Phường Cẩm Phả (TP. Cẩm Phả)',
      'Phường Uông Bí (TP. Uông Bí)',
    ],
    27: [
      'Phường Tiền An (TP. Bắc Ninh)',
      'Phường Ninh Xá (TP. Bắc Ninh)',
      'Phường Từ Sơn (TP. Từ Sơn)',
    ],
  };

  /// Tải thêm danh sách Phường / Xã từ Open API
  Future<List<String>> _fetchWardsFromApi(int provinceCode) async {
    try {
      final res = await http
          .get(Uri.parse('https://provinces.open-api.vn/api/v1/p/$provinceCode?depth=3'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final districts = data['districts'] as List? ?? [];
        final List<String> wards = [];
        for (final d in districts) {
          final dName = d['name'] ?? '';
          final wList = d['wards'] as List? ?? [];
          for (final w in wList) {
            final wName = w['name'] ?? '';
            if (wName.toString().isNotEmpty) {
              wards.add('$wName ($dName)');
            }
          }
        }
        if (wards.isNotEmpty) return wards;
      }
    } catch (_) {}
    return [];
  }

  /// Mở hộp thoại Danh bạ địa chỉ (AlertDialog cơ bản)
  Future<void> _showAddressBookPicker() async {
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.contacts, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Danh bạ địa chỉ (${_savedAddressBook.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: _savedAddressBook.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_off, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              'Chưa có địa chỉ nào được lưu',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Bấm "Thêm mới" bên dưới để nhập địa chỉ của bạn',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.5,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: _savedAddressBook.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final name = item['name'] as String? ?? 'Người nhận';
                              final phone = item['phone'] as String? ?? '';
                              final address = item['address'] as String? ?? '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.location_on, color: AppTheme.primaryColor),
                                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text(
                                    phone.isNotEmpty ? '$address\nSĐT: $phone' : address,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () {
                                      _deleteSavedAddress(index, setDialogState);
                                    },
                                  ),
                                  onTap: () {
                                    Navigator.pop(dialogCtx);
                                    setState(() {
                                      _addressController.text = phone.isNotEmpty
                                          ? '$address ($name - $phone)'
                                          : address;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('address_picker_add_new_button'),
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      _showAddNewAddressDialog();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Mở hộp thoại Thêm địa chỉ mới (AlertDialog cơ bản có chọn Tỉnh/Thành và Phường/Xã)
  Future<void> _showAddNewAddressDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressDetailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String? selectedProvince;
    String? selectedWard;
    List<String> currentWards = [];

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Thêm địa chỉ mới',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),

                        // 1. Họ và tên
                        TextFormField(
                          key: const Key('add_address_name_field'),
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Họ và tên *',
                            hintText: 'VD: Nguyễn Văn A',
                            prefixIcon: Icon(Icons.person_outline, size: 20),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final val = v?.trim() ?? '';
                            if (val.isEmpty) return 'Vui lòng nhập họ và tên';
                            if (val.length < 2) return 'Họ tên quá ngắn';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // 2. Số điện thoại liên hệ
                        TextFormField(
                          key: const Key('add_address_phone_field'),
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại liên hệ *',
                            hintText: 'VD: 0901234567',
                            prefixIcon: Icon(Icons.phone_outlined, size: 20),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final val = v?.trim() ?? '';
                            if (val.isEmpty) return 'Vui lòng nhập số điện thoại';
                            final regExp = RegExp(r'^(03|05|07|08|09)\d{8}$');
                            if (!regExp.hasMatch(val)) {
                              return 'Số điện thoại không hợp lệ (gồm 10 chữ số)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // 3. Tỉnh / Thành phố (34 tỉnh sáp nhập)
                        DropdownButtonFormField<String>(
                          key: const Key('add_address_province_dropdown'),
                          // ignore: deprecated_member_use
                          value: selectedProvince,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Tỉnh / Thành phố *',
                            hintText: 'Chọn Tỉnh / Thành phố',
                            prefixIcon: Icon(Icons.location_city, size: 20),
                            border: OutlineInputBorder(),
                          ),
                          items: _mergedProvinces.map((p) {
                            final name = p['name'] as String;
                            return DropdownMenuItem<String>(
                              value: name,
                              child: Text(name, style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            final prov = _mergedProvinces.firstWhere((p) => p['name'] == val);
                            final code = prov['code'] as int;

                            setDialogState(() {
                              selectedProvince = val;
                              selectedWard = null;
                              currentWards = List<String>.from(_defaultWardsByProvince[code] ?? [
                                'Phường 1',
                                'Phường 2',
                                'Phường 3',
                                'Phường Trung tâm',
                                'Xã Nông thôn mới',
                              ]);
                            });

                            // Tải thêm danh sách đầy đủ từ API nếu có kết nối
                            _fetchWardsFromApi(code).then((apiWards) {
                              if (apiWards.isNotEmpty && dialogCtx.mounted) {
                                setDialogState(() {
                                  final set = <String>{...currentWards, ...apiWards};
                                  currentWards = set.toList();
                                });
                              }
                            });
                          },
                          validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng chọn Tỉnh / Thành phố' : null,
                        ),
                        const SizedBox(height: 14),

                        // 4. Phường / Xã (sau sáp nhập) - chọn tỉnh trước mới chọn được phường/xã
                        DropdownButtonFormField<String>(
                          key: const Key('add_address_ward_dropdown'),
                          // ignore: deprecated_member_use
                          value: selectedWard,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Phường / Xã (sau sáp nhập) *',
                            hintText: selectedProvince == null
                                ? 'Vui lòng chọn Tỉnh / Thành phố trước'
                                : 'Chọn Phường / Xã',
                            prefixIcon: const Icon(Icons.holiday_village_outlined, size: 20),
                            border: const OutlineInputBorder(),
                          ),
                          items: currentWards.map((w) {
                            return DropdownMenuItem<String>(
                              value: w,
                              child: Text(w, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: selectedProvince == null
                              ? null
                              : (val) {
                                  setDialogState(() {
                                    selectedWard = val;
                                  });
                                },
                          validator: (v) {
                            if (selectedProvince == null) return 'Vui lòng chọn Tỉnh / Thành phố trước';
                            if (v == null || v.isEmpty) return 'Vui lòng chọn Phường / Xã';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // 5. Địa chỉ cụ thể (tự nhập số nhà, tên đường...)
                        TextFormField(
                          key: const Key('add_address_street_field'),
                          controller: addressDetailCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Địa chỉ cụ thể (Số nhà, tên đường) *',
                            hintText: 'VD: Số 123 Lê Lợi',
                            prefixIcon: Icon(Icons.home_outlined, size: 20),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final val = v?.trim() ?? '';
                            if (val.isEmpty) return 'Vui lòng nhập địa chỉ cụ thể';
                            if (val.length < 3) return 'Địa chỉ quá ngắn (tối thiểu 3 ký tự)';
                            final hasAlphaNumeric = RegExp(r'[a-zA-Z0-9À-ỹà-ỹ]').hasMatch(val);
                            if (!hasAlphaNumeric) {
                              return 'Địa chỉ cụ thể phải bao gồm chữ hoặc số hợp lệ (số nhà, tên đường)';
                            }
                            if (_isSpamContent(val)) {
                              return 'Địa chỉ không hợp lệ, vui lòng không nhập ký tự lặp hoặc vô nghĩa';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('add_address_save_button'),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;

                      final name = nameCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      final province = selectedProvince!;
                      final ward = selectedWard!;
                      final street = addressDetailCtrl.text.trim();
                      final fullAddress = '$street, $ward, $province';

                      final newAddress = {
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'name': name,
                        'phone': phone,
                        'province': province,
                        'ward': ward,
                        'address': fullAddress,
                      };

                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(dialogCtx);
                      if (!mounted) return;

                      setState(() {
                        _savedAddressBook.insert(0, newAddress);
                        _addressController.text = '$fullAddress ($name - $phone)';
                      });

                      await _saveAddressesToStorage();

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Đã lưu địa chỉ của "$name" và tự động điền'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Lưu & Chọn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Chuyển sang màn hình xem lại phiếu yêu cầu trước khi đăng (UC-REQ-06)
  void _previewRequest() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_preferredTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày và giờ hẹn thợ đến nhà'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    //_mirror validate của backend: ≥15 phút, ≤14 ngày
    final now = DateTime.now();
    if (!_preferredTime!.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thời gian hẹn phải ở tương lai, vui lòng chọn lại'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_preferredTime!.isBefore(now.add(const Duration(minutes: 15)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Thời gian hẹn cần cách hiện tại ít nhất 15 phút'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_preferredTime!.isAfter(now.add(const Duration(days: 14)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thời gian hẹn không được vượt quá 14 ngày'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && auth.currentUser != null && auth.currentUser!.role != 'user') {
      final roleName = auth.currentUser!.roleDisplay;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tài khoản $roleName không thể tạo yêu cầu sửa chữa. Vui lòng đăng nhập tài khoản Khách hàng.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final token = auth.token ?? '';
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để tạo yêu cầu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Chuyển sang màn hình xem lại tóm tắt phiếu trước khi đăng (UC-REQ-06)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestPreviewScreen(
          category: widget.preselectedCategory,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          urgency: _urgency,
          preferredTime: _preferredTime!,
          images: _selectedImages,
          address: _addressController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isNotCustomer = auth.isAuthenticated && auth.currentUser != null && auth.currentUser!.role != 'user';
    final roleName = auth.currentUser?.roleDisplay ?? 'Người dùng';

    final defaultIssueHint = widget.preselectedCategory.commonIssues.isNotEmpty
        ? widget.preselectedCategory.commonIssues.first
        : 'Mô tả ngắn sự cố cần sửa chữa';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tạo yêu cầu sửa chữa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Cảnh báo nếu tài khoản không phải Khách hàng (Thợ, Staff, Admin)
              if (isNotCustomer) _buildRoleRestrictionBanner(roleName),

              // Thông tin dịch vụ đã chọn
              _buildSelectedServiceCard(),
              const SizedBox(height: 24),

              // Tiêu đề yêu cầu
              _buildSectionLabel('Tiêu đề yêu cầu *', Icons.title_outlined),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('create_request_title_field'),
                controller: _titleController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: _inputDecoration(
                  hint: 'VD: $defaultIssueHint...',
                ),
                validator: (val) {
                  final text = val?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Vui lòng nhập tiêu đề sự cố cần sửa chữa';
                  }
                  if (text.length < 6) {
                    return 'Tiêu đề quá ngắn (tối thiểu 6 ký tự)';
                  }
                  if (text.length > 150) {
                    return 'Tiêu đề không được vượt quá 150 ký tự';
                  }
                  if (_isSpamContent(text)) {
                    return 'Tiêu đề không hợp lệ, vui lòng không nhập ký tự lặp hoặc từ vô nghĩa';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Mô tả triệu chứng hỏng hóc
              _buildSectionLabel('Mô tả triệu chứng hỏng hóc *', Icons.description_outlined),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('create_request_problem_field'),
                controller: _descriptionController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                maxLines: 5,
                maxLength: 1000,
                decoration: _inputDecoration(
                  hint: 'Mô tả chi tiết sự cố bạn đang gặp phải (triệu chứng, hiện tượng bất thường, thời điểm xuất hiện sự cố)...',
                ),
                validator: (val) {
                  final text = val?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Vui lòng mô tả chi tiết sự cố hỏng hóc';
                  }
                  if (text.length < 15) {
                    return 'Mô tả sự cố quá ngắn. Vui lòng nhập tối thiểu 15 ký tự để thợ hiểu rõ vấn đề';
                  }
                  if (text.length > 1000) {
                    return 'Mô tả không được vượt quá 1000 ký tự';
                  }
                  final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
                  if (wordCount < 3) {
                    return 'Vui lòng mô tả rõ ràng hơn (tối thiểu 3 từ) để thợ có thể hình dung sự cố';
                  }
                  if (_isSpamContent(text)) {
                    return 'Mô tả chứa ký tự lặp hoặc chuỗi vô nghĩa. Vui lòng mô tả sự cố thực tế';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Đính kèm ảnh hiện trường sự cố
              ImagePickerBoxWidget(
                selectedImages: _selectedImages,
                onImagesChanged: (images) => setState(() => _selectedImages = images),
              ),
              const SizedBox(height: 20),

              // Địa chỉ sửa chữa (UC-REQ-05: chọn từ danh bạ hoặc thêm mới trong danh bạ)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionLabel('Địa chỉ sửa chữa *', Icons.location_on_outlined),
                  TextButton.icon(
                    key: const Key('pick_address_book_button'),
                    onPressed: _showAddressBookPicker,
                    icon: const Icon(Icons.contacts_rounded, size: 16),
                    label: const Text('Danh bạ địa chỉ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('create_request_address_field'),
                controller: _addressController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: _inputDecoration(
                  hint: 'Chọn từ danh bạ hoặc nhập địa chỉ mới...',
                ),
                validator: (val) {
                  final text = val?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Vui lòng nhập hoặc chọn địa chỉ sửa chữa';
                  }
                  if (text.length < 5) {
                    return 'Địa chỉ quá ngắn (tối thiểu 5 ký tự)';
                  }
                  final hasAlphaNumeric = RegExp(r'[a-zA-Z0-9À-ỹà-ỹ]').hasMatch(text);
                  if (!hasAlphaNumeric) {
                    return 'Địa chỉ phải chứa chữ hoặc số hợp lệ';
                  }
                  if (_isSpamContent(text)) {
                    return 'Địa chỉ không hợp lệ, vui lòng không nhập ký tự lặp hoặc vô nghĩa';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Chọn mức độ khẩn cấp
              _buildSectionLabel('Mức độ khẩn cấp *', Icons.speed_outlined),
              const SizedBox(height: 12),
              Column(
                children: _urgencyOptions.map((opt) {
                  final isSelected = _urgency == opt['value'];
                  final color = opt['color'] as Color;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => setState(() => _urgency = opt['value'] as String),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.08) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? color : Colors.grey.shade300,
                            width: isSelected ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(opt['icon'] as IconData, color: color, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opt['label'] as String,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? color : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    opt['desc'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: isSelected ? color : Colors.grey.shade400,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Chọn lịch hẹn: ngày & khung giờ thợ đến nhà
              _buildSectionLabel('Lịch hẹn thợ đến nhà *', Icons.event_available_outlined),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Chọn ngày và giờ thuận tiện để thợ đến kiểm tra, sửa chữa',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              ScheduleTimeSlotPicker(
                onScheduleChanged: (schedule) => _preferredTime = schedule,
              ),
              const SizedBox(height: 28),

              // Nút Xem lại phiếu trước khi gửi (UC-REQ-06)
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  key: const Key('create_request_submit_button'),
                  onPressed: isNotCustomer ? null : _previewRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isNotCustomer ? Colors.grey.shade400 : AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isNotCustomer ? Icons.block : Icons.visibility_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isNotCustomer ? 'Tài khoản $roleName không thể tạo đơn' : 'Xem lại phiếu trước khi gửi',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!isNotCustomer) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleRestrictionBanner(String roleName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quyền hạn tài khoản: $roleName',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tài khoản $roleName không thể gửi phiếu yêu cầu sửa chữa. Tính năng đặt đơn sửa chữa chỉ dành riêng cho Khách hàng.',
                  style: const TextStyle(fontSize: 12.5, color: Colors.brown, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedServiceCard() {
    final cat = widget.preselectedCategory;
    final color = AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.handyman_rounded, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dịch vụ đã chọn',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                Text(
                  cat.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (cat.basePrice > 0)
                  Text(
                    'Giá tham khảo: ${cat.basePriceFormatted}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
