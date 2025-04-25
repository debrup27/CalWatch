import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../widgets/water_tracker_widget.dart';
import 'logs_screen.dart';
import 'profile_screen.dart';
import 'add_food_screen.dart';
import 'nutritionist_screen.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final String? username;
  
  const HomeScreen({Key? key, this.username}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0; // Diary selected by default
  late AnimationController _controller;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  
  // API service
  late ApiService _apiService;
  
  // Nutrition data
  Map<String, dynamic> _nutritionData = {
    'calories': {
      'consumed': 0.0,
      'goal': 0.0,
    },
    'protein': {
      'consumed': 0.0,
      'goal': 0.0,
    },
    'carbohydrates': {
      'consumed': 0.0,
      'goal': 0.0,
    },
    'fat': {
      'consumed': 0.0,
      'goal': 0.0,
    },
  };

  // Food entries for the day
  List<Map<String, dynamic>> _foodEntries = [];
  
  // Date format
  final _timeFormat = DateFormat('h:mm a');

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Fetch data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDailyData();
    });
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  // Fetch daily data - both goals and consumption
  Future<void> _fetchDailyData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get today's date in YYYY-MM-DD format
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      // Fetch daily goals
      final dailyGoals = await _apiService.getDailyGoals();
      
      // Fetch today's food logs
      final foodLogs = await _apiService.getFoodLogs(today, tomorrow);
      
      // Calculate consumed nutrition values
      double caloriesConsumed = 0.0;
      double proteinConsumed = 0.0;
      double carbsConsumed = 0.0;
      double fatConsumed = 0.0;
      
      // Process food logs
      final todayFoodEntries = <Map<String, dynamic>>[];
      
      for (final log in foodLogs) {
        final timestamp = DateTime.parse(log['timestamp'] as String);
        final logDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
        
        // Only include logs from today
        if (logDate.isAtSameMomentAs(today)) {
          // Add formatted time to the log
          log['formatted_time'] = _timeFormat.format(timestamp);
          
          // Add to food entries for display
          todayFoodEntries.add(log);
          
          // Sum up nutrients
          caloriesConsumed += (log['calories'] as num?)?.toDouble() ?? 0.0;
          proteinConsumed += (log['protein'] as num?)?.toDouble() ?? 0.0;
          carbsConsumed += (log['carbohydrates'] as num?)?.toDouble() ?? 0.0;
          fatConsumed += (log['fat'] as num?)?.toDouble() ?? 0.0;
        }
      }
      
      // Sort food entries by timestamp (newest first)
      todayFoodEntries.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return bTime.compareTo(aTime);
      });
      
      setState(() {
        // Update nutrition data
        _nutritionData = {
          'calories': {
            'consumed': caloriesConsumed,
            'goal': dailyGoals['calories']?.toDouble() ?? 2000.0,
          },
          'protein': {
            'consumed': proteinConsumed,
            'goal': dailyGoals['protein']?.toDouble() ?? 50.0,
          },
          'carbohydrates': {
            'consumed': carbsConsumed,
            'goal': dailyGoals['carbohydrates']?.toDouble() ?? 250.0,
          },
          'fat': {
            'consumed': fatConsumed,
            'goal': dailyGoals['fat']?.toDouble() ?? 70.0,
          },
        };
        
        // Update food entries
        _foodEntries = todayFoodEntries;
        
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching daily data: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to fetch daily data: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _handleNavigation(int index) {
    if (index == _selectedIndex) return;
    
    setState(() {
      _selectedIndex = index;
    });
    
    switch (index) {
      case 0: // Home
        // Already on home screen
        break;
      case 1: // Nutritionist (formerly Foods)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NutritionistScreen()),
        );
        break;
      case 2: // Logs
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LogsScreen()),
        );
        break;
      case 3: // Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _fetchDailyData();
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _fetchDailyData();
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: _previousDay,
            ),
            Text(
              _formatDate(_selectedDate),
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: _nextDay,
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 1,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchDailyData,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nutrient circles
                    _buildNutrientCircles(),
                    
                    const SizedBox(height: 24),
                    
                    // Water consumption using our new widget
                    WaterTrackerWidget(
                      onAddWater: () {
                        // Optional callback when water is added - could be used for showing a toast
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Water intake recorded!',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.blue,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Food entries
                    _buildFoodEntries(),
                    
                    // Add padding at bottom for navigation bar
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddFoodScreen()),
          ).then((_) => _fetchDailyData()); // Refresh data when returning
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Food',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Nutritionist',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Logs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          onTap: _handleNavigation,
        ),
      ),
    );
  }

  Widget _buildNutrientCircles() {
    // Get nutrient data
    final caloriesConsumed = _nutritionData['calories']['consumed'] as double;
    final caloriesGoal = _nutritionData['calories']['goal'] as double;
    final proteinConsumed = _nutritionData['protein']['consumed'] as double;
    final proteinGoal = _nutritionData['protein']['goal'] as double;
    final carbsConsumed = _nutritionData['carbohydrates']['consumed'] as double;
    final carbsGoal = _nutritionData['carbohydrates']['goal'] as double;
    final fatConsumed = _nutritionData['fat']['consumed'] as double;
    final fatGoal = _nutritionData['fat']['goal'] as double;
    
    // Calculate percentages
    final caloriesPercent = (caloriesConsumed / caloriesGoal).clamp(0.0, 1.0);
    final proteinPercent = (proteinConsumed / proteinGoal).clamp(0.0, 1.0);
    final carbsPercent = (carbsConsumed / carbsGoal).clamp(0.0, 1.0);
    final fatPercent = (fatConsumed / fatGoal).clamp(0.0, 1.0);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
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
            Colors.black.withOpacity(0.5),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrition Tracker',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNutrientCircle(
                'Calories',
                caloriesConsumed.toInt(),
                caloriesGoal.toInt(),
                caloriesPercent,
                Colors.blue,
                'kcal',
              ),
              _buildNutrientCircle(
                'Protein',
                proteinConsumed.toInt(),
                proteinGoal.toInt(),
                proteinPercent,
                Colors.red,
                'g',
              ),
              _buildNutrientCircle(
                'Carbs',
                carbsConsumed.toInt(),
                carbsGoal.toInt(),
                carbsPercent,
                Colors.green,
                'g',
              ),
              _buildNutrientCircle(
                'Fat',
                fatConsumed.toInt(),
                fatGoal.toInt(),
                fatPercent,
                Colors.yellow,
                'g',
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildNutrientCircle(String label, int consumed, int goal, double percent, Color color, String unit) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CircularPercentIndicator(
              radius: 35.0,
              lineWidth: 6.0,
              animation: false,
              percent: percent * _controller.value,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$consumed',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    unit,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              footer: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Goal: $goal',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: color,
              backgroundColor: Colors.grey[800] ?? Colors.grey.shade800,
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildFoodEntries() {
    List<Widget> widgets = [];
    
    widgets.add(
      Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.1),
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
              Colors.black.withOpacity(0.5),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Food",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Calories",
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFoodEntriesContent(),
          ],
        ),
      ),
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
  
  Widget _buildFoodEntriesContent() {
    if (_foodEntries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "No food entries yet. Tap + to add food.",
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ),
      );
    }
    
    // Group foods by meal type if possible
    final Map<String, List<Map<String, dynamic>>> mealGroups = {};
    
    for (final entry in _foodEntries) {
      final mealType = entry['meal_type'] ?? 'Other';
      if (!mealGroups.containsKey(mealType)) {
        mealGroups[mealType] = [];
      }
      mealGroups[mealType]!.add(entry);
    }
    
    if (mealGroups.isEmpty) {
      // No meal type grouping, just show the list
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _foodEntries.map((entry) => _buildFoodEntryItem(entry)).toList(),
      );
    }
    
    // Build entries grouped by meal type
    final List<Widget> groupedEntries = [];
    
    mealGroups.forEach((mealType, entries) {
      groupedEntries.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
          child: Text(
            mealType,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
      
      for (final entry in entries) {
        groupedEntries.add(_buildFoodEntryItem(entry));
      }
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedEntries,
    );
  }
  
  Widget _buildFoodEntryItem(Map<String, dynamic> entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.circle,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['food_name'] ?? 'Unknown Food',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry['formatted_time'] ?? '',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(entry['calories'] as num?)?.toStringAsFixed(1) ?? 'N/A'} kcal',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}