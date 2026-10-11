import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/service_category_model.dart';
import '../providers/repair_request_provider.dart';
import '../widgets/service_category_card.dart';
import 'create_repair_request_screen.dart';

class ServiceCategoryScreen extends StatefulWidget {
  const ServiceCategoryScreen({super.key});

  @override
  State<ServiceCategoryScreen> createState() => _ServiceCategoryScreenState();
}

class _ServiceCategoryScreenState extends State<ServiceCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  // Từ khóa sự cố phổ biến
  static const List<String> _suggestedKeywords = [
    'Tất cả',
    'Chập điện',
    'Rò rỉ nước',
    'Điều hòa',
    'Máy tính',
    'Vòi sen',
    'Ổ cắm',
    'Aptomat',
  ];
  String _selectedSuggestedTag = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RepairRequestProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _selectedSuggestedTag = _suggestedKeywords.contains(val.trim()) ? val.trim() : '';
        });
        context.read<RepairRequestProvider>().setSearchKeyword(val);
      }
    });
  }

  void _onSelectSuggestedTag(String tag) {
    setState(() {
      _selectedSuggestedTag = tag;
    });

    if (tag == 'Tất cả') {
      _searchController.clear();
      context.read<RepairRequestProvider>().clearSearch();
    } else {
      _searchController.text = tag;
      context.read<RepairRequestProvider>().setSearchKeyword(tag);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _selectedSuggestedTag = 'Tất cả';
    });
    context.read<RepairRequestProvider>().clearSearch();
  }

  void _showCategoryDetail(BuildContext context, ServiceCategoryModel category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                category.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Các sự cố thường gặp cần thợ hỗ trợ:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              ...category.commonIssues.map((issue) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          issue,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              Builder(
                builder: (buttonCtx) {
                  final auth = buttonCtx.watch<AuthProvider>();
                  final isNotCustomer = auth.isAuthenticated && auth.currentUser != null && auth.currentUser!.role != 'user';

                  if (isNotCustomer) {
                    final roleName = auth.currentUser!.roleDisplay;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tài khoản $roleName chỉ xem danh mục tham khảo, không thể tạo đơn sửa chữa.',
                              style: const TextStyle(fontSize: 12.5, color: Colors.brown),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ElevatedButton.icon(
                    icon: const Icon(Icons.post_add_rounded),
                    label: const Text('Tạo yêu cầu cho dịch vụ này'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateRepairRequestScreen(
                            preselectedCategory: category,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Danh mục dịch vụ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Ô tìm kiếm dịch vụ
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm sự cố: chập điện, xì gas, quạt kêu...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: _clearSearch,
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),

            // Gợi ý từ khóa tìm kiếm nhanh
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestedKeywords.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final tag = _suggestedKeywords[idx];
                  final isSelected = _selectedSuggestedTag == tag;
                  return ChoiceChip(
                    label: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: Colors.white,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                      ),
                    ),
                    onSelected: (_) => _onSelectSuggestedTag(tag),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),

            // Dòng thông báo kết quả tìm kiếm nếu đang lọc
            Consumer<RepairRequestProvider>(
              builder: (context, provider, _) {
                if (provider.searchKeyword.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt_outlined, size: 16, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 6),
                      Text(
                        'Kết quả cho "${provider.searchKeyword}": ${provider.categories.length} dịch vụ',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: _clearSearch,
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            'Xem tất cả',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Main Category List State
            Expanded(
              child: Consumer<RepairRequestProvider>(
                builder: (context, provider, _) {
                  // Đang tải dữ liệu
                  if (provider.isLoading && provider.rawCategories.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  // Lỗi kết nối
                  if (provider.errorMessage != null && provider.rawCategories.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 56,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              provider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Thử lại'),
                              onPressed: () {
                                provider.fetchCategories(refresh: true);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Danh sách trống
                  if (provider.categories.isEmpty) {
                    final hasFilter = provider.searchKeyword.isNotEmpty;
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search_off_rounded,
                                size: 52,
                                color: Colors.orange.shade400,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              hasFilter
                                  ? 'Không tìm thấy dịch vụ cho "${provider.searchKeyword}"'
                                  : 'Không tìm thấy danh mục dịch vụ phù hợp',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              hasFilter
                                  ? 'Hãy thử tìm theo tên thiết bị (điều hòa, máy bơm, ổ cắm...)'
                                  : 'Hệ thống đang cập nhật danh mục, vui lòng thử lại sau.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            if (hasFilter) ...[
                              const SizedBox(height: 18),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.clear_all_rounded, size: 18),
                                label: const Text('Xem tất cả danh mục'),
                                onPressed: _clearSearch,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  // Danh sách danh mục
                  return RefreshIndicator(
                    onRefresh: () => provider.fetchCategories(refresh: true),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: provider.categories.length,
                      itemBuilder: (ctx, index) {
                        final cat = provider.categories[index];
                        return ServiceCategoryCard(
                          category: cat,
                          onTap: () => _showCategoryDetail(context, cat),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
