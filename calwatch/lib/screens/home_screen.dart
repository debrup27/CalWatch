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
import 'streak_screen.dart';
import '../services/streak_service.dart';
import '../services/groq_service.dart';
import 'dart:async'; // Add StreamController import

class HomeScreen extends StatefulWidget {
  final String? username;
  
  const HomeScreen({Key? key, this.username}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0; // Diary selected by default
  late AnimationController _controller;
  late DateTime _selectedDate;
  bool _isLoading = true;
  
  // Streak variables
  int _streakCount = 0;
  bool _isOnStreak = false;
  
  // API service
  late ApiService _apiService;
  
  // Water intake value
  double _waterIntake = 0.0;
  
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

  // Add streak service
  late StreakService _streakService;

  // Add GroqService
  late GroqService _groqService;

  // For motivational quote
  String _motivationalQuote = "";
  bool _isLoadingQuote = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isPenaltyActive = false;
  
  // Add water controller
  late StreamController<void> _fetchWaterController;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now(); // Initialize _selectedDate
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      value: 1.0,
    );
    _groqService = GroqService();
    _streakService = StreakService();
    _apiService = ApiService();
    _fetchWaterController = StreamController<void>.broadcast();
    
    // Add listener for water refreshes
    _fetchWaterController.stream.listen((_) {
      _fetchDailyData();
    });
    
    // Schedule data fetch after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDailyData();
      _checkPenaltyStatus();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _fetchDailyData() async {
    setState(() {
      _isLoading = true;
      _isLoadingQuote = true;
    });
    
    try {
      final data = await _apiService.getDailyData(_selectedDate);
      
      // Check if it's today's data and update streak if needed
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      
      // Previous streak count to check for milestones
      final previousStreakCount = _streakCount;
      
      // Only update streak for today's data
      if (selectedDay.isAtSameMomentAs(today)) {
        // Update streak based on nutrition data
        final streakResult = await _streakService.updateStreak(data['nutritionData']);
        
        // Update streak info from result
        _streakCount = streakResult['streakCount'];
        _isOnStreak = streakResult['isOnStreak'];
        
        // Show streak notification if streak changed
        if (streakResult['streakChanged'] && mounted) {
          final goalsMet = streakResult['goalsMet'];
          _showStreakNotification(goalsMet, _streakCount);
          
          // Check for streak milestones and show motivational quote
          if (goalsMet && _streakCount > previousStreakCount) {
            // Define milestone streak counts
            final milestones = [3, 7, 14, 21, 30, 60, 90, 180, 365];
            
            // Check if the current streak count is a milestone
            if (milestones.contains(_streakCount)) {
              _showStreakMilestoneMotivation(_streakCount);
            }
          }
        }
      } else {
        // For other days, just fetch the current streak info
        _streakCount = await _streakService.getStreakCount();
        _isOnStreak = await _streakService.isOnStreak();
      }
      
      // After updating streak, reload the motivational quote if streak count changed
      if (_streakCount != previousStreakCount) {
        _loadMotivationalQuote();
      }
      
      setState(() {
        _nutritionData = data['nutritionData'];
        _foodEntries = data['foodEntries'];
        _waterIntake = data['waterIntake'] as double;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching daily data: $e');
      setState(() {
        _isLoading = false;
        
        // Fallback streak data from service
        _streakService.getStreakCount().then((count) => _streakCount = count);
        _streakService.isOnStreak().then((status) => _isOnStreak = status); 
      });
      
      // Show error message if mounted and context is available
      if (mounted) {
        // Using Future.microtask to ensure we're not in build or layout phase
        Future.microtask(() {
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
        });
      }
    }
  }
  
  // Show streak notification
  void _showStreakNotification(bool goalsMet, int streakCount) {
    final String message = goalsMet 
        ? streakCount > 1 
            ? 'Streak extended to $streakCount days! 🔥'
            : 'New streak started! 🔥'
        : 'Streak reset. Try to meet your calorie goal tomorrow.';
    
    final Color backgroundColor = goalsMet ? Colors.green : Colors.orange;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  // Add a new method to show motivational quotes at streak milestones
  Future<void> _showStreakMilestoneMotivation(int streakCount) async {
    try {
      // Get a motivational quote from GROQ
      final quote = await _groqService.getStreakMotivationalQuote(streakCount);
      
      // Show a more prominent notification with the quote
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: Colors.amber.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Flame icon
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.amber,
                    size: 50,
                  ),
                  const SizedBox(height: 15),
                  // Milestone text
                  Text(
                    "$streakCount Day Streak Milestone!",
                    style: GoogleFonts.montserrat(
                      color: Colors.amber,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  // Motivational quote
                  Text(
                    quote,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Padma attribution
                  Text(
                    "~ PADMA",
                    style: GoogleFonts.montserrat(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 20),
                  // Close button
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Keep Going!",
                      style: GoogleFonts.montserrat(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error showing streak milestone motivation: $e');
      // Continue silently if there's an error - this is a non-critical feature
    }
  }
  
  // Add method to load motivational quote
  Future<void> _loadMotivationalQuote() async {
    if (_streakCount == 0) {
      setState(() {
        _motivationalQuote = "Every nutritional journey begins with a single healthy choice. Start your streak today!";
        _isLoadingQuote = false;
      });
      return;
    }
    
    try {
      final quote = await _groqService.getStreakMotivationalQuote(_streakCount);
      setState(() {
        _motivationalQuote = quote;
        _isLoadingQuote = false;
      });
    } catch (e) {
      print('Error loading motivational quote: $e');
      // Fallback quotes based on streak length
      final fallbackQuotes = [
        "Consistency is the key to lasting change. Keep going!",
        "Every day you maintain your streak is a victory for your health.",
        "Small daily improvements lead to remarkable results over time.",
        "Your dedication to nutrition is building a healthier future.",
        "The strength of your streak reflects the strength of your commitment."
      ];
      
      // Pick a random fallback quote
      final randomIndex = DateTime.now().millisecondsSinceEpoch % fallbackQuotes.length;
      setState(() {
        _motivationalQuote = fallbackQuotes[randomIndex];
        _isLoadingQuote = false;
      });
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
    // Get streak color based on streak count
    Color streakColor = Colors.redAccent;
    if (_streakCount >= 30) streakColor = Colors.purpleAccent;
    else if (_streakCount >= 14) streakColor = Colors.orangeAccent;
    else if (_streakCount >= 7) streakColor = Colors.amberAccent;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                      _fetchDailyData();
                    });
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null && picked != _selectedDate) {
                      setState(() {
                        _selectedDate = picked;
                        _fetchDailyData();
                      });
                    }
                  },
                  child: Row(
                    children: [
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final tomorrow = DateTime.now().add(const Duration(days: 1));
                    if (_selectedDate.day != tomorrow.day ||
                        _selectedDate.month != tomorrow.month ||
                        _selectedDate.year != tomorrow.year) {
                      setState(() {
                        _selectedDate = _selectedDate.add(const Duration(days: 1));
                        if (_selectedDate.isAfter(DateTime.now())) {
                          _selectedDate = DateTime.now();
                        }
                        _fetchDailyData();
                      });
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                // Streak button
                _buildStreakWidget(),
                const SizedBox(width: 8),
                // Refresh button
                IconButton(
                  onPressed: () {
                    setState(() {
                      _fetchDailyData();
                    });
                  },
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
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
                    
                    const SizedBox(height: 20),
                    
                    // Motivational Quote from PADMA
                    if (_isOnStreak && _streakCount > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: streakColor.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: streakColor.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      color: streakColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "PADMA says:",
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: streakColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      color: streakColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "$_streakCount day streak",
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _isLoadingQuote
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _motivationalQuote,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 15,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white,
                                      height: 1.4,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    
                    // Water consumption
                    WaterTrackerWidget(
                      date: _selectedDate,
                      waterAmount: _waterIntake,
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
                        // Refresh data after adding water
                        _fetchDailyData();
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
              label: 'Padma',
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

  Widget _buildStreakWidget() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StreakScreen(
              streakCount: _streakCount,
              isOnStreak: _streakCount > 0,
            ),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.local_fire_department,
            color: _getStreakColor(),
            size: 32,
          ),
          Positioned(
            bottom: 2,
            child: Text(
              '$_streakCount',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Show penalty dot if there's a penalty active
          if (_isPenaltyActive)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Check if there's an active penalty
  Future<void> _checkPenaltyStatus() async {
    try {
      // Get the penalty status from the streak service
      final penaltyStatus = await _streakService.getPenaltyStatus();
      setState(() {
        _isPenaltyActive = penaltyStatus['isPenaltyActive'];
      });
    } catch (e) {
      print('Error checking penalty status: $e');
      setState(() {
        _isPenaltyActive = false;
      });
    }
  }

  Color _getStreakColor() {
    if (_streakCount >= 30) return Colors.purpleAccent;
    else if (_streakCount >= 14) return Colors.orangeAccent;
    else if (_streakCount >= 7) return Colors.amberAccent;
    else return Colors.redAccent;
  }
}