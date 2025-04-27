import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/groq_service.dart';
import '../services/api_service.dart';
import 'dart:math' as math;
import 'home_screen.dart';
import 'logs_screen.dart';
import 'profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

// Nebula effect painter
class NebulaPainter extends CustomPainter {
  final double animationValue;
  
  NebulaPainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Create random "gas clouds" in the nebula
    final random = math.Random(42); // Fixed seed for consistency
    
    for (int i = 0; i < 15; i++) {
      final xCenter = size.width * random.nextDouble();
      final yCenter = size.height * random.nextDouble();
      final radius = size.width * (0.1 + 0.15 * random.nextDouble());
      
      // Use animation value to shift the positions slightly
      final xOffset = 10 * math.sin(animationValue * 2 * math.pi + i);
      final yOffset = 10 * math.cos(animationValue * 2 * math.pi + i * 0.7);
      
      // Create a radial gradient for each cloud
      final gradient = RadialGradient(
        colors: [
          HSLColor.fromAHSL(
            0.3 + 0.1 * math.sin(animationValue * math.pi + i),
            (220 + 40 * random.nextDouble() + 20 * math.sin(animationValue * math.pi * 2)) % 360,
            0.8,
            0.5 + 0.1 * math.sin(animationValue * math.pi + i * 0.5),
          ).toColor(),
          Colors.transparent,
        ],
        stops: [0.0, 1.0],
      );
      
      paint.shader = gradient.createShader(
        Rect.fromCircle(
          center: Offset(xCenter + xOffset, yCenter + yOffset),
          radius: radius,
        ),
      );
      
      canvas.drawCircle(
        Offset(xCenter + xOffset, yCenter + yOffset),
        radius,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant NebulaPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class NutritionistScreen extends StatefulWidget {
  const NutritionistScreen({Key? key}) : super(key: key);

  @override
  State<NutritionistScreen> createState() => _NutritionistScreenState();
}

class _NutritionistScreenState extends State<NutritionistScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GroqService _groqService = GroqService();
  final ApiService _apiService = ApiService();
  
  int _selectedIndex = 1; // Nutritionist tab selected
  bool _isTyping = false;
  bool _isGroqConfigured = false;
  bool _isLoadingUserData = true;
  
  // Animation controller for the nebula effect
  late AnimationController _animationController;
  
  // User data for personalized recommendations
  Map<String, dynamic> _userData = {};
  
  // Chat messages
  List<Map<String, dynamic>> _messages = [];

  // Shared Preferences key for storing nutrition plan
  static const String _nutritionPlanKey = 'nutrition_plan_request';

  @override
  void initState() {
    super.initState();
    _checkGroqConfiguration();
    _fetchUserData();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 15000),
    )..repeat();
    
    // Set initial welcome message after getting user data
    _messages = [
      {
        'isUser': false,
        'message': 'Hello! I\'m Padma, your GROQ-powered nutrition assistant. I\'m analyzing your data to provide personalized advice...',
        'timestamp': DateTime.now(),
      },
    ];
    
    // Check for pending nutrition plan request
    _checkPendingNutritionPlan();
  }
  
  Future<void> _fetchUserData() async {
    try {
      final userDetails = await _apiService.getUserDetails();
      final dailyGoals = await _apiService.getDailyGoals();
      
      setState(() {
        _userData = {
          ...userDetails,
          'goals': dailyGoals,
        };
        _isLoadingUserData = false;
        
        // After data is loaded, update the welcome message
        if (_messages.isNotEmpty) {
          _messages[0] = {
            'isUser': false,
            'message': _buildWelcomeMessage(userDetails),
            'timestamp': DateTime.now(),
          };
        }
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }
  
  String _buildWelcomeMessage(Map<String, dynamic> userDetails) {
    String gender = userDetails['gender'] ?? '';
    if (gender == 'M') gender = 'male';
    else if (gender == 'F') gender = 'female';
    else if (gender == 'O') gender = 'non-binary';
    else gender = '';
    
    String activityLevel = userDetails['activity_level'] ?? '';
    
    if (userDetails.isEmpty) {
      return 'Hello! I\'m Padma, your GROQ-powered nutrition assistant. Please complete your profile so I can provide personalized advice.';
    }
    
    return 'Hello! I\'m Padma, your GROQ-powered nutrition assistant. Based on your profile (${userDetails['age']} years, ${gender}, ${userDetails['height']}cm, ${userDetails['current_weight']}kg, ${activityLevel} activity), I can provide personalized nutrition advice. How can I help you today?';
  }
  
  Future<void> _checkGroqConfiguration() async {
    try {
      final apiKey = await _groqService.getApiKey();
      setState(() {
        _isGroqConfigured = apiKey != null && apiKey.isNotEmpty;
      });
    } catch (e) {
      // Handle error
      print('Error checking Groq configuration: $e');
    }
  }

  Future<void> _checkPendingNutritionPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingPlan = prefs.getString(_nutritionPlanKey);
      
      if (pendingPlan != null) {
        // Found a pending nutrition plan request
        final planData = json.decode(pendingPlan) as Map<String, dynamic>;
        final userMessage = planData['message'] as String;
        
        // Add user message with a slight delay for better UX
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _messages.add({
                'isUser': true,
                'message': userMessage,
                'timestamp': DateTime.now(),
              });
              _isTyping = true;
            });
            
            // Process the nutrition plan request
            _processNutritionPlanRequest(userMessage);
            
            // Clear the stored request
            prefs.remove(_nutritionPlanKey);
          }
        });
      }
    } catch (e) {
      print('Error checking pending nutrition plan: $e');
    }
  }
  
  Future<void> _processNutritionPlanRequest(String userMessage) async {
    try {
      // Get response from Groq API
      final response = await _groqService.getNutritionistResponse(
        userMessage, 
        _messages.sublist(0, _messages.length - 1) // Exclude the message we just sent
      );
      
      if (!mounted) return;
      
      // Add AI response
      setState(() {
        _messages.add({
          'isUser': false,
          'message': response,
          'timestamp': DateTime.now(),
        });
        _isTyping = false;
      });
      
      // Scroll to bottom
      _scrollToBottom();
      
      // Extract and save nutrition values from Padma's response
      _extractAndSaveNutritionValues(response);
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _messages.add({
          'isUser': false,
          'message': 'Sorry, I encountered an error while generating your nutrition plan. Please try asking me again.',
          'timestamp': DateTime.now(),
        });
        _isTyping = false;
      });
    }
  }

  // Extract and save nutrition values from Padma's response
  Future<void> _extractAndSaveNutritionValues(String response) async {
    try {
      print('Extracting nutrition values from: $response');
      
      // First, check if this response is about a full day nutrition plan
      // rather than a specific meal plan
      if (!_isFullDayNutritionPlan(response)) {
        print('Response appears to be about a specific meal or not a full nutrition plan. Skipping daily goal update.');
        return;
      }
      
      print('Response appears to be about a full day nutrition plan. Proceeding with extraction.');

      // Attempt extraction with primary regex patterns
      Map<String, int?> extractedValues = _attemptExtraction(response);
      
      // If not all values are available, retry with alternative patterns
      if (extractedValues['calories'] == null || 
          extractedValues['protein'] == null || 
          extractedValues['carbs'] == null || 
          extractedValues['fat'] == null) {
        
        print('Not all values extracted in first attempt, trying alternative patterns...');
        Map<String, int?> retryValues = _attemptAlternativeExtraction(response);
        
        // Merge the results, taking values from retry only if the original was null
        if (extractedValues['calories'] == null) extractedValues['calories'] = retryValues['calories'];
        if (extractedValues['protein'] == null) extractedValues['protein'] = retryValues['protein'];
        if (extractedValues['carbs'] == null) extractedValues['carbs'] = retryValues['carbs'];
        if (extractedValues['fat'] == null) extractedValues['fat'] = retryValues['fat'];
      }
      
      // Extract the final values
      int? calories = extractedValues['calories'];
      int? protein = extractedValues['protein'];
      int? carbs = extractedValues['carbs'];
      int? fat = extractedValues['fat'];
      
      // Only proceed if ALL values are available
      if (calories != null && protein != null && carbs != null && fat != null) {
        final Map<String, dynamic> nutritionValues = {
          'calories': calories,
          'protein': protein,
          'carbohydrates': carbs,
          'fat': fat
        };
        
        print('All nutrition values extracted successfully: $nutritionValues');
        
        // Send to backend since we have all values
        final result = await _apiService.updateDailyGoals(nutritionValues);
        
        // Show success message if values were saved
        if (result.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Daily nutrition goals updated with Padma\'s recommendations'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('Not all nutrition values could be extracted:');
        print('Calories: $calories, Protein: $protein, Carbs: $carbs, Fat: $fat');
      }
    } catch (e) {
      print('Error extracting nutrition values: $e');
      // Don't show error to user since this is a background operation
    }
  }
  
  // Check if the response is about a full day nutrition plan
  bool _isFullDayNutritionPlan(String response) {
    // Convert to lowercase for case-insensitive matching
    final lowerResponse = response.toLowerCase();
    
    // Check if the response contains specific meal-related phrases
    // that would indicate it's NOT a full day plan
    final mealSpecificPhrases = [
      'breakfast recipe',
      'breakfast plan',
      'lunch recipe',
      'lunch plan',
      'dinner recipe',
      'dinner plan',
      'snack recipe',
      'snack idea',
      'meal recipe',
      'single meal',
      'this meal',
      'for this recipe',
    ];
    
    for (final phrase in mealSpecificPhrases) {
      if (lowerResponse.contains(phrase)) {
        return false;
      }
    }
    
    // Check if response contains phrases that indicate it IS a full day plan
    final fullDayPhrases = [
      'daily nutrition',
      'daily goals',
      'daily caloric',
      'daily intake',
      'daily needs',
      'day\'s nutrition',
      'per day',
      'each day',
      'daily macros',
      'daily macronutrients',
      'nutrition plan',
      'diet plan',
      'your diet should',
      'recommended daily',
      'total daily',
    ];
    
    for (final phrase in fullDayPhrases) {
      if (lowerResponse.contains(phrase)) {
        return true;
      }
    }
    
    // If the response contains the special formatted nutrients section at the beginning
    // OR contains all four nutrition labels with values close together
    // we'll assume it's a full day plan (this matches our prompt to the AI)
    if (lowerResponse.contains('**calories:') && 
        lowerResponse.contains('**protein:') && 
        lowerResponse.contains('**carbohydrates:') && 
        lowerResponse.contains('**fat:')) {
      return true;
    }
    
    // By default, be conservative and don't update daily goals
    // unless we're confident it's a full day plan
    return false;
  }
  
  // Primary extraction attempt with standard patterns
  Map<String, int?> _attemptExtraction(String response) {
    // Regex patterns
    final caloriesRegex = RegExp(r'Calories\s*:\s*(\d+)\s*calories', caseSensitive: false);
    final proteinRegex = RegExp(r'Protein:\s*(\d+)g', caseSensitive: false);
    final carbsRegex = RegExp(r'Carbohydrates:\s*(\d+)g', caseSensitive: false);
    final fatRegex = RegExp(r'Fat:\s*(\d+)g', caseSensitive: false);
    
    // Extract values
    int? calories;
    int? protein;
    int? carbs;
    int? fat;
    
    final caloriesMatch = caloriesRegex.firstMatch(response);
    if (caloriesMatch != null && caloriesMatch.groupCount >= 1) {
      calories = int.tryParse(caloriesMatch.group(1)!);
    }
    
    final proteinMatch = proteinRegex.firstMatch(response);
    if (proteinMatch != null && proteinMatch.groupCount >= 1) {
      protein = int.tryParse(proteinMatch.group(1)!);
    }
    
    final carbsMatch = carbsRegex.firstMatch(response);
    if (carbsMatch != null && carbsMatch.groupCount >= 1) {
      carbs = int.tryParse(carbsMatch.group(1)!);
    }
    
    final fatMatch = fatRegex.firstMatch(response);
    if (fatMatch != null && fatMatch.groupCount >= 1) {
      fat = int.tryParse(fatMatch.group(1)!);
    }
    
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat
    };
  }
  
  // Alternative extraction attempt with more flexible patterns
  Map<String, int?> _attemptAlternativeExtraction(String response) {
    // Alternative patterns that are more flexible
    final altCaloriesRegex = RegExp(r'(\d+)[\s-]*calories', caseSensitive: false);
    final altProteinRegex = RegExp(r'(\d+)[\s-]*g(?:rams)?[\s-]*(?:of)?[\s-]*protein', caseSensitive: false);
    final altCarbsRegex = RegExp(r'(\d+)[\s-]*g(?:rams)?[\s-]*(?:of)?[\s-]*carb(?:ohydrate)?s?', caseSensitive: false);
    final altFatRegex = RegExp(r'(\d+)[\s-]*g(?:rams)?[\s-]*(?:of)?[\s-]*fat', caseSensitive: false);
    
    // Extract values
    int? calories;
    int? protein;
    int? carbs;
    int? fat;
    
    final caloriesMatch = altCaloriesRegex.firstMatch(response);
    if (caloriesMatch != null && caloriesMatch.groupCount >= 1) {
      calories = int.tryParse(caloriesMatch.group(1)!);
    }
    
    final proteinMatch = altProteinRegex.firstMatch(response);
    if (proteinMatch != null && proteinMatch.groupCount >= 1) {
      protein = int.tryParse(proteinMatch.group(1)!);
    }
    
    final carbsMatch = altCarbsRegex.firstMatch(response);
    if (carbsMatch != null && carbsMatch.groupCount >= 1) {
      carbs = int.tryParse(carbsMatch.group(1)!);
    }
    
    final fatMatch = altFatRegex.firstMatch(response);
    if (fatMatch != null && fatMatch.groupCount >= 1) {
      fat = int.tryParse(fatMatch.group(1)!);
    }
    
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat
    };
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

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
      case 1: // Nutritionist - already here
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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final userMessage = _messageController.text.trim();
    
    final newMessage = {
      'isUser': true,
      'message': userMessage,
      'timestamp': DateTime.now(),
    };
    
    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
      _isTyping = true;
    });
    
    // Scroll to bottom after sending message
    _scrollToBottom();
    
    try {
      if (!_isGroqConfigured) {
        // Show error if Groq isn't configured
        throw Exception('Groq API is not properly configured. Please contact the administrator.');
      }
      
      // Get response from Groq API
      final response = await _groqService.getNutritionistResponse(
        userMessage, 
        _messages.sublist(0, _messages.length - 1) // Exclude the message we just sent
      );
      
      if (!mounted) return;
      
      final aiResponse = {
        'isUser': false,
        'message': response,
        'timestamp': DateTime.now(),
      };
      
      setState(() {
        _messages.add(aiResponse);
        _isTyping = false;
      });
      
      // Extract and save nutrition values from Padma's response
      _extractAndSaveNutritionValues(response);
    } catch (e) {
      if (!mounted) return;
      
      // Handle error
      final errorResponse = {
        'isUser': false,
        'message': 'Sorry, I encountered an error while processing your request: ${e.toString()}',
        'timestamp': DateTime.now(),
      };
      
      setState(() {
        _messages.add(errorResponse);
        _isTyping = false;
      });
      
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    // Scroll to bottom after receiving response
    _scrollToBottom();
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMessageBubble(String message, bool isUser, DateTime timestamp) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: isUser ? NebulaMessageBubble(
        message: message,
        timestamp: timestamp,
        animationController: _animationController,
      ) : Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.purpleAccent.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(
            color: Colors.deepPurple.withOpacity(0.3),
            width: 1,
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: message,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 15,
                ),
                strong: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                em: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
                h1: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                h2: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                h3: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                listBullet: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              extensionSet: md.ExtensionSet.gitHubWeb,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(timestamp),
              style: GoogleFonts.montserrat(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'PADMA',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purpleAccent.withOpacity(
                          0.3 + 0.2 * math.sin(_animationController.value * 2 * math.pi),
                        ),
                        blurRadius: 10 + 5 * math.sin(_animationController.value * 2 * math.pi),
                        spreadRadius: 2 + math.sin(_animationController.value * 2 * math.pi),
                      ),
                    ],
                    gradient: RadialGradient(
                      colors: [
                        Colors.deepPurple.withOpacity(0.7 + 0.3 * math.sin(_animationController.value * math.pi)),
                        Colors.indigo.withOpacity(0.5 + 0.2 * math.cos(_animationController.value * math.pi)),
                        Colors.blue.withOpacity(0.3 + 0.1 * math.sin(_animationController.value * 2 * math.pi)),
                      ],
                      stops: [
                        0.1,
                        0.4 + 0.1 * math.sin(_animationController.value * 2 * math.pi),
                        0.7 + 0.1 * math.cos(_animationController.value * 2 * math.pi),
                      ],
                    ),
                  ),
                  child: CustomPaint(
                    painter: NebulaPainter(_animationController.value),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background stars
          ...List.generate(50, (index) {
            final random = math.Random(index);
            return Positioned(
              left: random.nextDouble() * size.width,
              top: random.nextDouble() * size.height,
              child: Container(
                width: random.nextDouble() * 2,
                height: random.nextDouble() * 2,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(random.nextDouble() * 0.7 + 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
          
          // Main content
          Column(
            children: [
              // User data summary (if available)
              if (!_isLoadingUserData && _userData.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.purpleAccent.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Nebula circle avatar
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purpleAccent.withOpacity(0.3 + 0.2 * math.sin(_animationController.value * 2 * math.pi)),
                                  blurRadius: 10 + 5 * math.sin(_animationController.value * 2 * math.pi),
                                  spreadRadius: 1 + math.sin(_animationController.value * 2 * math.pi),
                                ),
                              ],
                              gradient: RadialGradient(
                                colors: [
                                  Colors.deepPurple.withOpacity(0.7 + 0.3 * math.sin(_animationController.value * math.pi)),
                                  Colors.indigo.withOpacity(0.5 + 0.2 * math.cos(_animationController.value * math.pi)),
                                  Colors.blue.withOpacity(0.3 + 0.1 * math.sin(_animationController.value * 2 * math.pi)),
                                ],
                                stops: [
                                  0.1,
                                  0.4 + 0.1 * math.sin(_animationController.value * 2 * math.pi),
                                  0.7 + 0.1 * math.cos(_animationController.value * 2 * math.pi),
                                ],
                              ),
                            ),
                            child: CustomPaint(
                              painter: NebulaPainter(_animationController.value),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      // User data text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Profile',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_userData['age'] ?? '?'} years, ${_userData['height'] ?? '?'}cm, ${_userData['current_weight'] ?? '?'}kg',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Goal
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Goal Weight',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                          Text(
                            '${_userData['goal_weight'] ?? '?'} kg',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              
              // Chat messages area
              Expanded(
                child: _isLoadingUserData
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Nebula Effect 
                            SizedBox(
                              height: 150,
                              width: 150,
                              child: AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.purpleAccent.withOpacity(0.3 + 0.2 * math.sin(_animationController.value * 2 * math.pi)),
                                          blurRadius: 20 + 10 * math.sin(_animationController.value * 2 * math.pi),
                                          spreadRadius: 5 + 3 * math.sin(_animationController.value * 2 * math.pi),
                                        ),
                                      ],
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.deepPurple.withOpacity(0.7 + 0.3 * math.sin(_animationController.value * math.pi)),
                                          Colors.indigo.withOpacity(0.5 + 0.2 * math.cos(_animationController.value * math.pi)),
                                          Colors.blue.withOpacity(0.3 + 0.1 * math.sin(_animationController.value * 2 * math.pi)),
                                          Colors.black.withOpacity(0.1),
                                        ],
                                        stops: [
                                          0.1,
                                          0.4 + 0.1 * math.sin(_animationController.value * 2 * math.pi),
                                          0.7 + 0.1 * math.cos(_animationController.value * 2 * math.pi),
                                          1.0,
                                        ],
                                      ),
                                    ),
                                    child: CustomPaint(
                                      painter: NebulaPainter(_animationController.value),
                                      child: Center(
                                        child: Text(
                                          "PADMA",
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 3,
                                            shadows: [
                                              Shadow(
                                                color: Colors.purpleAccent.withOpacity(0.7),
                                                blurRadius: 10,
                                                offset: const Offset(0, 0),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'Preparing your nutrition plan...',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Analyzing your personal data',
                              style: GoogleFonts.montserrat(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageBubble(
                            message['message'],
                            message['isUser'],
                            message['timestamp'],
                          );
                        },
                      ),
              ),
              
              // "AI is typing" indicator
              if (_isTyping)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        'Padma is thinking',
                        style: GoogleFonts.montserrat(
                          color: Colors.purpleAccent,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Message input area
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border(
                    top: BorderSide(color: Colors.deepPurple.withOpacity(0.3), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Ask Padma about nutrition...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.deepPurple.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.purpleAccent),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple, Colors.purpleAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purpleAccent.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send),
                        color: Colors.white,
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          currentIndex: _selectedIndex,
          onTap: _handleNavigation,
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.health_and_safety),
              label: 'Padma',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Logs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// Stateful widget for user message bubbles with nebula effect
class NebulaMessageBubble extends StatelessWidget {
  final String message;
  final DateTime timestamp;
  final AnimationController animationController;

  const NebulaMessageBubble({
    Key? key,
    required this.message,
    required this.timestamp,
    required this.animationController,
  }) : super(key: key);

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withOpacity(0.1 + 0.1 * math.sin(animationController.value * 2 * math.pi)),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: Colors.deepPurple.withOpacity(0.3),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.withOpacity(0.6 + 0.1 * math.sin(animationController.value * math.pi)),
                Colors.indigo.withOpacity(0.4 + 0.1 * math.cos(animationController.value * math.pi)),
                Colors.blue.withOpacity(0.2 + 0.1 * math.sin(animationController.value * 2 * math.pi)),
              ],
              stops: [
                0.2,
                0.5 + 0.1 * math.sin(animationController.value * 2 * math.pi),
                0.8,
              ],
            ),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(timestamp),
                style: GoogleFonts.montserrat(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 