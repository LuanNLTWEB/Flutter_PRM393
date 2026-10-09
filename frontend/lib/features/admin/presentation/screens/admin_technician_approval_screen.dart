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
    super.dispose();
  }

  void _loadCurrentTab() {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final statuses = ['pending', 'approved', 'rejected'];
    final currentStatus = statuses[_tabController.index];
    context
        .read<TechnicianProvider>()
        .fetchKYCTechnicians(token, status: currentStatus);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TechnicianProvider>();
    final token = context.watch<AuthProvider>().token ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Duyệt Hồ Sơ Thợ (KYC)'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Chờ duyệt'),
            Tab(text: 'Đã duyệt'),
            Tab(text: 'Từ chối'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadCurrentTab(),
              child: provider.kycTechnicians.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Không có hồ sơ nào trong mục này',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
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
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Đã duyệt';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Đã từ chối';
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusText = 'Chờ duyệt';
    }

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
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
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
              Row(
                children: [
                  const Icon(Icons.handyman_outlined,
                      size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Kỹ năng: ${(profile?.skills ?? []).join(', ')}',
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
                    child: Text(
                      'Hồ Sơ KYC: ${tech.fullName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
              const Text(
                'Ảnh CCCD / CMND 2 Mặt:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildImagePreviewCard(
                      ctx,
                      title: 'Mặt trước',
                      imageUrl: profile?.idCardFront ?? '',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildImagePreviewCard(
                      ctx,
                      title: 'Mặt sau',
                      imageUrl: profile?.idCardBack ?? '',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Bằng cấp & Chứng chỉ
              const Text(
                'Chứng chỉ nghề & Bằng cấp:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 10),
              if ((profile?.certificates ?? []).isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Thợ không đính kèm chứng chỉ bổ sung',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                  ),
                )
              else
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: profile!.certificates.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),

                    itemBuilder: (_, i) => _buildCertificateThumbnail(
                      ctx,
                      profile.certificates[i],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // 3. Thông tin nghề nghiệp
              const Text(
                'Kinh nghiệm & Giới thiệu:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                '• Kinh nghiệm: ${profile?.experienceYears ?? 0} năm',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '• Giới thiệu: ${profile?.bio.isNotEmpty == true ? profile!.bio : "Không có"}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimaryColor),
              ),
              if (profile?.rejectionReason.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    'Lý do từ chối: ${profile!.rejectionReason}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // 4. Các nút thao tác Phê duyệt / Từ chối (Nếu là Pending)
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
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreviewCard(
      BuildContext context, {
      required String title,
      required String imageUrl,
  }) {
    return InkWell(
      onTap: imageUrl.isNotEmpty ? () => _zoomImage(context, imageUrl) : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image),
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
                child: Text(
                  'Không có ảnh $title',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
      ),
    );
  }

  Widget _buildCertificateThumbnail(BuildContext context, String imageUrl) {
    return GestureDetector(
      onTap: () => _zoomImage(context, imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            width: 100,
            height: 100,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image),
          ),

        ),
      ),
    );
  }

  void _zoomImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmApprove(BuildContext context, UserModel tech, String token) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận phê duyệt'),
        content: Text(
          'Bạn có chắc chắn muốn phê duyệt hồ sơ cho thợ "${tech.fullName}"?\nThợ sẽ bắt đầu được cấp quyền nhận việc.',
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
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối hồ sơ KYC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vui lòng nêu rõ lý do từ chối hồ sơ thợ "${tech.fullName}":'),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ví dụ: Ảnh CCCD bị mờ, thiếu chứng chỉ nghề...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
    );
  }
}
