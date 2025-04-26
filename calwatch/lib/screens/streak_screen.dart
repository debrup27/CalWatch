import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../services/streak_service.dart';
import 'package:intl/intl.dart';
import '../services/groq_service.dart';
import '../widgets/stellar_token_info.dart';

class StreakScreen extends StatefulWidget {
  final int streakCount;
  final bool isOnStreak;

  const StreakScreen({
    Key? key, 
    required this.streakCount,
    required this.isOnStreak,
  }) : super(key: key);

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final StreakService _streakService = StreakService();
  final GroqService _groqService = GroqService();
  List<Map<String, dynamic>> _streakHistory = [];
  bool _isLoading = true;
  String _motivationalQuote = "";
  bool _isLoadingQuote = true;
  bool _isPenaltyActive = false;
  DateTime? _missedDate;
  
  // Colors for the flame and background effects
  final List<Color> _nebulaColors = [
    Colors.red.withOpacity(0.6),
    Colors.orange.withOpacity(0.5),
    Colors.amber.withOpacity(0.4),
    Colors.yellow.withOpacity(0.3),
  ];
  
  // Streak achievement messages
  final Map<int, String> _streakAchievements = {
    3: "🔥 3-Day Streak! You're getting started!",
    7: "🔥🔥 1-Week Streak! Keep it up!",
    14: "🔥🔥🔥 2-Week Streak! You're on fire!",
    21: "🔥🔥🔥🔥 3-Week Streak! Incredible commitment!",
    30: "🔥🔥🔥🔥🔥 30-Day Streak! You're a nutrition champion!",
    60: "🌟 60-Day Streak! Legendary consistency!",
    90: "🏆 90-Day Streak! Nutrition master!",
    180: "👑 180-Day Streak! You're in the elite league!",
    365: "🌈 365-Day Streak! A full year of perfect nutrition!"
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _loadStreakHistory();
    _loadMotivationalQuote();
    _checkPenaltyStatus();
  }
  
  // Check if penalty is active
  Future<void> _checkPenaltyStatus() async {
    final isPenalty = await _streakService.isPenaltyActive();
    final missedDate = await _streakService.getMissedDate();
    
    setState(() {
      _isPenaltyActive = isPenalty;
      _missedDate = missedDate;
    });
  }

  // Load the user's streak history
  Future<void> _loadStreakHistory() async {
    try {
      final history = await _streakService.getStreakHistory();
      setState(() {
        _streakHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading streak history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMotivationalQuote() async {
    if (widget.streakCount == 0) {
      setState(() {
        _motivationalQuote = "Every nutritional journey begins with a single healthy choice. Start your streak today!";
        _isLoadingQuote = false;
      });
      return;
    }
    
    try {
      final quote = await _groqService.getStreakMotivationalQuote(widget.streakCount);
      setState(() {
        _motivationalQuote = quote;
        _isLoadingQuote = false;
      });
    } catch (e) {
      print('Error loading motivational quote: $e');
      // Fallback quotes based on streak length if API fails
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  // Get achievement message for current streak
  String? _getAchievementMessage() {
    // Find the highest achievement level that's less than or equal to current streak
    final eligible = _streakAchievements.keys
        .where((days) => days <= widget.streakCount)
        .toList();
    
    if (eligible.isEmpty) return null;
    
    // Get the highest eligible achievement
    final highestAchievement = eligible.reduce(math.max);
    return _streakAchievements[highestAchievement];
  }
  
  // Get color based on streak count
  Color _getStreakColor() {
    if (widget.streakCount >= 30) return Colors.purpleAccent;
    if (widget.streakCount >= 14) return Colors.orangeAccent;
    if (widget.streakCount >= 7) return Colors.amberAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final streakColor = _getStreakColor();
    final achievementMessage = _getAchievementMessage();
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Your Streak',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Main Streak Display
                    Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Animated nebula
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          for (var i = 0; i < _nebulaColors.length; i++)
                            BoxShadow(
                                            color: widget.isOnStreak 
                                                ? _nebulaColors[i] 
                                                : Colors.grey.withOpacity(0.3),
                              blurRadius: 30 + 20 * math.sin(_controller.value * 2 * math.pi + i),
                              spreadRadius: 5 + 3 * math.cos(_controller.value * 2 * math.pi + i),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                // Fire icon
                Icon(
                  Icons.local_fire_department,
                  size: 100,
                                color: widget.isOnStreak 
                                    ? streakColor 
                                    : Colors.grey,
                ),
              ],
            ),
                          const SizedBox(height: 20),
            // Streak count display
            Text(
              '${widget.streakCount}',
              style: GoogleFonts.montserrat(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                              color: widget.isOnStreak 
                                  ? Colors.white
                                  : Colors.grey[400],
              ),
            ),
                          const SizedBox(height: 10),
            Text(
              'day streak',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                color: Colors.grey[400],
              ),
            ),
                          
                          // Penalty notice
                          if (_isPenaltyActive) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Penalty Day Active',
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _missedDate != null
                                        ? 'You missed your goal on ${DateFormat('MMMM d').format(_missedDate!)}. '
                                            'Meet your goal today to remove the penalty and resume your streak tomorrow.'
                                        : 'Meet your goal today to remove the penalty and resume your streak tomorrow.',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          if (achievementMessage != null) ...[
                            const SizedBox(height: 20),
            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: streakColor.withOpacity(0.5),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: streakColor.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
              child: Text(
                                achievementMessage,
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Streak Token Information
                    const StellarTokenInfo(),
                    
                    // Streak token refresh button
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            try {
                              await _streakService.debugRepairDistributorAccount();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Streak token refresh initiated'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.refresh, size: 16, color: Colors.white70),
                          label: Text(
                            'Click to refresh if streak token not updated',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Motivational Quote Section
                    Container(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.chat,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'PADMA says:',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _isLoadingQuote
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  _motivationalQuote,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                    color: Colors.white,
                                  ),
                                ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Streak Information Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Streak Explained',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.fact_check_outlined,
                            'Daily Goals',
                            'Meet your calorie, protein, carbs and fat goals each day to maintain your streak.',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.warning_amber_rounded,
                            'Missed Goals',
                            'If you miss your goals, your streak resets and you\'ll have a one-day penalty period.',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.emoji_events_outlined,
                            'Achievements',
                            'Unlock achievements at 3, 7, 14, 21, 30, 60, 90, 180, and 365 days.',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.insights_outlined,
                            'Consistency',
                            'Your streak is a measure of your consistency with maintaining nutritional balance.',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.calendar_today_outlined,
                            'History',
                            'View your streak history below to track your progress over time.',
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Streak History
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent History',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _streakHistory.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    'No streak history yet',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                            : _buildStreakCalendar(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.grey[400],
              ),
            ),
          ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStreakCalendar() {
    // Sort history by date
    _streakHistory.sort((a, b) {
      final dateA = DateTime.parse(a['date'] as String);
      final dateB = DateTime.parse(b['date'] as String);
      return dateB.compareTo(dateA); // Newest first
    });
    
    // Limit to 14 days for display
    final displayHistory = _streakHistory.take(14).toList();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          for (var entry in displayHistory)
            _buildHistoryEntry(entry),
        ],
      ),
    );
  }
  
  Widget _buildHistoryEntry(Map<String, dynamic> entry) {
    final date = DateTime.parse(entry['date'] as String);
    final streakCount = entry['streak'] as int;
    final dateFormat = DateFormat('MMMM d, yyyy');
    
    // Determine color based on streak count
    Color dotColor;
    if (streakCount == 0) {
      dotColor = Colors.redAccent;
    } else if (streakCount >= 30) {
      dotColor = Colors.purpleAccent;
    } else if (streakCount >= 14) {
      dotColor = Colors.orangeAccent;
    } else if (streakCount >= 7) {
      dotColor = Colors.amberAccent;
    } else {
      dotColor = Colors.greenAccent;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              dateFormat.format(date),
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            streakCount > 0
                ? '$streakCount day${streakCount > 1 ? "s" : ""}'
                : 'Missed goal',
            style: GoogleFonts.montserrat(
              color: streakCount > 0 ? Colors.white : Colors.red[300],
              fontSize: 14,
              fontWeight: streakCount > 0 ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
} 