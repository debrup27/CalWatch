import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'dart:math' as math;
import 'home_screen.dart';
import 'nutritionist_screen.dart';
import '../services/groq_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> userDetails;
  final bool isNewUser;

  const UserDetailsScreen({
    Key? key,
    required this.userDetails,
    this.isNewUser = false,
  }) : super(key: key);

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _currentWeightController;
  late TextEditingController _goalWeightController;
  
  String _selectedGender = '';
  String _selectedActivityLevel = '';
  
  bool _isLoading = false;
  bool _showThankYouMessage = false;
  
  // Animation controller for the nebula effect
  late AnimationController _animationController;
  
  // Options for dropdown menus
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _activityLevelOptions = [
    'Sedentary', 
    'Medium',
    'High'
  ];
  
  // Variable to store user data
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 15000),
    )..repeat();
    
    // Initialize controllers with existing values or defaults
    _ageController = TextEditingController(
      text: widget.userDetails['age'] != null && widget.userDetails['age'] != 0 ? widget.userDetails['age'].toString() : ''
    );
    
    _heightController = TextEditingController(
      text: widget.userDetails['height'] != null && widget.userDetails['height'] != 0.0 ? widget.userDetails['height'].toString() : ''
    );
    
    _currentWeightController = TextEditingController(
      text: widget.userDetails['current_weight'] != null && widget.userDetails['current_weight'] != 0.0 ? widget.userDetails['current_weight'].toString() : ''
    );
    
    _goalWeightController = TextEditingController(
      text: widget.userDetails['goal_weight'] != null && widget.userDetails['goal_weight'] != 0.0 ? widget.userDetails['goal_weight'].toString() : ''
    );
    
    // Initialize gender and activity level if provided, otherwise keep empty
    _selectedGender = widget.userDetails['gender'] != null ? 
                     (widget.userDetails['gender'] == 'M' ? 'Male' : 
                      widget.userDetails['gender'] == 'F' ? 'Female' :
                      widget.userDetails['gender'] == 'O' ? 'Other' : '') : '';
                      
    _selectedActivityLevel = widget.userDetails['activity_level'] != null ?
                            widget.userDetails['activity_level'].toString().isNotEmpty ?
                            widget.userDetails['activity_level'].toString().substring(0, 1).toUpperCase() +
                            widget.userDetails['activity_level'].toString().substring(1) : '' : '';
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _currentWeightController.dispose();
    _goalWeightController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveUserDetails() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check required dropdown fields
    if (_selectedGender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a gender'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_selectedActivityLevel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an activity level'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final apiService = ApiService();
      
      // Parse values with appropriate data types
      int age = int.parse(_ageController.text.trim());
      double height = double.parse(_heightController.text.trim());
      double currentWeight = double.parse(_currentWeightController.text.trim());
      double goalWeight = double.parse(_goalWeightController.text.trim());
      
      // Prepare user details data with correct data types
      final userDetailsData = {
        'age': age,
        'height': height,
        'current_weight': currentWeight, 
        'goal_weight': goalWeight,
        'gender': _selectedGender == 'Other' ? 'O' : _selectedGender.substring(0, 1), // Store first letter of gender
        'activity_level': _selectedActivityLevel.toLowerCase(), // Convert to lowercase
      };
      
      // Store in local variable
      _userData = userDetailsData;
      
      // Send data to API - use different method based on if it's a new user
      if (widget.isNewUser) {
        // New user - use POST
        await apiService.createUserDetails(userDetailsData);
      } else {
        // Existing user - use PATCH
        await apiService.updateUserDetails(userDetailsData);
      }
      
      setState(() {
        _isLoading = false;
        _showThankYouMessage = true;
      });
      
      // Generate nutrition plan with GROQ
      _generateNutritionPlan(userDetailsData);
      
      // Wait for 2 seconds to show thank you message then navigate to Padma
      Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => const NutritionistScreen())
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving user details: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Generate nutrition plan using GROQ
  Future<void> _generateNutritionPlan(Map<String, dynamic> userData) async {
    try {
      final groqService = GroqService();
      final prefs = await SharedPreferences.getInstance();
      
      // Create meaningful prompt about the user data
      String genderText = userData['gender'] == 'M' ? 'male' : 
                          userData['gender'] == 'F' ? 'female' : 'non-binary';
      
      String prompt = '''
Based on these user details, provide a personalized nutrition plan:
- Age: ${userData['age']}
- Gender: $genderText
- Height: ${userData['height']} cm
- Current weight: ${userData['current_weight']} kg
- Goal weight: ${userData['goal_weight']} kg
- Activity level: ${userData['activity_level']}

Please include:
1. Daily calorie recommendation
2. Macronutrient breakdown (proteins, carbs, fats)
3. Key micronutrients to focus on
4. A sample daily meal plan
''';

      // Store the request in SharedPreferences for NutritionistScreen to process
      await prefs.setString('nutrition_plan_request', json.encode({
        'message': prompt,
        'timestamp': DateTime.now().toIso8601String(),
      }));
      
    } catch (e) {
      print('Error generating nutrition plan: $e');
      // Non-fatal error, user can still proceed
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background stars
          ...List.generate(100, (index) {
            final random = math.Random();
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
          SafeArea(
            child: _showThankYouMessage 
                ? _buildThankYouMessage()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          
                          // Header
                          Text(
                            'PADMA',
                            style: GoogleFonts.montserrat(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 3,
                            ),
                          ),
                          
                          Text(
                            'Your GROQ-Powered Nutrition Assistant',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey[400],
                              letterSpacing: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Nebula Effect 
                          Center(
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return Container(
                                  height: size.width * 0.6,
                                  width: size.width * 0.6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purpleAccent.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.deepPurple.withOpacity(0.7),
                                        Colors.indigo.withOpacity(0.5),
                                        Colors.blue.withOpacity(0.3),
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
                                  child: Stack(
                                    children: List.generate(20, (index) {
                                      final random = math.Random(index);
                                      return Positioned(
                                        left: size.width * 0.3 * random.nextDouble() + 
                                            size.width * 0.15 * math.sin((_animationController.value + index / 20) * 2 * math.pi),
                                        top: size.width * 0.3 * random.nextDouble() + 
                                            size.width * 0.15 * math.cos((_animationController.value + index / 20) * 2 * math.pi),
                                        child: Container(
                                          width: random.nextDouble() * 8 + 2,
                                          height: random.nextDouble() * 8 + 2,
                                          decoration: BoxDecoration(
                                            color: [
                                              Colors.white,
                                              Colors.blueAccent,
                                              Colors.purpleAccent,
                                              Colors.pinkAccent,
                                            ][random.nextInt(4)].withOpacity(
                                              0.3 + 0.7 * random.nextDouble(),
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white.withOpacity(0.3),
                                                blurRadius: 5,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          Text(
                            'Please tell me about yourself so I can help you achieve your nutrition goals',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Age field
                          TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[900],
                              labelText: 'Age',
                              labelStyle: GoogleFonts.montserrat(
                                color: Colors.grey[400],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your age';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Height field
                          TextFormField(
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[900],
                              labelText: 'Height (cm)',
                              labelStyle: GoogleFonts.montserrat(
                                color: Colors.grey[400],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your height';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Current Weight field
                          TextFormField(
                            controller: _currentWeightController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[900],
                              labelText: 'Current Weight (kg)',
                              labelStyle: GoogleFonts.montserrat(
                                color: Colors.grey[400],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your current weight';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Goal Weight field
                          TextFormField(
                            controller: _goalWeightController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[900],
                              labelText: 'Goal Weight (kg)',
                              labelStyle: GoogleFonts.montserrat(
                                color: Colors.grey[400],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your goal weight';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Gender dropdown - redesigned
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gender',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: _genderOptions.map((gender) {
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedGender = gender;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: _selectedGender == gender
                                                  ? Colors.purpleAccent.withOpacity(0.3)
                                                  : Colors.grey[900],
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: _selectedGender == gender
                                                    ? Colors.purpleAccent
                                                    : Colors.grey[800]!,
                                                width: 1,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                gender,
                                                style: GoogleFonts.montserrat(
                                                  color: _selectedGender == gender
                                                      ? Colors.white
                                                      : Colors.grey[400],
                                                  fontWeight: _selectedGender == gender
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Activity Level dropdown - redesigned
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Activity Level',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: _activityLevelOptions.map((level) {
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedActivityLevel = level;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            decoration: BoxDecoration(
                                              color: _selectedActivityLevel == level
                                                  ? Colors.blueAccent.withOpacity(0.3)
                                                  : Colors.grey[900],
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: _selectedActivityLevel == level
                                                    ? Colors.blueAccent
                                                    : Colors.grey[800]!,
                                                width: 1,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                level,
                                                style: GoogleFonts.montserrat(
                                                  color: _selectedActivityLevel == level
                                                      ? Colors.white
                                                      : Colors.grey[400],
                                                  fontWeight: _selectedActivityLevel == level
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveUserDetails,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                                shadowColor: Colors.purpleAccent.withOpacity(0.5),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Continue',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildThankYouMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.greenAccent,
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'Thank you!',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'I now have all the information needed to help you on your nutrition journey.',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey[300],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
          ),
        ],
      ),
    );
  }
} 