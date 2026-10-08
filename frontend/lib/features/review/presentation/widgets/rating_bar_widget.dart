import 'package:flutter/material.dart';

class InteractiveRatingBar extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onRatingChanged;
  final double itemSize;

  const InteractiveRatingBar({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.itemSize = 36.0,
  });

  String _getRatingText(double score) {
    if (score >= 5.0) return 'Tuyệt vời - Rất hài lòng';
    if (score >= 4.0) return 'Hài lòng - Dịch vụ tốt';
    if (score >= 3.0) return 'Bình thường';
    if (score >= 2.0) return 'Chưa hài lòng';
    return 'Rất tệ - Không hài lòng';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starValue = index + 1.0;
            final isFilled = rating >= starValue;

            return IconButton(
              iconSize: itemSize,
              splashRadius: itemSize * 0.7,
              icon: Icon(
                isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isFilled ? Colors.amber[700] : Colors.grey[400],
              ),
              onPressed: () => onRatingChanged(starValue),
            );
          }),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _getRatingText(rating),
            key: ValueKey<double>(rating),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: rating >= 4.0
                  ? Colors.green[700]
                  : (rating >= 3.0 ? Colors.orange[800] : Colors.red[700]),
            ),
          ),
        ),
      ],
    );
  }
}
