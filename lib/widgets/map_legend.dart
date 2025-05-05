import 'package:flutter/material.dart';
import 'package:trust_me/config/constants.dart';

class MapLegend extends StatelessWidget {
  const MapLegend({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SAFETY LEVELS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _buildLegendItem(AppColors.safeGreen, 'Safe'),
          const SizedBox(height: 8),
          _buildLegendItem(AppColors.moderateYellow, 'Moderate'),
          const SizedBox(height: 8),
          _buildLegendItem(AppColors.highRiskRed, 'High Risk'),
          const SizedBox(height: 4),
          Container(
            height: 1,
            color: Colors.grey.withOpacity(0.3),
            margin: const EdgeInsets.symmetric(vertical: 4),
          ),
          _buildSpecialItem(
            Colors.purple,
            'Selected Location',
            Icons.location_pin,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color, width: 1.5),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSpecialItem(Color color, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}