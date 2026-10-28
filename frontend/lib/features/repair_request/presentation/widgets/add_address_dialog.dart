import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_theme.dart';

/// Hộp thoại thêm địa chỉ mới với API Tỉnh/Thành, Phường/Xã hành chính
class AddAddressDialog extends StatefulWidget {
  final bool asBottomSheet;
  final ValueChanged<Map<String, dynamic>>? onSaved;
  final VoidCallback? onCancel;

  const AddAddressDialog({
    super.key,
    this.asBottomSheet = false,
    this.onSaved,
    this.onCancel,
  });

  @override
  State<AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<AddAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();

  static final List<Map<String, dynamic>> _defaultProvinces = [
    {'code': 79, 'name': 'Thành phố Hồ Chí Minh'},
    {'code': 1, 'name': 'Thành phố Hà Nội'},
    {'code': 48, 'name': 'Thành phố Đà Nẵng'},
    {'code': 46, 'name': 'Thành phố Huế'},
    {'code': 31, 'name': 'Thành phố Hải Phòng'},
    {'code': 92, 'name': 'Thành phố Cần Thơ'},
    {'code': 74, 'name': 'Tỉnh Bình Dương'},
    {'code': 75, 'name': 'Tỉnh Đồng Nai'},
    {'code': 77, 'name': 'Tỉnh Bà Rịa - Vũng Tàu'},
    {'code': 68, 'name': 'Tỉnh Lâm Đồng'},
    {'code': 56, 'name': 'Tỉnh Khánh Hòa'},
    {'code': 27, 'name': 'Tỉnh Bắc Ninh'},
    {'code': 22, 'name': 'Tỉnh Quảng Ninh'},
  ];

  static final Map<int, List<Map<String, dynamic>>> _defaultDistricts = {
    79: [
      {'code': 760, 'name': 'Quận 1'},
      {'code': 769, 'name': 'Thành phố Thủ Đức'},
      {'code': 770, 'name': 'Quận 3'},
      {'code': 774, 'name': 'Quận 5'},
      {'code': 771, 'name': 'Quận 10'},
      {'code': 765, 'name': 'Quận Bình Thạnh'},
      {'code': 766, 'name': 'Quận Tân Bình'},
      {'code': 764, 'name': 'Quận Gò Vấp'},
      {'code': 778, 'name': 'Quận 7'},
      {'code': 768, 'name': 'Quận Phú Nhuận'},
      {'code': 777, 'name': 'Quận Bình Tân'},
    ],
    1: [
      {'code': 1, 'name': 'Quận Ba Đình'},
      {'code': 2, 'name': 'Quận Hoàn Kiếm'},
      {'code': 5, 'name': 'Quận Cầu Giấy'},
      {'code': 6, 'name': 'Quận Đống Đa'},
      {'code': 7, 'name': 'Quận Hai Bà Trưng'},
      {'code': 9, 'name': 'Quận Thanh Xuân'},
      {'code': 21, 'name': 'Quận Hà Đông'},
      {'code': 8, 'name': 'Quận Hoàng Mai'},
    ],
    48: [
      {'code': 490, 'name': 'Quận Hải Châu'},
      {'code': 491, 'name': 'Quận Thanh Khê'},
      {'code': 492, 'name': 'Quận Sơn Trà'},
      {'code': 493, 'name': 'Quận Ngũ Hành Sơn'},
      {'code': 494, 'name': 'Quận Liên Chiểu'},
      {'code': 495, 'name': 'Quận Cẩm Lệ'},
    ],
    92: [
      {'code': 916, 'name': 'Quận Ninh Kiều'},
      {'code': 917, 'name': 'Quận Bình Thủy'},
      {'code': 918, 'name': 'Quận Cái Răng'},
      {'code': 919, 'name': 'Quận Ô Môn'},
    ],
    74: [
      {'code': 718, 'name': 'Thành phố Thủ Dầu Một'},
      {'code': 724, 'name': 'Thành phố Thuận An'},
      {'code': 725, 'name': 'Thành phố Dĩ An'},
      {'code': 721, 'name': 'Thành phố Bến Cát'},
      {'code': 723, 'name': 'Thành phố Tân Uyên'},
    ],
    75: [
      {'code': 731, 'name': 'Thành phố Biên Hòa'},
      {'code': 732, 'name': 'Thành phố Long Khánh'},
      {'code': 734, 'name': 'Huyện Long Thành'},
      {'code': 735, 'name': 'Huyện Nhơn Trạch'},
    ],
  };

  static final Map<int, List<Map<String, dynamic>>> _defaultWards = {
    760: [
      {'code': 26734, 'name': 'Phường Tân Định'},
      {'code': 26737, 'name': 'Phường Đa Kao'},
      {'code': 26740, 'name': 'Phường Bến Nghé'},
      {'code': 26743, 'name': 'Phường Bến Thành'},
      {'code': 26746, 'name': 'Phường Nguyễn Thái Bình'},
      {'code': 26749, 'name': 'Phường Phạm Ngũ Lão'},
    ],
    769: [
      {'code': 26782, 'name': 'Phường Thảo Điền'},
      {'code': 26785, 'name': 'Phường An Phú'},
      {'code': 26788, 'name': 'Phường An Khánh'},
      {'code': 26800, 'name': 'Phường Hiệp Phú'},
      {'code': 26803, 'name': 'Phường Tăng Nhơn Phú A'},
      {'code': 26830, 'name': 'Phường Linh Trung'},
    ],
    770: [
      {'code': 27040, 'name': 'Phường Võ Thị Sáu'},
      {'code': 27043, 'name': 'Phường 1'},
      {'code': 27046, 'name': 'Phường 2'},
      {'code': 27049, 'name': 'Phường 3'},
    ],
    774: [
      {'code': 27076, 'name': 'Phường 1'},
      {'code': 27079, 'name': 'Phường 2'},
      {'code': 27082, 'name': 'Phường 3'},
      {'code': 27085, 'name': 'Phường 4'},
    ],
    1: [
      {'code': 1, 'name': 'Phường Phúc Xá'},
      {'code': 4, 'name': 'Phường Trúc Bạch'},
      {'code': 6, 'name': 'Phường Vĩnh Phúc'},
      {'code': 10, 'name': 'Phường Liễu Giai'},
      {'code': 19, 'name': 'Phường Kim Mã'},
      {'code': 22, 'name': 'Phường Giảng Võ'},
      {'code': 25, 'name': 'Phường Thành Công'},
    ],
    2: [
      {'code': 37, 'name': 'Phường Hàng Bạc'},
      {'code': 40, 'name': 'Phường Hàng Bồ'},
      {'code': 43, 'name': 'Phường Hàng Đào'},
      {'code': 55, 'name': 'Phường Tràng Tiền'},
    ],
    5: [
      {'code': 163, 'name': 'Phường Dịch Vọng'},
      {'code': 166, 'name': 'Phường Dịch Vọng Hậu'},
      {'code': 169, 'name': 'Phường Quan Hoa'},
      {'code': 172, 'name': 'Phường Yên Hòa'},
      {'code': 175, 'name': 'Phường Trung Hòa'},
    ],
    490: [
      {'code': 20194, 'name': 'Phường Thạch Thang'},
      {'code': 20197, 'name': 'Phường Hải Châu 1'},
      {'code': 20200, 'name': 'Phường Hải Châu 2'},
      {'code': 20212, 'name': 'Phường Hòa Cường Bắc'},
      {'code': 20215, 'name': 'Phường Hòa Cường Nam'},
    ],
    916: [
      {'code': 31147, 'name': 'Phường Tân An'},
      {'code': 31150, 'name': 'Phường An Lạc'},
      {'code': 31156, 'name': 'Phường Xuân Khánh'},
      {'code': 31159, 'name': 'Phường Hưng Lợi'},
    ],
    718: [
      {'code': 25681, 'name': 'Phường Phú Cường'},
      {'code': 25684, 'name': 'Phường Hiệp Thành'},
      {'code': 25690, 'name': 'Phường Chánh Nghĩa'},
    ],
  };

  static List<Map<String, dynamic>>? _cachedProvinces;
  List<Map<String, dynamic>> _provinces = List.from(_defaultProvinces);
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _wards = [];

  int? _selectedProvinceCode;
  int? _selectedDistrictCode;
  int? _selectedWardCode;

  final _manualDistrictController = TextEditingController();
  final _manualWardController = TextEditingController();
  bool _isManualDistrict = false;
  bool _isManualWard = false;

  bool _isLoadingProvinces = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingWards = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (_cachedProvinces != null && _cachedProvinces!.isNotEmpty) {
      _provinces = _cachedProvinces!;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchProvinces();
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _manualDistrictController.dispose();
    _manualWardController.dispose();
    super.dispose();
  }

  /// Tải danh sách Tỉnh/Thành phố từ Open API (có fallback tức thì)
  Future<void> _fetchProvinces() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProvinces = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse('https://provinces.open-api.vn/api/v1/p/'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
        final parsed = list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        _cachedProvinces = parsed;
        if (mounted) {
          setState(() {
            _provinces = parsed;
            _isLoadingProvinces = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingProvinces = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingProvinces = false);
      }
    }
  }

  /// Tải danh sách Quận/Huyện theo Tỉnh đã chọn
  Future<void> _fetchDistricts(int provinceCode) async {
    final fallback = _defaultDistricts[provinceCode] ?? [];
    setState(() {
      _isLoadingDistricts = true;
      _districts = List.from(fallback);
      _selectedDistrictCode = null;
      _manualDistrictController.clear();
      _isManualDistrict = fallback.isEmpty;
      _wards = [];
      _selectedWardCode = null;
      _manualWardController.clear();
      _isManualWard = false;
    });

    try {
      final response = await http
          .get(Uri.parse('https://provinces.open-api.vn/api/v1/p/$provinceCode?depth=2'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> list = data['districts'] ?? [];
        final parsed = list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        if (mounted) {
          setState(() {
            _districts = parsed;
            _isLoadingDistricts = false;
            if (parsed.isNotEmpty) {
              _isManualDistrict = false;
            }
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingDistricts = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDistricts = false);
    }
  }

  /// Tải danh sách Phường/Xã theo Quận/Huyện đã chọn (sau sáp nhập)
  Future<void> _fetchWards(int districtCode) async {
    final fallback = _defaultWards[districtCode] ?? [];
    setState(() {
      _isLoadingWards = true;
      _wards = List.from(fallback);
      _selectedWardCode = null;
      _manualWardController.clear();
      _isManualWard = fallback.isEmpty;
    });

    try {
      final response = await http
          .get(Uri.parse('https://provinces.open-api.vn/api/v1/d/$districtCode?depth=2'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> list = data['wards'] ?? [];
        final parsed = list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        if (mounted) {
          setState(() {
            _wards = parsed;
            _isLoadingWards = false;
            if (parsed.isNotEmpty) {
              _isManualWard = false;
            }
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingWards = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingWards = false);
    }
  }

  /// Xác thực và lưu địa chỉ trả về cho màn hình gọi
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProvinceCode == null) {
      _showWarningSnackBar('Vui lòng chọn Tỉnh/Thành phố');
      return;
    }

    final province = _provinces.firstWhere(
      (p) => p['code'] == _selectedProvinceCode,
      orElse: () => <String, dynamic>{'name': ''},
    );

    String districtName = '';
    if (_isManualDistrict) {
      districtName = _manualDistrictController.text.trim();
      if (districtName.isEmpty) {
        _showWarningSnackBar('Vui lòng nhập Quận/Huyện');
        return;
      }
    } else {
      if (_selectedDistrictCode == null) {
        _showWarningSnackBar('Vui lòng chọn Quận/Huyện');
        return;
      }
      final district = _districts.firstWhere(
        (d) => d['code'] == _selectedDistrictCode,
        orElse: () => <String, dynamic>{'name': ''},
      );
      districtName = district['name'] as String? ?? '';
    }

    String wardName = '';
    if (_isManualWard) {
      wardName = _manualWardController.text.trim();
      if (wardName.isEmpty) {
        _showWarningSnackBar('Vui lòng nhập Phường/Xã');
        return;
      }
    } else {
      if (_selectedWardCode == null) {
        _showWarningSnackBar('Vui lòng chọn Phường/Xã');
        return;
      }
      final ward = _wards.firstWhere(
        (w) => w['code'] == _selectedWardCode,
        orElse: () => <String, dynamic>{'name': ''},
      );
      wardName = ward['name'] as String? ?? '';
    }

    final street = _streetController.text.trim();
    final fullAddress = '$street, $wardName, $districtName, ${province['name']}';

    final result = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'street': street,
      'ward': wardName,
      'district': districtName,
      'province': province['name'] as String,
      'address': fullAddress,
    };

    if (widget.onSaved != null) {
      widget.onSaved!(result);
    } else {
      Navigator.pop(context, result);
    }
  }

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.pop(context);
    }
  }

  /// Hiển thị thông báo nhắc nhở chọn trường hành chính
  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.amber.shade800),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formContent = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.add_location_alt_rounded, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Thêm địa chỉ mới',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: _handleCancel,
              ),
            ],
          ),
          const SizedBox(height: 14),

                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: Colors.red)),
                        ),
                        TextButton(
                          onPressed: _fetchProvinces,
                          child: const Text('Thử lại', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                TextFormField(
                  key: const Key('add_address_name_field'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên người nhận *',
                    hintText: 'VD: Nguyễn Văn A',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Vui lòng nhập họ tên người liên hệ';
                    if (val.length < 2) return 'Họ tên quá ngắn';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  key: const Key('add_address_phone_field'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại liên hệ *',
                    hintText: 'VD: 0901234567',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    border: OutlineInputBorder(),
                    isDense: true,
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
                const SizedBox(height: 12),

                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tỉnh / Thành phố *',
                    prefixIcon: const Icon(Icons.apartment_rounded, size: 20),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    suffixIcon: _isLoadingProvinces
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      key: const Key('add_address_province_dropdown'),
                      value: _selectedProvinceCode,
                      isExpanded: true,
                      hint: const Text('Chọn Tỉnh / Thành phố'),
                      items: _provinces.map((p) {
                        return DropdownMenuItem<int>(
                          value: p['code'] as int,
                          child: Text(p['name'] as String, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() => _selectedProvinceCode = val);
                        _fetchDistricts(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (_isManualDistrict) ...[
                  TextFormField(
                    controller: _manualDistrictController,
                    decoration: InputDecoration(
                      labelText: 'Quận / Huyện *',
                      hintText: 'Nhập tên Quận/Huyện...',
                      prefixIcon: const Icon(Icons.location_city_rounded, size: 20),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: _districts.isNotEmpty
                          ? TextButton(
                              onPressed: () => setState(() => _isManualDistrict = false),
                              child: const Text('Chọn ds', style: TextStyle(fontSize: 11)),
                            )
                          : null,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập Quận/Huyện' : null,
                  ),
                ] else ...[
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Quận / Huyện *',
                      prefixIcon: const Icon(Icons.location_city_rounded, size: 20),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      suffixIcon: _isLoadingDistricts
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : (_selectedProvinceCode != null
                              ? TextButton(
                                  onPressed: () => setState(() => _isManualDistrict = true),
                                  child: const Text('Tự nhập', style: TextStyle(fontSize: 11)),
                                )
                              : null),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        key: const Key('add_address_district_dropdown'),
                        value: _selectedDistrictCode,
                        isExpanded: true,
                        hint: Text(_districts.isEmpty ? 'Chọn Tỉnh/Thành trước' : 'Chọn Quận / Huyện'),
                        items: _districts.isEmpty
                            ? null
                            : _districts.map((d) {
                                return DropdownMenuItem<int>(
                                  value: d['code'] as int,
                                  child: Text(d['name'] as String, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                        onChanged: _districts.isEmpty
                            ? null
                            : (val) {
                                if (val == null) return;
                                setState(() => _selectedDistrictCode = val);
                                _fetchWards(val);
                              },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                if (_isManualWard) ...[
                  TextFormField(
                    controller: _manualWardController,
                    decoration: InputDecoration(
                      labelText: 'Phường / Xã (sau sáp nhập) *',
                      hintText: 'Nhập tên Phường/Xã...',
                      prefixIcon: const Icon(Icons.holiday_village_outlined, size: 20),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: _wards.isNotEmpty
                          ? TextButton(
                              onPressed: () => setState(() => _isManualWard = false),
                              child: const Text('Chọn ds', style: TextStyle(fontSize: 11)),
                            )
                          : null,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập Phường/Xã' : null,
                  ),
                ] else ...[
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Phường / Xã (sau sáp nhập) *',
                      prefixIcon: const Icon(Icons.holiday_village_outlined, size: 20),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      suffixIcon: _isLoadingWards
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : (_selectedDistrictCode != null
                              ? TextButton(
                                  onPressed: () => setState(() => _isManualWard = true),
                                  child: const Text('Tự nhập', style: TextStyle(fontSize: 11)),
                                )
                              : null),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        key: const Key('add_address_ward_dropdown'),
                        value: _selectedWardCode,
                        isExpanded: true,
                        hint: Text(_wards.isEmpty ? 'Chọn Quận/Huyện trước' : 'Chọn Phường / Xã'),
                        items: _wards.isEmpty
                            ? null
                            : _wards.map((w) {
                                return DropdownMenuItem<int>(
                                  value: w['code'] as int,
                                  child: Text(w['name'] as String, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                        onChanged: _wards.isEmpty
                            ? null
                            : (val) {
                                if (val == null) return;
                                setState(() => _selectedWardCode = val);
                              },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                TextFormField(
                  key: const Key('add_address_street_field'),
                  controller: _streetController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ cụ thể (Số nhà, ngõ/ngách, tên đường) *',
                    hintText: 'VD: Số 123/45 đường Lê Lợi',
                    prefixIcon: Icon(Icons.home_outlined, size: 20),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Vui lòng nhập số nhà, tên đường';
                    if (val.length < 3) return 'Địa chỉ cụ thể quá ngắn (tối thiểu 3 ký tự)';
                    final hasAlphaNumeric = RegExp(r'[a-zA-Z0-9À-ỹà-ỹ]').hasMatch(val);
                    if (!hasAlphaNumeric) {
                      return 'Địa chỉ cụ thể phải bao gồm chữ hoặc số hợp lệ';
                    }
                    // Bắt buộc có tên đường — chỉ nhập số nhà (vd "123") thì
                    // Google Maps không geocode được và sẽ chọn nhầm địa điểm
                    if (!RegExp(r'[a-zA-ZÀ-ỹà-ỹ]').hasMatch(val)) {
                      return 'Cần nhập thêm tên đường (VD: Số 123/45 đường Lê Lợi)';
                    }
                    if (RegExp(r'(.)\1{3,}').hasMatch(val.replaceAll(RegExp(r'\s+'), ''))) {
                      return 'Địa chỉ không hợp lệ, vui lòng không nhập ký tự lặp hoặc vô nghĩa';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _handleCancel,
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      key: const Key('add_address_save_button'),
                      onPressed: _submit,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Lưu & Chọn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );

    if (widget.asBottomSheet) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 18,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: formContent,
            ),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: formContent,
          ),
        ),
      ),
    );
  }
}
