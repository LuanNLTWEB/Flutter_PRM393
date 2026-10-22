import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/complaint_model.dart';
import '../providers/complaint_provider.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  static const _filters = <String, String>{
    'ALL': 'Tất cả',
    'RECEIVED': 'Mới',
    'IN_REVIEW': 'Đang xử lý',
    'RESOLVED': 'Đã giải quyết',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadComplaints());
  }

  Future<void> _loadComplaints({String? status}) async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;
    await context.read<ComplaintProvider>().fetchComplaints(
      token,
      status: status,
    );
  }

  Future<void> _showHandleDialog(ComplaintModel complaint) async {
    final noteController = TextEditingController(text: complaint.staffNote);
    String selectedStatus = complaint.status == 'RECEIVED'
        ? 'IN_REVIEW'
        : 'RESOLVED';
    String? validationMessage;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Lập biên bản xử lý'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint.subject,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái xử lý',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'IN_REVIEW',
                      child: Text('Đang xử lý'),
                    ),
                    DropdownMenuItem(
                      value: 'RESOLVED',
                      child: Text('Đã giải quyết'),
                    ),
                    DropdownMenuItem(
                      value: 'REJECTED',
                      child: Text('Không chấp nhận'),
                    ),
                  ],
                  onChanged: (value) => setDialogState(() {
                    selectedStatus = value ?? selectedStatus;
                    validationMessage = null;
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Biên bản / ghi chú Staff',
                    hintText:
                        'Ghi rõ cách đối chiếu, kết quả và hướng xử lý...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                if (validationMessage != null)
                  Text(
                    validationMessage!,
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedStatus != 'IN_REVIEW' &&
                    noteController.text.trim().length < 10) {
                  setDialogState(() {
                    validationMessage = 'Cần ghi biên bản tối thiểu 10 ký tự trước khi kết thúc.';
                  });
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Lưu cập nhật'),
            ),
          ],
        ),
      ),
    );

    if (submitted != true || !mounted) {
      noteController.dispose();
      return;
    }

    final token = context.read<AuthProvider>().token ?? '';
    final provider = context.read<ComplaintProvider>();
    final success = await provider.handleComplaint(
      token: token,
      complaintId: complaint.id,
      status: selectedStatus,
      staffNote: noteController.text,
    );
    noteController.dispose();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.successMessage ?? provider.errorMessage ?? 'Đã cập nhật',
        ),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );
    if (success) _loadComplaints();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComplaintProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text('Khiếu nại & tranh chấp'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: provider.isLoading ? null : _loadComplaints,
          ),
        ],
      ),
      body: provider.isLoading && provider.complaints.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadComplaints,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _SummaryCard(
                    received: provider.countOf('RECEIVED'),
                    inReview: provider.countOf('IN_REVIEW'),
                    resolved: provider.countOf('RESOLVED'),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.entries
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(entry.value),
                                selected: provider.statusFilter == entry.key,
                                onSelected: (_) =>
                                    _loadComplaints(status: entry.key),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (provider.errorMessage != null)
                    _ErrorState(message: provider.errorMessage!)
                  else if (provider.complaints.isEmpty)
                    const _EmptyState()
                  else
                    ...provider.complaints.map(
                      (complaint) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ComplaintCard(
                          complaint: complaint,
                          onHandle: complaint.isFinal
                              ? null
                              : () => _showHandleDialog(complaint),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int received;
  final int inReview;
  final int resolved;

  const _SummaryCard({
    required this.received,
    required this.inReview,
    required this.resolved,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0B7285), Color(0xFF168AAD)],
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.support_agent_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Hàng đợi hỗ trợ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _SummaryItem(label: 'Mới', count: received),
            _SummaryItem(label: 'Đang xử lý', count: inReview),
            _SummaryItem(label: 'Đã xong', count: resolved),
          ],
        ),
      ],
    ),
  );
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final int count;

  const _SummaryItem({required this.label, required this.count});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .82),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback? onHandle;

  const _ComplaintCard({required this.complaint, this.onHandle});

  Color _statusColor() {
    switch (complaint.status) {
      case 'RECEIVED':
        return Colors.orange.shade700;
      case 'IN_REVIEW':
        return Colors.blue.shade700;
      case 'RESOLVED':
        return Colors.green.shade700;
      default:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    final createdAt = complaint.createdAt;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  complaint.categoryDisplay,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  complaint.statusDisplay,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            complaint.subject,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            'Đơn: ${complaint.requestTitle}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${complaint.reporterName}  ↔  ${complaint.respondentName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            complaint.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 13,
            ),
          ),
          if (complaint.staffNote.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                'Biên bản: ${complaint.staffNote}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  createdAt == null
                      ? ''
                      : DateFormat('HH:mm, dd/MM/yyyy').format(createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
              if (onHandle != null)
                OutlinedButton.icon(
                  onPressed: onHandle,
                  icon: const Icon(Icons.edit_note_rounded, size: 17),
                  label: const Text('Xử lý'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.red.shade700),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 72),
    child: Column(
      children: [
        Icon(
          Icons.sentiment_satisfied_alt_rounded,
          size: 58,
          color: AppTheme.textSecondaryColor,
        ),
        SizedBox(height: 12),
        Text(
          'Không có khiếu nại trong mục này',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    ),
  );
}
