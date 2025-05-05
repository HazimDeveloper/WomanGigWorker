import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../config/constants.dart';

class SafetyRating extends StatelessWidget {
  final double rating;
  final bool allowUpdate;
  final Function(double)? onRatingUpdate;
  final double itemSize;
  final Color? activeColor;
  final Color? inactiveColor;

  const SafetyRating({
    Key? key,
    required this.rating,
    this.allowUpdate = false,
    this.onRatingUpdate,
    this.itemSize = 24.0,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: rating,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: itemSize,
      ignoreGestures: !allowUpdate,
      itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
      itemBuilder: (context, _) => Icon(
        Icons.star,
        color: activeColor ?? Colors.amber,
      ),
      unratedColor: inactiveColor ?? Colors.grey.shade300,
      onRatingUpdate: onRatingUpdate ?? (rating) {},
    );
  }
}

class SafetyLabel extends StatelessWidget {
  final String safetyLevel;
  final double fontSize;

  const SafetyLabel({
    Key? key,
    required this.safetyLevel,
    this.fontSize = 14.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (safetyLevel) {
      case AppConstants.safeLevelSafe:
        color = AppColors.safeGreen;
        label = 'Safe';
        break;
      case AppConstants.safeLevelModerate:
        color = AppColors.moderateYellow;
        label = 'Moderate';
        break;
      case AppConstants.safeLevelHighRisk:
        color = AppColors.highRiskRed;
        label = 'High Risk';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}