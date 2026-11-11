import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/review_model.dart';
import '../providers/review_provider.dart';
import 'create_review_screen.dart';

class TechnicianReviewsScreen extends StatefulWidget {
  final String technicianId;
  final String technicianName;
  final String? bookingId;

  const TechnicianReviewsScreen({
    super.key,
    required this.technicianId,
    required this.technicianName,
    this.bookingId,
  });

  @override
  State<TechnicianReviewsScreen> createState() =>
      _TechnicianReviewsScreenState();
}

class _TechnicianReviewsScreenState extends State<TechnicianReviewsScreen> {
  int? _selectedStar;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviews();
    });
  }

  void _loadReviews() {
    context.read<ReviewProvider>().fetchTechnicianReviews(
          widget.technicianId,
          star: _selectedStar,
        );
  }

  @override
  Widget build(BuildContext context) {
    final reviewProvider = context.watch<ReviewProvider>();
    final summary = reviewProvider.summary;
    final currentUser = context.watch<AuthProvider>().currentUser;
    final currentUserId = currentUser?.id ?? '';
    final isTechnicianOwner = (currentUser?.role == 'technician' &&
            currentUser?.id == widget.technicianId) ||
        currentUser?.role == 'admin';

    // Tìm đánh giá của chính người dùng hiện tại (nếu có)
    ReviewModel? myReview;
    for (final r in reviewProvider.reviews) {
      if ((widget.bookingId != null && r.bookingId == widget.bookingId) ||
          (currentUserId.isNotEmpty && r.customerId == currentUserId)) {
        myReview = r;
        break;
      }
    }

    final hasBooking = widget.bookingId != null || (myReview != null && (myReview.bookingId?.isNotEmpty ?? false));
    final targetBookingId = widget.bookingId ?? myReview?.bookingId ?? '';
    final isEditing = myReview != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTechnicianOwner
              ? 'Đánh giá của tôi (${widget.technicianName})'
              : 'Đánh giá: ${widget.technicianName}',
        ),
      ),
      bottomNavigationBar: (!isTechnicianOwner && hasBooking && targetBookingId.isNotEmpty)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  style: isEditing
                      ? ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        )
                      : ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                  icon: Icon(
                    isEditing ? Icons.edit_note_rounded : Icons.rate_review_rounded,
                  ),
                  label: Text(
                    isEditing ? 'Chỉnh sửa đánh giá của bạn' : 'Viết đánh giá cho thợ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => CreateReviewScreen(
                          technicianId: widget.technicianId,
                          technicianName: widget.technicianName,
                          bookingId: targetBookingId,
                          initialRating: myReview?.rating,
                          initialTags: myReview?.tags,
                          initialComment: myReview?.comment,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadReviews();
                    }
                  },
                ),
              ),
            )
          : null,
      body: reviewProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadReviews(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Thẻ thống kê điểm số
                    if (summary != null)
                      _buildSummaryCard(summary)
                    else
                      const SizedBox.shrink(),
                    const SizedBox(height: 16),

                    // Lọc theo số sao
                    _buildFilterChips(),
                    const SizedBox(height: 16),

                    // Danh sách nhận xét
                    if (reviewProvider.reviews.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviewProvider.reviews.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final review = reviewProvider.reviews[index];
                          final isMyReview = (currentUserId.isNotEmpty && review.customerId == currentUserId) ||
                              (widget.bookingId != null && review.bookingId == widget.bookingId);
                          return _buildReviewCard(
                            review,
                            isMyReview: isMyReview,
                            isTechnicianOwner: isTechnicianOwner,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(ReviewSummaryModel summary) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Cột điểm trung bình
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  summary.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return Icon(
                      starIndex <= summary.averageRating.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber[700],
                      size: 18,
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  '${summary.totalReviews} lượt đánh giá',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            // Thanh tiến trình từng sao (5 sao -> 1 sao)
            Expanded(
              child: Column(
                children: [5, 4, 3, 2, 1].map((star) {
                  final count = summary.starBreakdown[star] ?? 0;
                  final ratio = summary.totalReviews > 0
                      ? count / summary.totalReviews
                      : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        Text(
                          '$star',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: Colors.grey[200],
                              color: Colors.amber[700],
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 24,
                          child: Text(
                            '$count',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondaryColor,
                            ),
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
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Tất cả'),
            selected: _selectedStar == null,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedStar = null);
                _loadReviews();
              }
            },
          ),
          const SizedBox(width: 8),
          ...[5, 4, 3, 2, 1].map((star) {
            final isSelected = _selectedStar == star;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$star'),
                    const SizedBox(width: 2),
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedStar = selected ? star : null;
                  });
                  _loadReviews();
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    ReviewModel review, {
    bool isMyReview = false,
    bool isTechnicianOwner = false,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final formattedDate = review.createdAt != null
        ? dateFormat.format(review.createdAt!)
        : '';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isMyReview ? Colors.amber.shade300 : Colors.grey.shade200,
          width: isMyReview ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Khách hàng & Số sao
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isMyReview
                      ? Colors.amber.shade100
                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    review.customerName.isNotEmpty
                        ? review.customerName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: isMyReview ? Colors.amber.shade900 : AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
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
                          Flexible(
                            child: Text(
                              review.customerName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isMyReview) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Text(
                                'Bạn',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber[700],
                      size: 16,
                    );
                  }),
                ),
                if (isMyReview) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      Icons.edit_note_rounded,
                      size: 22,
                      color: Colors.amber.shade800,
                    ),
                    tooltip: 'Chỉnh sửa đánh giá',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      final targetBookingId =
                          widget.bookingId ?? review.bookingId ?? '';
                      if (targetBookingId.isEmpty) return;
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => CreateReviewScreen(
                            technicianId: widget.technicianId,
                            technicianName: widget.technicianName,
                            bookingId: targetBookingId,
                            initialRating: review.rating,
                            initialTags: review.tags,
                            initialComment: review.comment,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadReviews();
                      }
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Tags
            if (review.tags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: review.tags.map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],

            // Bình luận
            if (review.comment.isNotEmpty)
              Text(
                review.comment,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimaryColor,
                  height: 1.4,
                ),
              ),

            // Phản hồi của thợ (UC-RAT-02)
            if (review.reply != null && review.reply!.comment.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.reply_rounded,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isTechnicianOwner
                                ? 'Phản hồi của bạn'
                                : 'Phản hồi từ thợ (${widget.technicianName})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        if (review.reply?.repliedAt != null)
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm')
                                .format(review.reply!.repliedAt!),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        if (isTechnicianOwner) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            color: AppTheme.primaryColor,
                            tooltip: 'Chỉnh sửa phản hồi',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _openReplySheet(context, review),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                            ),
                            color: Colors.red.shade600,
                            tooltip: 'Xóa phản hồi',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () =>
                                _confirmDeleteReply(context, review),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      review.reply!.comment,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimaryColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isTechnicianOwner) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.reply_rounded, size: 15),
                  label: const Text(
                    'Phản hồi nhận xét này',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => _openReplySheet(context, review),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Mở BottomSheet phản hồi nhận xét (UC-RAT-02)
  void _openReplySheet(BuildContext context, ReviewModel review) {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để thực hiện')),
      );
      return;
    }

    final isEditing = review.reply != null && review.reply!.comment.isNotEmpty;
    final controller = TextEditingController(text: review.reply?.comment ?? '');

    final quickReplies = [
      'Cảm ơn bạn đã tin tưởng dịch vụ!',
      'Rất vui được hỗ trợ quý khách!',
      'Cảm ơn anh/chị nhiều, chúc gia đình thật nhiều sức khỏe!',
      'HomeFix luôn sẵn sàng phục vụ khi bạn cần!',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final reviewProvider = context.watch<ReviewProvider>();
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom:
                    MediaQuery.of(bottomSheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isEditing
                                  ? Icons.edit_note_rounded
                                  : Icons.reply_rounded,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEditing
                                  ? 'Chỉnh sửa phản hồi'
                                  : 'Phản hồi đánh giá',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Trích dẫn nhận xét của khách
                    Container(
                      padding: const EdgeInsets.all(12),
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
                              Text(
                                review.customerName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Row(
                                children: List.generate(5, (idx) {
                                  return Icon(
                                    idx < review.rating.round()
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 13,
                                    color: Colors.amber[700],
                                  );
                                }),
                              ),
                            ],
                          ),
                          if (review.comment.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '"${review.comment}"',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Gợi ý phản hồi nhanh
                    const Text(
                      'Gợi ý câu trả lời nhanh:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: quickReplies.map((text) {
                        return ActionChip(
                          backgroundColor: Colors.blue.shade50,
                          side: BorderSide(color: Colors.blue.shade100),
                          label: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          onPressed: () {
                            setSheetState(() {
                              controller.text = text;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Ô nhập phản hồi
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      minLines: 3,
                      maxLength: 1000,
                      decoration: InputDecoration(
                        hintText:
                            'Nhập nội dung phản hồi nhận xét của khách hàng...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nút gửi phản hồi
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: reviewProvider.isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          reviewProvider.isSubmitting
                              ? 'Đang gửi...'
                              : (isEditing
                                  ? 'Cập nhật phản hồi'
                                  : 'Gửi phản hồi'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: reviewProvider.isSubmitting
                            ? null
                            : () async {
                                final text = controller.text.trim();
                                if (text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Vui lòng nhập nội dung phản hồi',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final success =
                                    await reviewProvider.replyReview(
                                  token: token,
                                  reviewId: review.id,
                                  comment: text,
                                );

                                if (context.mounted &&
                                    bottomSheetContext.mounted) {
                                  if (success) {
                                    Navigator.pop(bottomSheetContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.green.shade700,
                                        content: Text(
                                          reviewProvider.successMessage ??
                                              'Phản hồi đánh giá thành công!',
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.red.shade700,
                                        content: Text(
                                          reviewProvider.errorMessage ??
                                              'Không thể gửi phản hồi',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Xác nhận xóa phản hồi (UC-RAT-02)
  Future<void> _confirmDeleteReply(
    BuildContext context,
    ReviewModel review,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Xác nhận xóa phản hồi'),
          content: const Text(
            'Bạn có chắc chắn muốn xóa phản hồi này không? Khách hàng sẽ không còn thấy câu trả lời của bạn.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null || token.isEmpty) return;

      final success = await context.read<ReviewProvider>().deleteReviewReply(
            token: token,
            reviewId: review.id,
          );

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Đã xóa phản hồi thành công'),
            ),
          );
        } else {
          final error =
              context.read<ReviewProvider>().errorMessage ?? 'Lỗi xóa phản hồi';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(error),
            ),
          );
        }
      }
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 54, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text(
            'Chưa có đánh giá nào cho thợ này',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hãy là người đầu tiên trải nghiệm và để lại đánh giá!',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }
}
