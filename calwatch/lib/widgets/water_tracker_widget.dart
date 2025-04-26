import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class WaterTrackerWidget extends StatefulWidget {
  final Function? onAddWater;
  final DateTime date;
  final double? waterAmount; // Optional - if provided, will use this instead of fetching
  
  const WaterTrackerWidget({
    Key? key, 
    this.onAddWater, 
    required this.date,
    this.waterAmount,
  }) : super(key: key);

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
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    if (widget.waterAmount != null) {
      // Use the provided water amount
      _totalWaterAmount = widget.waterAmount!;
      _isLoading = false;
    } else {
      // Fetch water intake
      _fetchWaterIntake();
    }
  }

  @override
  void didUpdateWidget(WaterTrackerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If date changed or water amount was updated, refresh the data
    if (widget.date != oldWidget.date || widget.waterAmount != oldWidget.waterAmount) {
      if (widget.waterAmount != null) {
        setState(() {
          _totalWaterAmount = widget.waterAmount!;
          _isLoading = false;
        });
      } else if (widget.date != oldWidget.date) {
        _fetchWaterIntake();
      }
    }
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
      // Get water intake for the selected date
      final waterAmount = await _apiService.getWaterIntakeForDate(widget.date);
      
      setState(() {
        _totalWaterAmount = waterAmount;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching water intake: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Check if date is today
  bool get _isToday {
    final now = DateTime.now();
    return widget.date.year == now.year && 
           widget.date.month == now.month && 
           widget.date.day == now.day;
  }

  // Add water via API
  Future<void> _addWater() async {
    // Only allow adding water for today
    if (!_isToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can only add water for today',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_isAdding) return;
    
    setState(() {
      _isAdding = true;
    });
    
    try {
      await _apiService.addWaterIntake(_glassSize);
      
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
                            // Disable the button for past dates
                            color: _isToday ? Colors.blue : Colors.blue.withOpacity(0.4),
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