import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/review_model.dart';
import '../providers/review_provider.dart';
import 'create_review_screen.dart';

class TechnicianReviewsScreen extends StatefulWidget {
  final String technicianId;
  final String technicianName;

  const TechnicianReviewsScreen({
    super.key,
    required this.technicianId,
    required this.technicianName,
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Đánh giá: ${widget.technicianName}'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.rate_review_rounded),
            label: const Text('Viết đánh giá cho thợ'),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => CreateReviewScreen(
                    technicianId: widget.technicianId,
                    technicianName: widget.technicianName,
                  ),
                ),
              );
              if (result == true) {
                _loadReviews();
              }
            },
          ),
        ),
      ),
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
                          return _buildReviewCard(review);
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

  Widget _buildReviewCard(ReviewModel review) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final formattedDate = review.createdAt != null
        ? dateFormat.format(review.createdAt!)
        : '';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
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
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    review.customerName.isNotEmpty
                        ? review.customerName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.customerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
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
                padding: const EdgeInsets.all(10),
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
                        Text(
                          'Phản hồi từ thợ (${widget.technicianName})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.reply!.comment,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
