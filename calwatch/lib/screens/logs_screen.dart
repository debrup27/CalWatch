import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'home_screen.dart';
import 'nutritionist_screen.dart';
import 'profile_screen.dart';
import 'dart:ui';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({Key? key}) : super(key: key);

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  int _selectedIndex = 2; // Logs tab selected by default
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;
  
  // Map to store fetched logs by date
  Map<DateTime, List<Map<String, dynamic>>> _logEvents = {};
  
  // Combined map for both food and water logs
  Map<DateTime, List<Map<String, dynamic>>> _combinedLogs = {};
  
  // ApiService instance
  late ApiService _apiService;
  
  // Format dates
  final _dateFormat = DateFormat('h:mm a');

  void _handleNavigation(int index) {
    if (index == _selectedIndex) return;
    
    setState(() {
      _selectedIndex = index;
    });
    
    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1: // Nutritionist (formerly Foods)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NutritionistScreen()),
        );
        break;
      case 2: // Logs
        // Already on Logs screen
        break;
      case 3: // Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  // Get start and end dates based on current calendar view
  Map<String, DateTime> _getDateRange() {
    DateTime start, end;
    
    switch (_calendarFormat) {
      case CalendarFormat.month:
        // For month view, get first and last day of the month
        final DateTime firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
        final DateTime lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
        start = firstDayOfMonth;
        end = lastDayOfMonth;
        break;
        
      case CalendarFormat.twoWeeks:
        // For two weeks view, get 7 days before and 7 days after focused day
        start = _focusedDay.subtract(const Duration(days: 7));
        end = _focusedDay.add(const Duration(days: 7));
        break;
        
      case CalendarFormat.week:
      default:
        // For week view, get start and end of the week
        int difference = _focusedDay.weekday - 1; // 0 for Monday, 6 for Sunday
        start = _focusedDay.subtract(Duration(days: difference));
        end = start.add(const Duration(days: 6));
        break;
    }
    
    return {'start': start, 'end': end};
  }
  
  // Fetch logs for the current view
  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final dateRange = _getDateRange();
      final startDate = dateRange['start']!;
      final endDate = dateRange['end']!;
      
      print('Fetching logs from $startDate to $endDate');
      
      // Fetch food logs
      final foodLogs = await _apiService.getFoodLogs(startDate, endDate);
      
      // Fetch water logs (optional - if you want to include this as well)
      final waterLogs = await _apiService.getWaterIntake();
      
      // Reset the combined logs map
      final newCombinedLogs = <DateTime, List<Map<String, dynamic>>>{};
      
      // Process food logs
      for (final log in foodLogs) {
        final timestamp = DateTime.parse(log['timestamp'] as String);
        final day = DateTime(timestamp.year, timestamp.month, timestamp.day);
        
        if (!newCombinedLogs.containsKey(day)) {
          newCombinedLogs[day] = [];
        }
        
        // Add formatted time to the log
        log['formatted_time'] = _dateFormat.format(timestamp);
        log['type'] = 'food';
        
        newCombinedLogs[day]!.add(log);
      }
      
      // Process water logs - only those in our date range
      for (final log in waterLogs) {
        final timestamp = DateTime.parse(log['timestamp'] as String);
        final day = DateTime(timestamp.year, timestamp.month, timestamp.day);
        
        // Check if within date range
        if (day.compareTo(startDate) >= 0 && day.compareTo(endDate) <= 0) {
          if (!newCombinedLogs.containsKey(day)) {
            newCombinedLogs[day] = [];
          }
          
          // Add formatted time to the log
          log['formatted_time'] = _dateFormat.format(timestamp);
          log['type'] = 'water';
          
          newCombinedLogs[day]!.add(log);
        }
      }
      
      // Sort logs by timestamp for each day
      for (final day in newCombinedLogs.keys) {
        newCombinedLogs[day]!.sort((a, b) {
          final aTime = DateTime.parse(a['timestamp'] as String);
          final bTime = DateTime.parse(b['timestamp'] as String);
          return bTime.compareTo(aTime); // Descending order (newest first)
        });
      }
      
      setState(() {
        _combinedLogs = newCombinedLogs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching logs: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to fetch logs: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    // Normalize the day to remove time component
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _combinedLogs[normalizedDay] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _selectedDay = _focusedDay;
    
    // Fetch logs after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Nutrition Logs',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendar(),
          const SizedBox(height: 20),
          _isLoading 
              ? const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.green,
                    ),
                  ),
                )
              : _buildLogsList(),
        ],
      ),
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

  Widget _buildCalendar() {
    return Card(
      color: Colors.grey[900],
      elevation: 4,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.withOpacity(0.2),
                  Colors.grey.shade900.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                  
                  // Fetch logs with new date range
                  _fetchLogs();
                }
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
                
                // Fetch logs with new date range
                _fetchLogs();
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.orangeAccent,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: const TextStyle(color: Colors.red),
                outsideTextStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                defaultTextStyle: const TextStyle(color: Colors.white),
              ),
              headerStyle: HeaderStyle(
                formatButtonDecoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                formatButtonTextStyle: const TextStyle(color: Colors.white),
                titleTextStyle: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.poppins(color: Colors.white),
                weekendStyle: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogsList() {
    final events = _getEventsForDay(_selectedDay!);
    
    if (events.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'No logs for this day',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
    
    return Expanded(
      child: ListView.builder(
        itemCount: events.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final event = events[index];
          final isFood = event['type'] == 'food';
          final isWater = event['type'] == 'water';
          
          return Card(
            color: Colors.grey[850],
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(
                isFood 
                    ? (event['food_name'] ?? 'Unknown Food')
                    : 'Water Intake',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                isFood
                    ? 'Calories: ${event['calories']?.toStringAsFixed(1) ?? 'N/A'} • ${event['formatted_time']}'
                    : 'Amount: ${event['amount']?.toStringAsFixed(0) ?? 'N/A'} ml • ${event['formatted_time']}',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                ),
              ),
              leading: CircleAvatar(
                backgroundColor: isFood ? Colors.orange : Colors.blue,
                child: Icon(
                  isFood ? Icons.restaurant : Icons.water_drop,
                  color: Colors.white,
                ),
              ),
              trailing: isFood ? PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Details',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                color: Colors.grey[900],
                onSelected: (value) {
                  if (value == 'details') {
                    _showFoodDetails(event);
                  }
                },
              ) : null,
            ),
          );
        },
      ),
    );
  }
  
  void _showFoodDetails(Map<String, dynamic> food) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                food['food_name'] ?? 'Unknown Food',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Consumed on ${food['formatted_time']}',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              const SizedBox(height: 16),
              _buildNutrientRow('Calories', '${food['calories']?.toStringAsFixed(1) ?? 'N/A'} kcal', Colors.orange),
              const SizedBox(height: 12),
              _buildNutrientRow('Protein', '${food['protein']?.toStringAsFixed(1) ?? 'N/A'} g', Colors.red),
              const SizedBox(height: 12),
              _buildNutrientRow('Carbs', '${food['carbohydrates']?.toStringAsFixed(1) ?? 'N/A'} g', Colors.blue),
              const SizedBox(height: 12),
              _buildNutrientRow('Fat', '${food['fat']?.toStringAsFixed(1) ?? 'N/A'} g', Colors.yellow),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildNutrientRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[300],
            fontSize: 16,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 