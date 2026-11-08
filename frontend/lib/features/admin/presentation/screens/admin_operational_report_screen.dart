// Tác giả: Bảo (CE191178)
// Chức năng: Thống kê báo cáo vận hành - Xem biểu đồ tỷ lệ đơn thành công, doanh thu và năng suất (#UC-STF-05)

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_provider.dart';

class AdminOperationalReportScreen extends StatefulWidget {
  const AdminOperationalReportScreen({super.key});

  @override
  State<AdminOperationalReportScreen> createState() =>
      _AdminOperationalReportScreenState();
}

class _AdminOperationalReportScreenState
    extends State<AdminOperationalReportScreen> {
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReport();
    });
  }

  void _loadReport() {
    final token = context.read<AuthProvider>().token;
    if (token != null && token.isNotEmpty) {
      context.read<AdminProvider>().fetchOperationalReport(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthProvider>().token ?? '';
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text(
          'Thống kê & Báo cáo vận hành',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới báo cáo',
            icon: const Icon(Icons.refresh),
            onPressed: _loadReport,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(provider, token),
          Expanded(
            child: _buildReportBody(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(AdminProvider provider, String token) {
    final periods = [
      {'key': 'all', 'label': 'Toàn thời gian'},
      {'key': '7d', 'label': '7 ngày qua'},
      {'key': '30d', 'label': '30 ngày qua'},
      {'key': '90d', 'label': '90 ngày qua'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: 8),
            const Text(
              'Kỳ báo cáo:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(width: 8),
            ...periods.map((item) {
              final key = item['key']!;
              final label = item['label']!;
              final isSelected = provider.reportPeriod == key;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor: Colors.grey.shade100,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color:
                        isSelected ? Colors.white : AppTheme.textPrimaryColor,
                  ),
                  onSelected: (_) => provider.setReportPeriod(key, token),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildReportBody(AdminProvider provider) {
    if (provider.isReportLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final report = provider.operationalReport;
    if (report == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bar_chart_outlined, size: 52, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage ?? 'Chưa có dữ liệu báo cáo vận hành',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Tải lại báo cáo'),
                onPressed: _loadReport,
              ),
            ],
          ),
        ),
      );
    }

    final orderStats = report['orderStats'] is Map
        ? Map<String, dynamic>.from(report['orderStats'] as Map)
        : <String, dynamic>{};
    final revenueStats = report['revenueStats'] is Map
        ? Map<String, dynamic>.from(report['revenueStats'] as Map)
        : <String, dynamic>{};
    final productivityStats = report['productivityStats'] is Map
        ? Map<String, dynamic>.from(report['productivityStats'] as Map)
        : <String, dynamic>{};

    return RefreshIndicator(
      onRefresh: () async => _loadReport(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
        children: [
          _buildKpiGrid(orderStats, revenueStats),
          const SizedBox(height: 16),
          _buildOrderRateChartCard(orderStats),
          const SizedBox(height: 16),
          _buildRevenueChartCard(revenueStats),
          const SizedBox(height: 16),
          _buildProductivityChartCard(productivityStats),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(
    Map<String, dynamic> orderStats,
    Map<String, dynamic> revenueStats,
  ) {
    final totalRevenue = (revenueStats['totalRevenue'] as num?)?.toDouble() ?? 0;
    final avgOrderVal =
        (revenueStats['averageOrderValue'] as num?)?.toDouble() ?? 0;
    final totalOrders = (orderStats['totalOrders'] as num?)?.toInt() ?? 0;
    final completedOrders =
        (orderStats['completedOrders'] as num?)?.toInt() ?? 0;
    final successRate = (orderStats['successRate'] as num?)?.toDouble() ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'Tổng doanh thu',
                value: _currencyFormat.format(totalRevenue),
                subtitle: '$completedOrders đơn hoàn tất',
                icon: Icons.payments_outlined,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'Tỷ lệ thành công',
                value: '${successRate.toStringAsFixed(1)}%',
                subtitle: '$completedOrders / $totalOrders tổng đơn',
                icon: Icons.verified_outlined,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'Tổng số đơn hàng',
                value: '$totalOrders đơn',
                subtitle:
                    'Đang xử lý: ${(orderStats['inProgressOrders'] ?? 0) + (orderStats['openOrders'] ?? 0)} đơn',
                icon: Icons.receipt_long_outlined,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKpiCard(
                title: 'Giá trị TB / đơn',
                value: _currencyFormat.format(avgOrderVal),
                subtitle: 'Trên mỗi đơn hoàn tất',
                icon: Icons.trending_up_rounded,
                color: Colors.teal.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRateChartCard(Map<String, dynamic> orderStats) {
    final totalOrders = (orderStats['totalOrders'] as num?)?.toInt() ?? 0;
    final completed = (orderStats['completedOrders'] as num?)?.toInt() ?? 0;
    final inProgress = (orderStats['inProgressOrders'] as num?)?.toInt() ?? 0;
    final open = (orderStats['openOrders'] as num?)?.toInt() ?? 0;
    final cancelled = (orderStats['cancelledOrders'] as num?)?.toInt() ?? 0;
    final successRate = (orderStats['successRate'] as num?)?.toDouble() ?? 0;

    final segments = [
      _ChartSegment('Đã hoàn tất', completed, Colors.green.shade600),
      _ChartSegment('Đang sửa chữa', inProgress, Colors.blue.shade600),
      _ChartSegment('Chờ báo giá/thợ', open, Colors.amber.shade700),
      _ChartSegment('Đã hủy', cancelled, Colors.red.shade600),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded,
                  size: 20, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Biểu đồ Tỷ lệ đơn hàng',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(130, 130),
                      painter: _DonutChartPainter(
                        segments: segments,
                        total: totalOrders,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${successRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const Text(
                          'Thành công',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: segments.map((seg) {
                    final pct = totalOrders > 0
                        ? (seg.value / totalOrders * 100).toStringAsFixed(1)
                        : '0.0';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: seg.color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              seg.label,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                          Text(
                            '${seg.value} ($pct%)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChartCard(Map<String, dynamic> revenueStats) {
    final totalRevenue =
        (revenueStats['totalRevenue'] as num?)?.toDouble() ?? 0;
    final labourCost =
        (revenueStats['totalLabourCost'] as num?)?.toDouble() ?? 0;
    final partsCost =
        (revenueStats['totalPartsCost'] as num?)?.toDouble() ?? 0;
    final additionalCost =
        (revenueStats['totalAdditionalCost'] as num?)?.toDouble() ?? 0;

    final rawCategories =
        (revenueStats['revenueByCategory'] as List<dynamic>? ?? []);
    final categories = rawCategories
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    double maxCatRevenue = 0;
    for (final c in categories) {
      final rev = (c['revenue'] as num?)?.toDouble() ?? 0;
      if (rev > maxCatRevenue) maxCatRevenue = rev;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 20, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Biểu đồ Doanh thu & Danh mục dịch vụ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cơ cấu chi phí tạo doanh thu
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildCostBreakdownRow(
                  'Tiền công thợ sửa chữa',
                  labourCost,
                  totalRevenue,
                  Colors.blue.shade700,
                ),
                const SizedBox(height: 8),
                _buildCostBreakdownRow(
                  'Linh kiện theo báo giá',
                  partsCost,
                  totalRevenue,
                  Colors.teal.shade700,
                ),
                const SizedBox(height: 8),
                _buildCostBreakdownRow(
                  'Phụ tùng phát sinh (đã duyệt)',
                  additionalCost,
                  totalRevenue,
                  Colors.orange.shade800,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Text(
            'Doanh thu theo Danh mục dịch vụ:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 10),

          if (categories.isEmpty)
            const Text(
              'Chưa có dữ liệu danh mục dịch vụ',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            )
          else
            ...categories.map((cat) {
              final name = (cat['categoryName'] ?? 'Danh mục').toString();
              final rev = (cat['revenue'] as num?)?.toDouble() ?? 0;
              final completedCount =
                  (cat['completedCount'] as num?)?.toInt() ?? 0;
              final totalReq = (cat['totalRequests'] as num?)?.toInt() ?? 0;
              final ratio = maxCatRevenue > 0 ? (rev / maxCatRevenue) : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$name ($completedCount/$totalReq đơn hoàn tất)',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currencyFormat.format(rev),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        minHeight: 9,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.green.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCostBreakdownRow(
    String label,
    double amount,
    double total,
    Color color,
  ) {
    final pct = total > 0 ? (amount / total * 100) : 0.0;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimaryColor),
          ),
        ),
        Text(
          '${_currencyFormat.format(amount)} (${pct.toStringAsFixed(0)}%)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProductivityChartCard(Map<String, dynamic> productivityStats) {
    final totalTechs =
        (productivityStats['totalTechnicians'] as num?)?.toInt() ?? 0;
    final approvedTechs =
        (productivityStats['approvedTechniciansCount'] as num?)?.toInt() ?? 0;
    final onlineTechs =
        (productivityStats['onlineTechniciansCount'] as num?)?.toInt() ?? 0;
    final pendingKyc =
        (productivityStats['pendingKycCount'] as num?)?.toInt() ?? 0;
    final totalComplaints =
        (productivityStats['totalComplaints'] as num?)?.toInt() ?? 0;
    final resolvedComplaints =
        (productivityStats['resolvedComplaints'] as num?)?.toInt() ?? 0;
    final complaintRate =
        (productivityStats['complaintResolutionRate'] as num?)?.toDouble() ??
            100;

    final rawTopTechs =
        (productivityStats['topTechnicians'] as List<dynamic>? ?? []);
    final topTechs = rawTopTechs
        .map((e) => Map<String, dynamic>.from(e as Map))
        .take(8)
        .toList();

    int maxCompletedJobs = 1;
    for (final t in topTechs) {
      final jobs = (t['completedJobs'] as num?)?.toInt() ?? 0;
      if (jobs > maxCompletedJobs) maxCompletedJobs = jobs;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.leaderboard_outlined,
                  size: 20, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                'Năng suất Kỹ thuật viên & Vận hành',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Hàng chỉ số vận hành
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(
                    'Thợ đã duyệt', '$approvedTechs/$totalTechs', Colors.teal),
                _buildMiniStat('Đang Online', '$onlineTechs', Colors.green),
                _buildMiniStat('Chờ KYC', '$pendingKyc', Colors.orange.shade800),
                _buildMiniStat(
                  'Xử lý KN',
                  '$resolvedComplaints/$totalComplaints (${complaintRate.toStringAsFixed(0)}%)',
                  Colors.deepPurple,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Text(
            'Biểu đồ Năng suất Thợ sửa chữa:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 10),

          if (topTechs.isEmpty)
            const Text(
              'Chưa có dữ liệu kỹ thuật viên',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            )
          else
            ...topTechs.asMap().entries.map((entry) {
              final idx = entry.key;
              final tech = entry.value;
              final name = (tech['fullName'] ?? 'Thợ').toString();
              final completedJobs =
                  (tech['completedJobs'] as num?)?.toInt() ?? 0;
              final assignedJobs = (tech['assignedJobs'] as num?)?.toInt() ?? 0;
              final activeJobs = (tech['activeJobs'] as num?)?.toInt() ?? 0;
              final rating =
                  (tech['averageRating'] as num?)?.toDouble() ?? 0.0;
              final revenue =
                  (tech['revenueGenerated'] as num?)?.toDouble() ?? 0.0;
              final completionRate =
                  (tech['completionRate'] as num?)?.toDouble() ?? 0.0;

              final barRatio = (completedJobs / maxCompletedJobs).clamp(0.0, 1.0);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: idx < 3
                              ? Colors.amber.shade100
                              : Colors.grey.shade200,
                          child: Text(
                            '${idx + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: idx < 3
                                  ? Colors.amber.shade900
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: Colors.amber.shade800,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hoàn tất: $completedJobs/$assignedJobs đơn (${completionRate.toStringAsFixed(0)}%) • Đang làm: $activeJobs',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        Text(
                          _currencyFormat.format(revenue),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: barRatio,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}

class _ChartSegment {
  final String label;
  final int value;
  final Color color;

  _ChartSegment(this.label, this.value, this.color);
}

class _DonutChartPainter extends CustomPainter {
  final List<_ChartSegment> segments;
  final int total;

  _DonutChartPainter({
    required this.segments,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    const strokeWidth = 18.0;

    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (total <= 0) return;

    double startAngle = -math.pi / 2;
    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final sweepAngle = (seg.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.segments != segments;
  }
}
