import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import 'create_staff_screen.dart';
import 'admin_technician_approval_screen.dart';

class AdminHomeScreen extends StatefulWidget {

  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadUsers() {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      context.read<AdminProvider>().fetchUsers(token);
    }
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi trang Quản trị viên?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final adminProvider = context.watch<AdminProvider>();
    final currentUser = authProvider.currentUser;
    final currentUserId = currentUser?.id;
    final token = authProvider.token ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              AppAssets.logo,
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  'Cổng Quản trị viên',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Duyệt hồ sơ Thợ (KYC)',
            icon: const Icon(Icons.assignment_ind_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminTechnicianApprovalScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Làm mới danh sách',
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            style: IconButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context, authProvider),
          ),
        ],

      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Thêm Staff',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateStaffScreen(),
            ),
          );
          if (created == true) {
            _loadUsers();
          }
        },
      ),
      body: Column(
        children: [
          // Thẻ hồ sơ Admin & Thống kê tóm tắt
          _buildAdminHeaderCard(currentUser, adminProvider.users),

          // Thanh tìm kiếm và bộ lọc
          _buildSearchAndFilterSection(adminProvider, token),

          // Danh sách tài khoản
          Expanded(
            child: _buildUserList(adminProvider, currentUserId, token),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHeaderCard(UserModel? user, List<UserModel> allUsers) {
    if (user == null) return const SizedBox.shrink();

    final totalCount = allUsers.length;
    final staffCount = allUsers.where((u) => u.role == 'staff').length;
    final techCount = allUsers.where((u) => u.role == 'technician').length;
    final customerCount = allUsers.where((u) => u.role == 'user').length;
    final lockedCount = allUsers.where((u) => !u.isActive).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.deepPurple.shade50,
                child: Text(
                  user.initials,
                  style: TextStyle(
                    color: Colors.deepPurple.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.fullName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.deepPurple.shade200,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'Quản trị viên',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Hàng thống kê số lượng
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Tổng cộng', '$totalCount', Colors.blueGrey),
              _buildStatItem('Khách hàng', '$customerCount', Colors.blue),
              _buildStatItem('Thợ', '$techCount', Colors.orange.shade800),
              _buildStatItem('Nhân viên', '$staffCount', AppTheme.primaryColor),
              _buildStatItem('Đã khóa', '$lockedCount', Colors.red.shade700),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterSection(AdminProvider adminProvider, String token) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ô tìm kiếm
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm tên, email, số điện thoại...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        adminProvider.setSearchQuery('', token);
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 14,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (value) {
              adminProvider.setSearchQuery(value, token);
            },
          ),
          const SizedBox(height: 8),

          // Lọc theo Vai trò
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Vai trò:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(width: 6),
                _buildRoleFilterChip(
                  label: 'Tất cả',
                  value: null,
                  adminProvider: adminProvider,
                  token: token,
                ),
                const SizedBox(width: 4),
                _buildRoleFilterChip(
                  label: 'Khách hàng',
                  value: 'user',
                  adminProvider: adminProvider,
                  token: token,
                ),
                const SizedBox(width: 4),
                _buildRoleFilterChip(
                  label: 'Thợ',
                  value: 'technician',
                  adminProvider: adminProvider,
                  token: token,
                ),
                const SizedBox(width: 4),
                _buildRoleFilterChip(
                  label: 'Nhân viên (Staff)',
                  value: 'staff',
                  adminProvider: adminProvider,
                  token: token,
                ),
                const SizedBox(width: 4),
                _buildRoleFilterChip(
                  label: 'Admin',
                  value: 'admin',
                  adminProvider: adminProvider,
                  token: token,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Lọc theo Trạng thái
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Trạng thái:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(width: 6),
                _buildStatusFilterChip(
                  label: 'Tất cả',
                  value: null,
                  adminProvider: adminProvider,
                  token: token,
                ),
                const SizedBox(width: 4),
                _buildStatusFilterChip(
                  label: 'Hoạt động',
                  value: true,
                  adminProvider: adminProvider,
                  token: token,
                ),
                const SizedBox(width: 4),
                _buildStatusFilterChip(
                  label: 'Đã khóa',
                  value: false,
                  adminProvider: adminProvider,
                  token: token,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip({
    required String label,
    required String? value,
    required AdminProvider adminProvider,
    required String token,
  }) {
    final isSelected = adminProvider.selectedRole == value;
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor,
      backgroundColor: Colors.grey.shade100,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onSelected: (_) {
        adminProvider.setSelectedRole(value, token);
      },
    );
  }

  Widget _buildStatusFilterChip({
    required String label,
    required bool? value,
    required AdminProvider adminProvider,
    required String token,
  }) {
    final isSelected = adminProvider.selectedStatus == value;
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor,
      backgroundColor: Colors.grey.shade100,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onSelected: (_) {
        adminProvider.setSelectedStatus(value, token);
      },
    );
  }

  Widget _buildUserList(
    AdminProvider adminProvider,
    String? currentUserId,
    String token,
  ) {
    if (adminProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (adminProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                adminProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Thử lại'),
                onPressed: _loadUsers,
              ),
            ],
          ),
        ),
      );
    }

    final users = adminProvider.users;

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Không tìm thấy tài khoản nào',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                adminProvider.resetFilters(token);
              },
              child: const Text('Xóa bộ lọc'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isSelf = user.id == currentUserId;
        return _buildUserCard(user, isSelf, adminProvider, token);
      },
    );
  }

  Widget _buildUserCard(
    UserModel user,
    bool isSelf,
    AdminProvider adminProvider,
    String token,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dobText = dateFormat.format(user.dateOfBirth);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: user.isActive ? Colors.grey.shade200 : Colors.red.shade200,
          width: user.isActive ? 1 : 1.5,
        ),
      ),
      color: user.isActive
          ? Colors.white
          : Colors.red.shade50.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + Tên + Vai trò + Trạng thái
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      _getRoleColor(user.role).withValues(alpha: 0.15),
                  child: Text(
                    user.initials,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(user.role),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.fullName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelf)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(left: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Bạn',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Badge Role
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(user.role)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user.roleDisplay,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getRoleColor(user.role),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Badge Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: user.isActive
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: user.isActive
                                    ? Colors.green.shade300
                                    : Colors.red.shade300,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  user.isActive
                                      ? Icons.check_circle_outline
                                      : Icons.lock_outline,
                                  size: 11,
                                  color: user.isActive
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user.isActive ? 'Hoạt động' : 'Đã khóa',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: user.isActive
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Thông tin chi tiết: Email, Phone, Ngày sinh, Giới tính
            Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  size: 14,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.phone_outlined,
                  size: 14,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  user.phoneNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'NS: $dobText',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(
                  Icons.wc_outlined,
                  size: 13,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Giới tính: ${user.genderDisplay}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Nút Thao tác: Phân quyền / Khóa tài khoản
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.manage_accounts_outlined, size: 16),
                    label: const Text(
                      'Phân quyền',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: isSelf
                        ? null
                        : () => _showChangeRoleDialog(user, adminProvider, token),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: user.isActive
                      ? OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.lock_outline, size: 15),
                          label: const Text(
                            'Khóa',
                            style: TextStyle(fontSize: 12),
                          ),
                          onPressed: isSelf
                              ? null
                              : () => _confirmToggleStatus(
                                    user,
                                    adminProvider,
                                    token,
                                    false,
                                  ),
                        )
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.lock_open, size: 15),
                          label: const Text(
                            'Mở khóa',
                            style: TextStyle(fontSize: 12),
                          ),
                          onPressed: () => _confirmToggleStatus(
                            user,
                            adminProvider,
                            token,
                            true,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.deepPurple;
      case 'staff':
        return AppTheme.primaryColor;
      case 'technician':
        return Colors.orange.shade800;
      case 'user':
      default:
        return Colors.blueGrey;
    }
  }

  void _showChangeRoleDialog(
    UserModel user,
    AdminProvider adminProvider,
    String token,
  ) {
    String selectedRole = user.role;
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Phân quyền: ${user.fullName}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chọn vai trò mới cho tài khoản:',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRoleOptionItem(
                    title: 'Khách hàng (user)',
                    subtitle: 'Đặt lịch và sử dụng dịch vụ',
                    roleValue: 'user',
                    selectedRole: selectedRole,
                    onTap: () => setDialogState(() => selectedRole = 'user'),
                  ),
                  _buildRoleOptionItem(
                    title: 'Thợ kỹ thuật (technician)',
                    subtitle: 'Tiếp nhận công việc sửa chữa',
                    roleValue: 'technician',
                    selectedRole: selectedRole,
                    onTap: () => setDialogState(() => selectedRole = 'technician'),
                  ),
                  _buildRoleOptionItem(
                    title: 'Nhân viên (staff)',
                    subtitle: 'Điều phối công việc & CSKH',
                    roleValue: 'staff',
                    selectedRole: selectedRole,
                    onTap: () => setDialogState(() => selectedRole = 'staff'),
                  ),
                  _buildRoleOptionItem(
                    title: 'Quản trị viên (admin)',
                    subtitle: 'Toàn quyền quản trị hệ thống',
                    roleValue: 'admin',
                    selectedRole: selectedRole,
                    onTap: () => setDialogState(() => selectedRole = 'admin'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final success = await adminProvider.updateUserRole(
                      token: token,
                      userId: user.id,
                      role: selectedRole,
                    );
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          adminProvider.successMessage ??
                              adminProvider.errorMessage ??
                              'Thực hiện hoàn tất',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  },
                  child: const Text('Lưu thay đổi'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRoleOptionItem({
    required String title,
    required String subtitle,
    required String roleValue,
    required String selectedRole,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedRole == roleValue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmToggleStatus(
    UserModel user,
    AdminProvider adminProvider,
    String token,
    bool targetActive,
  ) {
    final actionText = targetActive ? 'mở khóa' : 'khóa';
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xác nhận $actionText tài khoản'),
        content: Text(
          targetActive
              ? 'Bạn có chắc chắn muốn mở khóa cho tài khoản "${user.fullName}"? Người dùng sẽ có thể đăng nhập bình thường.'
              : 'Bạn có chắc chắn muốn khóa tài khoản "${user.fullName}"? Người dùng sẽ bị chặn truy cập vào ứng dụng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: targetActive ? Colors.green : Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await adminProvider.toggleUserStatus(
                token: token,
                userId: user.id,
                isActive: targetActive,
              );
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    adminProvider.successMessage ??
                        adminProvider.errorMessage ??
                        'Thực hiện hoàn tất',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: Text(targetActive ? 'Mở khóa' : 'Khóa tài khoản'),
          ),
        ],
      ),
    );
  }
}
