import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class WaterTrackerWidget extends StatefulWidget {
  final Function? onAddWater;
  
  const WaterTrackerWidget({Key? key, this.onAddWater}) : super(key: key);

  @override
  _WaterTrackerWidgetState createState() => _WaterTrackerWidgetState();
}

class _WaterTrackerWidgetState extends State<WaterTrackerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _totalWaterAmount = 0.0; // Total water in ml
  final double _glassSize = 250.0; // Size of a water glass in ml
  final double _dailyTarget = 3000.0; // Daily target in ml
  bool _isLoading = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _fetchWaterIntake();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Fetch water intake data from API
  Future<void> _fetchWaterIntake() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final apiService = ApiService();
      final waterIntakeList = await apiService.getWaterIntake();
      
      // Calculate total water amount from all entries for today
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      double totalToday = 0.0;
      for (final intake in waterIntakeList) {
        // Parse timestamp string to DateTime
        final timestamp = DateTime.parse(intake['timestamp'] as String);
        final intakeDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
        
        // Check if the intake is from today
        if (intakeDate.isAtSameMomentAs(today)) {
          // Handle both int and double types safely
          final amount = intake['amount'];
          if (amount is int) {
            totalToday += amount.toDouble();
          } else if (amount is double) {
            totalToday += amount;
          } else {
            // Try to parse as double if it's a string
            totalToday += double.tryParse(amount.toString()) ?? 0.0;
          }
        }
      }
      
      setState(() {
        _totalWaterAmount = totalToday;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching water intake: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add water via API
  Future<void> _addWater() async {
    if (_isAdding) return;
    
    setState(() {
      _isAdding = true;
    });
    
    try {
      final apiService = ApiService();
      await apiService.addWaterIntake(_glassSize);
      
      setState(() {
        _totalWaterAmount += _glassSize;
        _isAdding = false;
      });
      
      _animationController.reset();
      _animationController.forward();
      
      if (widget.onAddWater != null) {
        widget.onAddWater!();
      }
    } catch (e) {
      print('Error adding water intake: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error adding water: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() {
        _isAdding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure all values are doubles
    final double totalWaterAmount = _totalWaterAmount;
    final double dailyTarget = _dailyTarget;
    final double glassSize = _glassSize;
    
    // Calculate percentage, ensuring it's within 0.0-1.0 range
    final double fillPercentage = (totalWaterAmount / dailyTarget).clamp(0.0, 1.0);
    
    // Calculate glass count
    final int glasses = (totalWaterAmount / glassSize).round();
    final int targetGlasses = (dailyTarget / glassSize).round();
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.blue.withOpacity(0.2),
          ],
        ),
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 2,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Water Intake',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _isAdding
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.blue,
                              strokeWidth: 2,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.blue),
                            onPressed: _addWater,
                          ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: MediaQuery.of(context).size.width * fillPercentage * 0.7,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade300, Colors.blue.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Center(
                        child: Text(
                          '$glasses / $targetGlasses glasses',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${totalWaterAmount.toStringAsFixed(0)} ml of ${dailyTarget.toStringAsFixed(0)} ml',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
    );
  }
} 