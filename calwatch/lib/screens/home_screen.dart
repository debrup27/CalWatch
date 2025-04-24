import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../widgets/water_tracker_widget.dart';
import 'logs_screen.dart';
import 'profile_screen.dart';
import 'add_food_screen.dart';
import 'nutritionist_screen.dart';

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
  int _waterGlasses = 0;
  
  // Sample nutrition data
  final Map<String, dynamic> _nutritionData = {
    'caloriesConsumed': 1455,
    'caloriesBurned': 468,
    'calorieGoal': 1820,
  };

  // Sample food entries for the day
  final List<Map<String, dynamic>> _foodEntries = [
    {
      'name': 'Pork chops, loin, fresh, visible fat eaten',
      'time': '6:49 pm',
      'amount': '2 oz',
      'calories': 142.9,
      'mealType': 'Dinner',
    },
    {
      'name': 'Green Beans, Cooked from Fresh',
      'time': '6:49 pm',
      'amount': '1 cup, cut pieces',
      'calories': 43.7,
      'mealType': 'Dinner',
    },
    {
      'name': 'Butter, Salted',
      'time': '6:49 pm',
      'amount': '1 tbsp',
      'calories': 101.7,
      'mealType': 'Dinner',
    },
    {
      'name': 'Raspberries, Raw',
      'time': '8:00 pm',
      'amount': '0.5 cup, whole pieces',
      'calories': 32.0,
      'mealType': 'Snacks Evening',
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _addWaterGlass() {
    setState(() {
      _waterGlasses++;
    });
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calorie circles
              _buildCalorieCircles(),
              
              const SizedBox(height: 24),
              
              // Water consumption using our new widget
              WaterTrackerWidget(
                onAddWater: _addWaterGlass,
              ),
              
              const SizedBox(height: 24),
              
              // Food entries
              ..._buildFoodEntries(),
              
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
          );
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

  Widget _buildCalorieCircles() {
    final double caloriesConsumed = _nutritionData['caloriesConsumed'].toDouble();
    final double caloriesBurned = _nutritionData['caloriesBurned'].toDouble();
    final double calorieGoal = _nutritionData['calorieGoal'].toDouble();
    final double consumedPercent = (caloriesConsumed / calorieGoal).clamp(0.0, 1.0);
    final double burnedPercent = (caloriesBurned / calorieGoal).clamp(0.0, 1.0);
    final double remainingPercent = ((calorieGoal - caloriesConsumed) / calorieGoal).clamp(0.0, 1.0);
    
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
            'Calories',
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
              _buildCalorieCircle(
                'Consumed',
                caloriesConsumed.toInt(),
                consumedPercent,
              ),
              _buildCalorieCircle(
                'Burned',
                caloriesBurned.toInt(),
                burnedPercent,
              ),
              _buildCalorieCircle(
                'Remaining',
                (calorieGoal - caloriesConsumed).toInt(),
                remainingPercent,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCalorieCircle(String label, int value, double percent) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CircularPercentIndicator(
              radius: 40.0,
              lineWidth: 8.0,
              animation: false,
              percent: percent * _controller.value,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$value',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'kcal',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: _getColorForLabel(label),
              backgroundColor: Colors.grey[800] ?? Colors.grey.shade800,
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
  
  Color _getColorForLabel(String label) {
    switch (label) {
      case 'Consumed':
        return Colors.blue;
      case 'Burned':
        return Colors.green;
      case 'Remaining':
        return Colors.purple;
      default:
        return Colors.white;
    }
  }

  List<Widget> _buildFoodEntries() {
    List<Widget> widgets = [];
    String currentMealType = '';
    
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
    
    return widgets;
  }
  
  Widget _buildFoodEntriesContent() {
    List<Widget> widgets = [];
    String currentMealType = '';
    
    for (final entry in _foodEntries) {
      if (entry['mealType'] != currentMealType) {
        currentMealType = entry['mealType'] as String;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
            child: Text(
              currentMealType,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
      }
      
      widgets.add(_buildFoodEntryItem(entry));
    }
    
    if (widgets.isEmpty) {
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
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
                  entry['name'],
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry['time']} ${entry['amount']}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry['calories']} kcal',
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