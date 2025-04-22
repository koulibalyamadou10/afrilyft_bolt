import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ReserveButton extends StatelessWidget {
  const ReserveButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.access_time, color: AppColors.white),
          SizedBox(width: 8),
          Text(
            'Reserve for Later',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 