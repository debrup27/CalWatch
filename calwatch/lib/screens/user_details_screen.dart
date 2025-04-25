import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

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

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _currentWeightController;
  late TextEditingController _goalWeightController;
  
  String _selectedGender = '';
  String _selectedActivityLevel = '';
  
  bool _isLoading = false;
  
  // Options for dropdown menus
  final List<String> _genderOptions = ['M', 'F', 'Other'];
  final List<String> _activityLevelOptions = [
    'sedentary', 
    'medium',
    'high'
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing values or defaults
    _ageController = TextEditingController(
      text: widget.userDetails['age'] != 0 ? widget.userDetails['age'].toString() : ''
    );
    
    _heightController = TextEditingController(
      text: widget.userDetails['height'] != 0.0 ? widget.userDetails['height'].toString() : ''
    );
    
    _currentWeightController = TextEditingController(
      text: widget.userDetails['current_weight'] != 0.0 ? widget.userDetails['current_weight'].toString() : ''
    );
    
    _goalWeightController = TextEditingController(
      text: widget.userDetails['goal_weight'] != 0.0 ? widget.userDetails['goal_weight'].toString() : ''
    );
    
    _selectedGender = widget.userDetails['gender'] ?? '';
    _selectedActivityLevel = widget.userDetails['activity_level'] ?? '';
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _currentWeightController.dispose();
    _goalWeightController.dispose();
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
        'gender': _selectedGender,
        'activity_level': _selectedActivityLevel,
      };
      
      print('Sending user details: $userDetailsData');
      
      // Send data to API - use different method based on if it's a new user
      if (widget.isNewUser) {
        // New user - use POST
        await apiService.createUserDetails(userDetailsData);
      } else {
        // Existing user - use PATCH
        await apiService.updateUserDetails(userDetailsData);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User details saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Return to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving user details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'User Details',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Age field
              Text(
                'Age',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[900],
                  hintText: 'Enter your age',
                  hintStyle: GoogleFonts.montserrat(
                    color: Colors.grey[700],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white),
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
              
              const SizedBox(height: 24),
              
              // Height field
              Text(
                'Height (cm)',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[900],
                  hintText: 'Enter your height in cm',
                  hintStyle: GoogleFonts.montserrat(
                    color: Colors.grey[700],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white),
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
              
              const SizedBox(height: 24),
              
              // Current Weight field
              Text(
                'Current Weight (kg)',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentWeightController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[900],
                  hintText: 'Enter your current weight in kg',
                  hintStyle: GoogleFonts.montserrat(
                    color: Colors.grey[700],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white),
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
              
              const SizedBox(height: 24),
              
              // Goal Weight field
              Text(
                'Goal Weight (kg)',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _goalWeightController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[900],
                  hintText: 'Enter your goal weight in kg',
                  hintStyle: GoogleFonts.montserrat(
                    color: Colors.grey[700],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[800]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white),
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
              
              const SizedBox(height: 24),
              
              // Gender dropdown
              Text(
                'Gender',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGender.isEmpty ? null : _selectedGender,
                    hint: Text(
                      'Select your gender',
                      style: GoogleFonts.montserrat(
                        color: Colors.grey[700],
                      ),
                    ),
                    isExpanded: true,
                    dropdownColor: Colors.grey[900],
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                    ),
                    items: _genderOptions.map((String gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGender = newValue ?? '';
                      });
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Activity Level dropdown
              Text(
                'Activity Level',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedActivityLevel.isEmpty ? null : _selectedActivityLevel,
                    hint: Text(
                      'Select your activity level',
                      style: GoogleFonts.montserrat(
                        color: Colors.grey[700],
                      ),
                    ),
                    isExpanded: true,
                    dropdownColor: Colors.grey[900],
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                    ),
                    items: _activityLevelOptions.map((String level) {
                      return DropdownMenuItem<String>(
                        value: level,
                        child: Text(level.substring(0, 1).toUpperCase() + level.substring(1)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedActivityLevel = newValue ?? '';
                      });
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveUserDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.grey,
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
                          'Save & Continue',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 