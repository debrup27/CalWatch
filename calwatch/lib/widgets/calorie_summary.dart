import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class CalorieSummary extends StatelessWidget {
  final int consumed;
  final int goal;

  const CalorieSummary({
    Key? key,
    required this.consumed,
    this.goal = 2000, // Default goal of 2000 calories
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (consumed / goal).clamp(0.0, 1.0);
    final remaining = goal - consumed;
    final isOverGoal = consumed > goal;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TODAY\'S PROGRESS',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                isOverGoal ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                color: isOverGoal ? Colors.black : Colors.black,
                size: 20,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Main stats display
          Row(
            children: [
              _buildCalorieDisplay(
                value: consumed,
                label: 'CONSUMED',
                textColor: Colors.black,
                fontSize: 32,
              ),
              Expanded(
                child: Container(
                  height: 60,
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                      Container(
                        height: 24,
                        width: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.black,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          isOverGoal ? Icons.remove : Icons.remove,
                          color: Colors.black,
                          size: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildCalorieDisplay(
                value: remaining,
                label: 'REMAINING',
                textColor: isOverGoal ? Colors.red : Colors.black.withOpacity(0.7),
                fontSize: 22,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(percentage * 100).toInt()}% of daily goal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'GOAL: $goal',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  // Background
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // Progress
                  Container(
                    height: 6,
                    width: MediaQuery.of(context).size.width * percentage * 0.85, // Adjust for padding
                    decoration: BoxDecoration(
                      color: isOverGoal ? Colors.red : Colors.black,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieDisplay({
    required int value,
    required String label,
    required Color textColor,
    required double fontSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.black.withOpacity(0.6),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
} 