import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/user_model.dart';

class TechnicianPublicProfileScreen extends StatelessWidget {
  final UserModel technician;

  const TechnicianPublicProfileScreen({
    super.key,
    required this.technician,
  });

  @override
  Widget build(BuildContext context) {
    final profile = technician.technicianProfile;
    final rating = profile?.rating ?? 5.0;
    final reviewCount = profile?.reviewCount ?? 0;
    final completedJobs = profile?.completedJobsCount ?? 0;
    final isAvailable = profile?.isAvailable ?? false;
    final skills = profile?.skills ?? [];
    final experienceYears = profile?.experienceYears ?? 0;
    final bio = profile?.bio ?? '';
    final certificates = profile?.certificates ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ Sơ Thợ Kỹ Thuật'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Thẻ Header Tổng quan
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                        backgroundImage: technician.avatar.isNotEmpty
                            ? NetworkImage(technician.avatar)
                            : null,
                        child: technician.avatar.isEmpty
                            ? Text(
                                technician.initials,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isAvailable ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Họ tên
                  Text(
                    technician.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Badge Trạng thái nhận việc
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAvailable
                              ? Icons.check_circle_outline
                              : Icons.schedule_outlined,
                          size: 14,
                          color: isAvailable ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAvailable ? 'Đang nhận việc' : 'Tạm bận / Nghỉ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isAvailable ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Bộ 3 chỉ số: Đánh giá sao, Số ca hoàn thành, Năm kinh nghiệm
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        icon: Icons.star_rounded,
                        iconColor: Colors.amber,
                        title: '$rating ★',
                        subtitle: '$reviewCount đánh giá',
                      ),
                      Container(height: 32, width: 1, color: Colors.grey.shade200),
                      _buildStatItem(
                        icon: Icons.task_alt_rounded,
                        iconColor: AppTheme.primaryColor,
                        title: '$completedJobs ca',
                        subtitle: 'Đã hoàn thành',
                      ),
                      Container(height: 32, width: 1, color: Colors.grey.shade200),
                      _buildStatItem(
                        icon: Icons.workspace_premium_rounded,
                        iconColor: Colors.purple,
                        title: '$experienceYears năm',
                        subtitle: 'Kinh nghiệm',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Chuyên môn kỹ thuật
            _buildSectionCard(
              title: 'Lĩnh vực chuyên môn',
              icon: Icons.handyman_outlined,
              child: skills.isEmpty
                  ? const Text('Chưa cập nhật kỹ năng')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skills.map((skill) {
                        return Chip(
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.08),
                          side: BorderSide.none,
                          avatar: const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          label: Text(
                            skill,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 16),

            // 3. Giới thiệu / Bio
            _buildSectionCard(
              title: 'Giới thiệu bản thân',
              icon: Icons.info_outline,
              child: Text(
                bio.isNotEmpty
                    ? bio
                    : 'Thợ lành nghề, nhiệt tình, có trách nhiệm và đầy đủ dụng cụ sửa chữa chuyên dụng.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Bằng cấp & Chứng chỉ nghề đã xác thực
            _buildSectionCard(
              title: 'Chứng chỉ nghề & Bằng cấp đã xác thực',
              icon: Icons.verified_outlined,
              child: certificates.isEmpty
                  ? const Text(
                      'Thợ chưa đăng tải chứng chỉ bổ sung.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Các chứng chỉ sau đã được ban quản trị HomeFix kiểm duyệt:',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 110,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: certificates.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 10),
                            itemBuilder: (ctx, idx) {
                              final certUrl = certificates[idx];
                              return GestureDetector(
                                onTap: () => _viewZoomImage(context, certUrl),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    certUrl,
                                    width: 140,
                                    height: 110,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 140,
                                      height: 110,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                              );
                            },

                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // 5. Nút Đặt lịch dịch vụ
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text(
                'Đặt Lịch Với Thợ Này',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: isAvailable
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Bạn đã chọn thợ ${technician.fullName}. Chuyển sang bước chọn dịch vụ!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  : null,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  void _viewZoomImage(BuildContext context, String imageUrl) {
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
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
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
}
