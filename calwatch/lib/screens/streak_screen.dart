import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

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
  final List<Color> _nebulaColors = [
    Colors.red.withOpacity(0.6),
    Colors.orange.withOpacity(0.5),
    Colors.amber.withOpacity(0.4),
    Colors.yellow.withOpacity(0.3),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Nebula effect around fire
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
                              color: _nebulaColors[i],
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
                  color: widget.isOnStreak ? Colors.red : Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 40),
            // Streak count display
            Text(
              '${widget.streakCount}',
              style: GoogleFonts.montserrat(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'day streak',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 40),
            // Additional message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                widget.isOnStreak
                    ? 'Great job keeping your streak alive! Keep logging every day to maintain it.'
                    : 'Your streak has been reset. Start logging every day to build it back up!',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.grey[300],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 