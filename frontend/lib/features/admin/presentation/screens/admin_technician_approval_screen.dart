import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../technician/presentation/providers/technician_provider.dart';

class AdminTechnicianApprovalScreen extends StatefulWidget {
  const AdminTechnicianApprovalScreen({super.key});

  @override
  State<AdminTechnicianApprovalScreen> createState() =>
      _AdminTechnicianApprovalScreenState();
}

class _AdminTechnicianApprovalScreenState
    extends State<AdminTechnicianApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _reasonController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isSearching = false;

  final List<String> _quickRejectReasons = const [
    'Ảnh CCCD bị mờ/lóa sáng',
    'Thiếu ảnh CCCD mặt sau',
    'Thông tin không khớp CCCD',
    'Chứng chỉ nghề không hợp lệ',
    'Ảnh chân dung không đạt yêu cầu',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadCurrentTab();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentTab();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadCurrentTab() {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final statuses = ['pending', 'approved', 'rejected'];
    final currentStatus = statuses[_tabController.index];
    final search = _searchController.text.trim();
    context.read<TechnicianProvider>().fetchKYCTechnicians(
          token,
          status: currentStatus,
          search: search.isNotEmpty ? search : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TechnicianProvider>();
    final token = context.watch<AuthProvider>().token ?? '';
    final counts = provider.kycCounts;

    final pendingCount = counts['pending'] ?? 0;
    final approvedCount = counts['approved'] ?? 0;
    final rejectedCount = counts['rejected'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Tìm theo tên, SĐT, chuyên môn...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _loadCurrentTab(),
              )
            : const Text('Duyệt Hồ Sơ Thợ (KYC)'),
        centerTitle: !_isSearching,
        actions: [
          IconButton(
            tooltip: _isSearching ? 'Đóng tìm kiếm' : 'Tìm kiếm thợ',
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _loadCurrentTab();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: _loadCurrentTab,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Chờ duyệt ($pendingCount)'),
            Tab(text: 'Đã duyệt ($approvedCount)'),
            Tab(text: 'Từ chối ($rejectedCount)'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadCurrentTab(),
              child: provider.kycTechnicians.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_turned_in_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'Không tìm thấy thợ phù hợp với từ khóa'
                                  : 'Không có hồ sơ nào trong mục này',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (_searchController.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _loadCurrentTab();
                                },
                                child: const Text('Xóa bộ lọc tìm kiếm'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.kycTechnicians.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (ctx, idx) {
                        final tech = provider.kycTechnicians[idx];
                        return _buildTechnicianCard(context, tech, token);
                      },
                    ),
            ),
    );
  }

  Widget _buildTechnicianCard(
      BuildContext context, UserModel tech, String token) {
    final profile = tech.technicianProfile;
    final status = profile?.approvalStatus ?? 'pending';
    final dateStr = tech.createdAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(tech.createdAt!)
        : 'Gần đây';

    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Đã duyệt';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Đã từ chối';
        statusIcon = Icons.cancel_outlined;
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusText = 'Chờ duyệt';
        statusIcon = Icons.hourglass_top_outlined;
    }

    final hasFront = profile?.idCardFront.isNotEmpty == true;
    final hasBack = profile?.idCardBack.isNotEmpty == true;
    final certCount = profile?.certificates.length ?? 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openKYCDetailModal(context, tech, token),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      tech.initials,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tech.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tech.phoneNumber} • ${tech.email}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 12, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Huy hiệu giấy tờ đính kèm
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: (hasFront && hasBack)
                          ? Colors.green.shade50
                          : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (hasFront && hasBack)
                            ? Colors.green.shade200
                            : Colors.amber.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 13,
                          color: (hasFront && hasBack)
                              ? Colors.green.shade700
                              : Colors.amber.shade900,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasFront && hasBack
                              ? 'CCCD 2 mặt'
                              : (!hasFront && !hasBack)
                                  ? 'Chưa có CCCD'
                                  : 'Thiếu 1 mặt CCCD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: (hasFront && hasBack)
                                ? Colors.green.shade700
                                : Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: certCount > 0
                          ? Colors.blue.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: certCount > 0
                            ? Colors.blue.shade200
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium_outlined,
                          size: 13,
                          color: certCount > 0
                              ? Colors.blue.shade700
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          certCount > 0
                              ? '$certCount chứng chỉ'
                              : '0 chứng chỉ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: certCount > 0
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${profile?.experienceYears ?? 0} năm KN',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Danh sách kỹ năng
              Row(
                children: [
                  const Icon(Icons.handyman_outlined,
                      size: 15, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Kỹ năng: ${(profile?.skills ?? []).isNotEmpty ? profile!.skills.join(', ') : "Chưa cập nhật"}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 20, color: AppTheme.textSecondaryColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openKYCDetailModal(
      BuildContext context, UserModel tech, String token) {
    final profile = tech.technicianProfile;
    final isPending = (profile?.approvalStatus ?? 'pending') == 'pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thanh kéo nhỏ
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hồ Sơ KYC: ${tech.fullName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Đăng ký: ${tech.createdAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(tech.createdAt!) : "N/A"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              // 1. Giấy tờ CCCD 2 mặt
              Row(
                children: [
                  const Text(
                    'Ảnh CCCD / CMND 2 Mặt:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Spacer(),
                  Text(
                    'Chạm ảnh để phóng to & soi chi tiết',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildImagePreviewCard(
                      ctx,
                      title: 'Mặt trước',
                      imageUrl: profile?.idCardFront ?? '',
                      fullName: tech.fullName,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildImagePreviewCard(
                      ctx,
                      title: 'Mặt sau',
                      imageUrl: profile?.idCardBack ?? '',
                      fullName: tech.fullName,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Bằng cấp & Chứng chỉ
              Row(
                children: [
                  const Text(
                    'Chứng chỉ nghề & Bằng cấp:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${profile?.certificates.length ?? 0}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if ((profile?.certificates ?? []).isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondaryColor),
                      SizedBox(width: 8),
                      Text(
                        'Thợ không đính kèm chứng chỉ bổ sung',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: profile!.certificates.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _buildCertificateThumbnail(
                      ctx,
                      profile.certificates[i],
                      i + 1,
                      tech.fullName,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // 3. Thông tin cá nhân & nghề nghiệp
              const Text(
                'Thông tin cá nhân & chuyên môn:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Số điện thoại', tech.phoneNumber),
                    _buildInfoRow('Email', tech.email),
                    _buildInfoRow('Giới tính', tech.genderDisplay),
                    _buildInfoRow(
                      'Ngày sinh',
                      DateFormat('dd/MM/yyyy').format(tech.dateOfBirth),
                    ),
                    _buildInfoRow(
                      'Kinh nghiệm',
                      '${profile?.experienceYears ?? 0} năm trong nghề',
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Chuyên môn:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: (profile?.skills ?? []).map((skill) {
                        return Chip(
                          label: Text(
                            skill,
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.blue.shade50,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Giới thiệu bản thân:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (profile?.bio.isNotEmpty == true)
                          ? profile!.bio
                          : 'Chưa cập nhật phần giới thiệu.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Hiển thị lý do từ chối nếu có
              if (profile?.rejectionReason.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
                          SizedBox(width: 6),
                          Text(
                            'Lý do từ chối trước đó:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile!.rejectionReason,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (profile.rejectedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Thời gian từ chối: ${DateFormat('dd/MM/yyyy HH:mm').format(profile.rejectedAt!)}',
                          style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Hiển thị thông tin duyệt nếu đã approved
              if (profile?.approvalStatus == 'approved') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đã phê duyệt${profile?.approvedAt != null ? " vào lúc ${DateFormat('dd/MM/yyyy HH:mm').format(profile!.approvedAt!)}" : ""}${profile?.approvedByName != null ? " bởi ${profile!.approvedByName}" : ""}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // 4. Các nút thao tác Phê duyệt / Từ chối (Nếu là Pending hoặc Rejected cần duyệt lại)
              if (isPending)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text(
                          'Từ chối',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showRejectReasonDialog(context, tech, token);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text(
                          'Phê duyệt',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmApprove(context, tech, token);
                        },
                      ),
                    ),
                  ],
                )
              else if (profile?.approvalStatus == 'rejected')
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text(
                    'Xem xét & Phê duyệt lại',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmApprove(context, tech, token);
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewCard(
    BuildContext context, {
    required String title,
    required String imageUrl,
    required String fullName,
  }) {
    final hasImage = imageUrl.isNotEmpty;
    return InkWell(
      onTap: hasImage
          ? () => _zoomImage(context, imageUrl, title: 'CCCD $title - $fullName')
          : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasImage ? Colors.grey.shade300 : Colors.red.shade200,
          ),
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.zoom_in,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.no_photography_outlined,
                        size: 28, color: Colors.red.shade300),
                    const SizedBox(height: 4),
                    Text(
                      'Thiếu $title',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCertificateThumbnail(
    BuildContext context,
    String imageUrl,
    int index,
    String fullName,
  ) {
    return GestureDetector(
      onTap: () => _zoomImage(
        context,
        imageUrl,
        title: 'Chứng chỉ $index - $fullName',
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Image.network(
              imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
              errorBuilder: (_, _, _) => Container(
                width: 100,
                height: 100,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.zoom_in, color: Colors.white, size: 14),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  'Chứng chỉ $index',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _zoomImage(
    BuildContext context,
    String imageUrl, {
    String title = 'Ảnh tài liệu',
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 250,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.white70, size: 48),
                        SizedBox(height: 8),
                        Text(
                          'Không thể tải hình ảnh này',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                'Dùng 2 ngón tay thu phóng để soi rõ thông tin CCCD/Chứng chỉ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmApprove(BuildContext context, UserModel tech, String token) {
    final skills = (tech.technicianProfile?.skills ?? []).join(', ');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_outlined, color: Colors.green),
            SizedBox(width: 8),
            Text('Xác nhận phê duyệt'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn phê duyệt hồ sơ thợ:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tech.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text('SĐT: ${tech.phoneNumber}'),
                  if (skills.isNotEmpty) Text('Chuyên môn: $skills'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Sau khi duyệt, tài khoản thợ sẽ được kích hoạt quyền nhận việc và có thể bắt đầu báo giá các sự cố của khách.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<TechnicianProvider>();
              final success = await provider.approveTechnician(token, tech.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Đã duyệt hồ sơ thợ thành công!'
                        : (provider.errorMessage ?? 'Duyệt thất bại')),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                _loadCurrentTab();
              }
            },
            child: const Text('Xác nhận Duyệt'),
          ),
        ],
      ),
    );
  }

  void _showRejectReasonDialog(
      BuildContext context, UserModel tech, String token) {
    _reasonController.clear();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text('Từ chối hồ sơ KYC'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lý do từ chối hồ sơ thợ "${tech.fullName}":'),
                const SizedBox(height: 8),
                const Text(
                  'Chọn nhanh lý do mẫu:',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _quickRejectReasons.map((reason) {
                    return ActionChip(
                      label: Text(reason, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.red.shade50,
                      side: BorderSide(color: Colors.red.shade200),
                      onPressed: () {
                        setStateModal(() {
                          if (_reasonController.text.trim().isEmpty) {
                            _reasonController.text = reason;
                          } else {
                            _reasonController.text =
                                '${_reasonController.text.trim()}, $reason';
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Nhập chi tiết yêu cầu bổ sung hoặc sửa đổi...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final reason = _reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập lý do từ chối!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                final provider = context.read<TechnicianProvider>();
                final success =
                    await provider.rejectTechnician(token, tech.id, reason);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Đã từ chối hồ sơ thợ.'
                          : (provider.errorMessage ?? 'Thao tác thất bại')),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                  _loadCurrentTab();
                }
              },
              child: const Text('Gửi Từ Chối'),
            ),
          ],
        ),
      ),
    );
  }
}
