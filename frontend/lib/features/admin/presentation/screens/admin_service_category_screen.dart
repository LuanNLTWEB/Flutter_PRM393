import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../repair_request/data/models/service_category_model.dart';
import '../providers/admin_provider.dart';

/// Màn hình Quản lý danh mục dịch vụ & giá sàn nhóm sửa chữa (UC-STF-02)
/// Dành cho Staff và Admin vận hành sàn HomeFix
class AdminServiceCategoryScreen extends StatefulWidget {
  const AdminServiceCategoryScreen({super.key});

  @override
  State<AdminServiceCategoryScreen> createState() =>
      _AdminServiceCategoryScreenState();
}

class _AdminServiceCategoryScreenState
    extends State<AdminServiceCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const List<Map<String, dynamic>> _availableIcons = [
    {'name': 'home_repair_service', 'icon': Icons.home_repair_service_rounded, 'label': 'Sửa chữa chung'},
    {'name': 'electric_bolt', 'icon': Icons.electric_bolt_rounded, 'label': 'Điện dân dụng'},
    {'name': 'water_drop', 'icon': Icons.water_drop_rounded, 'label': 'Nước & Đường ống'},
    {'name': 'ac_unit', 'icon': Icons.ac_unit_rounded, 'label': 'Điện lạnh'},
    {'name': 'laptop_chromebook', 'icon': Icons.laptop_chromebook_rounded, 'label': 'Máy tính & Laptop'},
    {'name': 'build', 'icon': Icons.build_rounded, 'label': 'Cơ khí & Bảo trì'},
    {'name': 'plumbing', 'icon': Icons.plumbing_rounded, 'label': 'Vòi nước & Van'},
    {'name': 'lock', 'icon': Icons.lock_rounded, 'label': 'Khóa cửa & Bản lề'},
    {'name': 'cleaning_services', 'icon': Icons.cleaning_services_rounded, 'label': 'Vệ sinh công nghiệp'},
    {'name': 'handyman', 'icon': Icons.handyman_rounded, 'label': 'Thợ mộc & Đồ gỗ'},
    {'name': 'roofing', 'icon': Icons.roofing_rounded, 'label': 'Mái tôn & Chống dột'},
    {'name': 'tv', 'icon': Icons.tv_rounded, 'label': 'Tivi & Màn hình'},
    {'name': 'kitchen', 'icon': Icons.kitchen_rounded, 'label': 'Tủ lạnh & Bếp'},
    {'name': 'local_laundry_service', 'icon': Icons.local_laundry_service_rounded, 'label': 'Máy giặt & Sấy'},
    {'name': 'brush', 'icon': Icons.brush_rounded, 'label': 'Sơn tường & Thạch cao'},
  ];

  static const List<Color> _availableColors = [
    Color(0xFF2563EB), // Blue
    Color(0xFFD97706), // Amber / Orange
    Color(0xFF0891B2), // Cyan
    Color(0xFF7C3AED), // Purple
    Color(0xFFEA580C), // Orange Red
    Color(0xFF059669), // Emerald Green
    Color(0xFFDC2626), // Red
    Color(0xFF4F46E5), // Indigo
    Color(0xFF0D9488), // Teal
    Color(0xFFDB2777), // Pink
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token != null && token.isNotEmpty) {
      context.read<AdminProvider>().fetchCategoriesForManage(token);
    }
  }

  IconData _getIconData(String iconName) {
    for (final item in _availableIcons) {
      if (item['name'] == iconName) {
        return item['icon'] as IconData;
      }
    }
    return Icons.home_repair_service_rounded;
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }

  String _formatCurrency(double amount) {
    final int value = amount.round();
    final formatted = value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '$formatted đ';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final token = auth.token ?? '';
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản Lý Danh Mục Dịch Vụ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'UC-STF-02 • Giá sàn & Nhóm sửa chữa',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm Nhóm Dịch Vụ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _openAddEditCategorySheet(context, token: token),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: Column(
          children: [
            // Thẻ thống kê tổng quan
            _buildStatisticsCard(admin),

            // Thanh tìm kiếm và bộ lọc trạng thái
            _buildSearchAndFilter(admin),

            // Danh sách danh mục
            Expanded(
              child: _buildCategoryList(admin, token),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(AdminProvider admin) {
    final categories = admin.rawCategories;
    double avgPrice = 0;
    if (categories.isNotEmpty) {
      final total = categories.fold<double>(0, (sum, c) => sum + c.basePrice);
      avgPrice = total / categories.length;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: 'Tổng nhóm',
            value: '${admin.categoriesTotal}',
            icon: Icons.category_outlined,
            color: Colors.blue.shade700,
          ),
          _buildStatDivider(),
          _buildStatItem(
            label: 'Đang mở',
            value: '${admin.categoriesActive}',
            icon: Icons.check_circle_outline,
            color: Colors.green.shade700,
          ),
          _buildStatDivider(),
          _buildStatItem(
            label: 'Đã tạm ẩn',
            value: '${admin.categoriesInactive}',
            icon: Icons.visibility_off_outlined,
            color: Colors.orange.shade800,
          ),
          _buildStatDivider(),
          _buildStatItem(
            label: 'Giá sàn TB',
            value: _formatCurrency(avgPrice),
            icon: Icons.payments_outlined,
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 28,
      width: 1,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter(AdminProvider admin) {
    final currentFilter = admin.categoryFilter;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm tên, mô tả, slug danh mục...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        admin.setCategorySearch('');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => admin.setCategorySearch(val),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Tất cả (${admin.categoriesTotal})',
                  isSelected: currentFilter == null,
                  onSelected: () => admin.setCategoryFilter(null),
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: 'Đang mở (${admin.categoriesActive})',
                  isSelected: currentFilter == 'ACTIVE',
                  selectedColor: Colors.green.shade50,
                  selectedTextColor: Colors.green.shade800,
                  onSelected: () => admin.setCategoryFilter('ACTIVE'),
                ),
                const SizedBox(width: 6),
                _buildFilterChip(
                  label: 'Đã tạm ẩn (${admin.categoriesInactive})',
                  isSelected: currentFilter == 'INACTIVE',
                  selectedColor: Colors.orange.shade50,
                  selectedTextColor: Colors.orange.shade800,
                  onSelected: () => admin.setCategoryFilter('INACTIVE'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    Color? selectedColor,
    Color? selectedTextColor,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? (selectedTextColor ?? AppTheme.primaryColor)
              : AppTheme.textSecondaryColor,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: selectedColor ?? AppTheme.primaryColor.withValues(alpha: 0.12),
      backgroundColor: Colors.grey.shade100,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? (selectedTextColor ?? AppTheme.primaryColor).withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildCategoryList(AdminProvider admin, String token) {
    if (admin.isCategoriesLoading && admin.rawCategories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final list = admin.categories;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_off_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              const Text(
                'Không tìm thấy danh mục phù hợp',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Thử tìm từ khóa khác hoặc bấm nút thêm bên dưới để tạo nhóm sửa chữa mới.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final category = list[index];
        return _buildCategoryCard(category, admin, token);
      },
    );
  }

  Widget _buildCategoryCard(
    ServiceCategoryModel category,
    AdminProvider admin,
    String token,
  ) {
    final color = _parseColor(category.color);
    final iconData = _getIconData(category.icon);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: category.isActive ? Colors.grey.shade200 : Colors.red.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề & Icon & Switch
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(iconData, color: color, size: 24),
                ),
                const SizedBox(width: 12),

                // Tên & Slug
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              category.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: category.isActive
                                    ? AppTheme.textPrimaryColor
                                    : AppTheme.textSecondaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: category.isActive
                                  ? Colors.green.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: category.isActive
                                    ? Colors.green.shade200
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              category.isActive ? 'Đang mở' : 'Đã ẩn',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: category.isActive
                                    ? Colors.green.shade700
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${category.slug} • Thứ tự: ${category.sortOrder}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Switch Bật/Tắt trạng thái
                Switch.adaptive(
                  value: category.isActive,
                  activeThumbColor: AppTheme.primaryColor,
                  activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                  onChanged: admin.isActionLoading
                      ? null
                      : (val) async {
                          final success = await admin.toggleCategoryStatus(
                            token: token,
                            id: category.id,
                          );
                          if (mounted && success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(admin.successMessage ?? 'Thành công'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          ),

          // Mô tả dịch vụ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              category.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
                height: 1.35,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Vùng Giá Sàn Đề Xuất
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.price_change_outlined,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Giá sàn nhóm sửa chữa:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatCurrency(category.basePrice),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Danh sách sự cố thường gặp (Common Issues)
          if (category.commonIssues.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: category.commonIssues.map((issue) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 0.8),
                    ),
                    child: Text(
                      '• $issue',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),

          // Thanh Thao Tác (Chỉnh sửa / Xóa)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Xóa / Ẩn', style: TextStyle(fontSize: 13)),
                  onPressed: () => _confirmDeleteCategory(
                    context,
                    category: category,
                    admin: admin,
                    token: token,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Chỉnh sửa', style: TextStyle(fontSize: 13)),
                  onPressed: () => _openAddEditCategorySheet(
                    context,
                    token: token,
                    existingCategory: category,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(
    BuildContext context, {
    required ServiceCategoryModel category,
    required AdminProvider admin,
    required String token,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Xóa nhóm dịch vụ?'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa danh mục "${category.name}"?\n\nLưu ý: Nếu danh mục đã có đơn yêu cầu sửa chữa gắn liền, hệ thống sẽ tự động chuyển sang trạng thái "Tạm ẩn" để đảm bảo tính toàn vẹn dữ liệu.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy bỏ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await admin.deleteCategory(
                token: token,
                id: category.id,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      admin.successMessage ??
                          admin.errorMessage ??
                          (success ? 'Thành công' : 'Thất bại'),
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
  }

  /// BottomSheet Thêm mới hoặc Chỉnh sửa danh mục
  void _openAddEditCategorySheet(
    BuildContext context, {
    required String token,
    ServiceCategoryModel? existingCategory,
  }) {
    final isEditing = existingCategory != null;

    final nameCtrl = TextEditingController(text: existingCategory?.name ?? '');
    final descCtrl =
        TextEditingController(text: existingCategory?.description ?? '');
    final priceCtrl = TextEditingController(
      text: existingCategory != null
          ? existingCategory.basePrice.toStringAsFixed(0)
          : '150000',
    );
    final sortOrderCtrl = TextEditingController(
      text: existingCategory != null ? '${existingCategory.sortOrder}' : '0',
    );

    String selectedIcon =
        existingCategory?.icon ?? 'home_repair_service';
    Color selectedColor = existingCategory != null
        ? _parseColor(existingCategory.color)
        : const Color(0xFF2563EB);
    bool isActive = existingCategory?.isActive ?? true;

    final List<String> issuesList = existingCategory != null
        ? List<String>.from(existingCategory.commonIssues)
        : [];
    final issueInputCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            String colorToHex(Color color) {
              return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar & Header
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing
                              ? 'Chỉnh Sửa Nhóm Dịch Vụ'
                              : 'Thêm Nhóm Dịch Vụ Mới',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Nội dung Form nhập liệu
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Tên danh mục
                          const Text(
                            'Tên nhóm sửa chữa *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameCtrl,
                            decoration: InputDecoration(
                              hintText: 'Ví dụ: Sửa máy giặt & Máy sấy',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. Mô tả dịch vụ
                          const Text(
                            'Mô tả chi tiết nhóm dịch vụ *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: descCtrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText:
                                  'Mô tả phạm vi sửa chữa, bảo dưỡng cho khách hàng nắm rõ...',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 3. Giá sàn tham khảo (Base Price)
                          Row(
                            children: [
                              const Text(
                                'Giá sàn dịch vụ (VND) *',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(Mức giá khởi điểm tối thiểu)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '150000',
                              prefixIcon: const Icon(Icons.payments_outlined),
                              suffixText: 'VND',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Nút gán nhanh giá sàn
                          Wrap(
                            spacing: 6,
                            children: [100000, 150000, 200000, 300000, 500000].map((preset) {
                              return ActionChip(
                                label: Text(
                                  _formatCurrency(preset.toDouble()),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onPressed: () {
                                  setSheetState(() {
                                    priceCtrl.text = '$preset';
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 18),

                          // 4. Chọn Biểu tượng (Icon)
                          const Text(
                            'Chọn biểu tượng đại diện (Icon)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _availableIcons.map((item) {
                              final name = item['name'] as String;
                              final icon = item['icon'] as IconData;
                              final isSelected = selectedIcon == name;

                              return InkWell(
                                onTap: () {
                                  setSheetState(() {
                                    selectedIcon = name;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? selectedColor.withValues(alpha: 0.15)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? selectedColor
                                          : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: isSelected ? selectedColor : Colors.grey.shade700,
                                    size: 24,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 18),

                          // 5. Chọn Màu sắc chủ đạo (Color)
                          const Text(
                            'Chọn màu sắc nhận diện',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _availableColors.map((color) {
                              final isSelected = selectedColor.toARGB32() == color.toARGB32();
                              return InkWell(
                                onTap: () {
                                  setSheetState(() {
                                    selectedColor = color;
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? Colors.black : Colors.white,
                                      width: isSelected ? 3 : 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.4),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 18,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 18),

                          // 6. Danh sách các vấn đề thường gặp (Common Issues)
                          const Text(
                            'Vấn đề thường gặp (Khách hay chọn)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: issueInputCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'Nhập vấn đề ví dụ: Rò rỉ nước ngầm',
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  ),
                                  onSubmitted: (val) {
                                    if (val.trim().isNotEmpty) {
                                      setSheetState(() {
                                        issuesList.add(val.trim());
                                        issueInputCtrl.clear();
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  if (issueInputCtrl.text.trim().isNotEmpty) {
                                    setSheetState(() {
                                      issuesList.add(issueInputCtrl.text.trim());
                                      issueInputCtrl.clear();
                                    });
                                  }
                                },
                                child: const Text('Thêm'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (issuesList.isNotEmpty)
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: issuesList.map((issue) {
                                return Chip(
                                  label: Text(
                                    issue,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () {
                                    setSheetState(() {
                                      issuesList.remove(issue);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 18),

                          // 7. Thứ tự hiển thị & Kích hoạt
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Thứ tự sắp xếp',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: sortOrderCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: '0',
                                        isDense: true,
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Kích hoạt ngay',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Switch.adaptive(
                                          value: isActive,
                                          activeThumbColor: AppTheme.primaryColor,
                                          activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                                          onChanged: (val) {
                                            setSheetState(() {
                                              isActive = val;
                                            });
                                          },
                                        ),
                                        Text(
                                          isActive ? 'Đang mở' : 'Tạm ẩn',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isActive
                                                ? Colors.green.shade700
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // Nút Lưu thay đổi
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final desc = descCtrl.text.trim();
                          final price = double.tryParse(priceCtrl.text.trim()) ?? 150000;
                          final sort = int.tryParse(sortOrderCtrl.text.trim()) ?? 0;

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng nhập tên nhóm sửa chữa'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (desc.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng nhập mô tả nhóm sửa chữa'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(ctx);

                          final adminProvider = context.read<AdminProvider>();
                          bool ok = false;
                          if (isEditing) {
                            ok = await adminProvider.updateCategory(
                              token: token,
                              id: existingCategory.id,
                              name: name,
                              description: desc,
                              icon: selectedIcon,
                              color: colorToHex(selectedColor),
                              basePrice: price,
                              commonIssues: issuesList,
                              isActive: isActive,
                              sortOrder: sort,
                            );
                          } else {
                            ok = await adminProvider.createCategory(
                              token: token,
                              name: name,
                              description: desc,
                              icon: selectedIcon,
                              color: colorToHex(selectedColor),
                              basePrice: price,
                              commonIssues: issuesList,
                              isActive: isActive,
                              sortOrder: sort,
                            );
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  adminProvider.successMessage ??
                                      adminProvider.errorMessage ??
                                      (ok ? 'Lưu thành công' : 'Có lỗi xảy ra'),
                                ),
                                backgroundColor: ok ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                        child: Text(
                          isEditing
                              ? 'Cập Nhật Nhóm Dịch Vụ'
                              : 'Tạo Nhóm Dịch Vụ Mới',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
