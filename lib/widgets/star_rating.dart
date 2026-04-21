// lib/widgets/star_rating.dart
// Star Rating Widget for Event Feedback

import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showValue;
  final ValueChanged<int>? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
    this.showValue = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = activeColor ?? Colors.amber;
    final inactive = inactiveColor ?? (isDark ? Colors.grey[700]! : Colors.grey[300]!);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(maxRating, (index) {
          final starValue = index + 1;
          final isFilled = starValue <= rating;
          final isHalfFilled = starValue > rating && starValue - 0.5 <= rating;

          return GestureDetector(
            onTap: onRatingChanged != null ? () => onRatingChanged!(starValue) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                isHalfFilled ? Icons.star_half : (isFilled ? Icons.star : Icons.star_border),
                color: isFilled || isHalfFilled ? active : inactive,
                size: size,
              ),
            ),
          );
        }),
        if (showValue) ...[
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.7,
              fontWeight: FontWeight.bold,
              color: isDark ? DarkColors.textPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

// Interactive Star Rating for submitting feedback
class InteractiveStarRating extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int> onRatingChanged;
  final double size;

  const InteractiveStarRating({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 40,
  });

  @override
  State<InteractiveStarRating> createState() => _InteractiveStarRatingState();
}

class _InteractiveStarRatingState extends State<InteractiveStarRating> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = starValue <= _rating;

        return GestureDetector(
          onTap: () {
            setState(() => _rating = starValue);
            widget.onRatingChanged(starValue);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isFilled ? Icons.star : Icons.star_border,
              color: isFilled ? Colors.amber : Colors.grey[400],
              size: isFilled ? widget.size * 1.1 : widget.size,
            ),
          ),
        );
      }),
    );
  }
}
