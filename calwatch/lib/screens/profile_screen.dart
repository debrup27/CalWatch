import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'home_screen.dart';
import 'logs_screen.dart';
import 'nutritionist_screen.dart';
import 'login_screen.dart';
import '../services/api_service.dart';
import 'edit_profile_screen.dart';
import 'user_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Selected index for the bottom navigation
  int _selectedIndex = 3; // Profile tab selected by default
  
  // User data from API
  String _username = '';
  String _email = '';
  String _firstName = '';
  String _lastName = '';
  String _bio = '';
  String _profileImage = '';
  bool _isLoading = true;
  bool _hasError = false;
  
  // User details data
  Map<String, dynamic> _userDetails = {
    'age': 0,
    'height': 0.0,
    'current_weight': 0.0,
    'goal_weight': 0.0,
    'gender': '',
    'activity_level': '',
  };
  
  // Daily goals data
  Map<String, dynamic> _dailyGoals = {
    'calories': 0.0,
    'protein': 0.0,
    'carbohydrates': 0.0,
    'fat': 0.0,
  };
  
  // Sample micronutrients data for donut chart
  final Map<String, double> _micronutrientsData = {
    'Vitamin A': 85, // percentage of daily value
    'Vitamin C': 120,
    'Calcium': 65,
    'Iron': 70,
    'Potassium': 55,
  };

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }
  
  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      final apiService = ApiService();
      
      // Get user info (username, email, etc.)
      final userData = await apiService.getUserMe();
      
      // Get user details (age, height, weight, etc.)
      Map<String, dynamic> userDetails = {};
      Map<String, dynamic> dailyGoals = {};
      try {
        userDetails = await apiService.getUserDetails();
        
        // Get daily goals from shared preferences (stored when creating/updating user details)
        dailyGoals = await apiService.getDailyGoals();
      } catch (e) {
        print('User details not yet set up: $e');
        // User may not have details yet, this is okay
      }
      
      if (mounted) {
        setState(() {
          _username = userData['username'] ?? '';
          _email = userData['email'] ?? '';
          _firstName = userData['first_name'] ?? '';
          _lastName = userData['last_name'] ?? '';
          
          // Get profile data if available
          if (userData.containsKey('profile') && userData['profile'] != null) {
            _bio = userData['profile']['bio'] ?? '';
            _profileImage = userData['profile']['profile_image'] ?? '';
          }
          
          // Update user details if available
          if (userDetails.isNotEmpty) {
            _userDetails = userDetails;
          }
          
          // Update daily goals if available
          if (dailyGoals.isNotEmpty) {
            _dailyGoals = dailyGoals;
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LogsScreen()),
        );
        break;
      case 3: // Profile
        // Already on Profile screen
        break;
    }
  }
  
  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          username: _username,
          email: _email,
          firstName: _firstName,
          lastName: _lastName,
          bio: _bio,
        ),
      ),
    ).then((_) => _fetchUserData()); // Refresh data when returning
  }
  
  void _navigateToUserDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailsScreen(
          userDetails: _userDetails,
        ),
      ),
    ).then((_) => _fetchUserData()); // Refresh data when returning
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'PROFILE',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _hasError
              ? _buildErrorView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile header
                      _buildProfileHeader(),
                      
                      const SizedBox(height: 32),
                      
                      // User stats
                      _buildUserStats(),
                      
                      const SizedBox(height: 32),
                      
                      // Daily goals section
                      _buildDailyGoalsSection(),
                      
                      const SizedBox(height: 32),
                      
                      // Micronutrients chart
                      _buildMicronutrientsSection(),
                      
                      const SizedBox(height: 32),
                      
                      // Settings section
                      _buildSettingsSection(),
                    ],
                  ),
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
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load profile data',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchUserData,
            icon: const Icon(Icons.refresh),
            label: Text(
              'Retry',
              style: GoogleFonts.montserrat(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          // Profile picture
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[900],
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
              image: _profileImage.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(_profileImage),
                    fit: BoxFit.cover,
                  )
                : null,
            ),
            child: _profileImage.isEmpty
                ? const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 80,
                  )
                : null,
          ),
          
          const SizedBox(height: 16),
          
          // Username
          Text(
            _username,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          // Email
          Text(
            _email,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          
          // First name and last name if available
          if (_firstName.isNotEmpty || _lastName.isNotEmpty)
            Text(
              '$_firstName $_lastName',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          
          // Bio if available
          if (_bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _bio,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Edit profile button
          TextButton.icon(
            onPressed: _navigateToEditProfile,
            icon: const Icon(Icons.edit, color: Colors.white, size: 16),
            label: Text(
              'Edit Profile',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserStats() {
    final bool hasUserDetails = _userDetails.isNotEmpty && 
                               (_userDetails['age'] != 0 || 
                                _userDetails['height'] != 0.0 || 
                                _userDetails['current_weight'] != 0.0);
                                
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personal Stats',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (hasUserDetails)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                  onPressed: _navigateToUserDetails,
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats grid or empty state
          hasUserDetails
              ? GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildStatItem('Age', _userDetails['age'].toString()),
                    _buildStatItem('Height', '${_userDetails['height']} cm'),
                    _buildStatItem('Current Weight', '${_userDetails['current_weight']} kg'),
                    _buildStatItem('Goal Weight', '${_userDetails['goal_weight']} kg'),
                    _buildStatItem('Gender', _userDetails['gender'] ?? ''),
                    _buildStatItem('Activity Level', _userDetails['activity_level'] ?? ''),
                  ],
                )
              : Center(
                  child: Column(
                    children: [
                      Text(
                        'No stats available yet',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _navigateToUserDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Add Your Details',
                          style: GoogleFonts.montserrat(),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDailyGoalsSection() {
    // Check if we have meaningful daily goals data
    final bool hasDailyGoals = _dailyGoals.isNotEmpty && 
                              (_dailyGoals['calories'] != 0.0 || 
                               _dailyGoals['protein'] != 0.0 || 
                               _dailyGoals['carbohydrates'] != 0.0 || 
                               _dailyGoals['fat'] != 0.0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Nutrition Goals',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Icon(Icons.restaurant_menu, color: Colors.green, size: 20),
            ],
          ),
          
          const SizedBox(height: 16),
          
          hasDailyGoals
              ? Column(
                  children: [
                    // Calories bar
                    _buildNutritionGoalBar(
                      'Calories', 
                      '${_dailyGoals['calories'].toStringAsFixed(0)} kcal', 
                      Colors.orange
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Protein bar
                    _buildNutritionGoalBar(
                      'Protein', 
                      '${_dailyGoals['protein'].toStringAsFixed(0)} g', 
                      Colors.red
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Carbs bar
                    _buildNutritionGoalBar(
                      'Carbohydrates', 
                      '${_dailyGoals['carbohydrates'].toStringAsFixed(0)} g', 
                      Colors.blue
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Fat bar
                    _buildNutritionGoalBar(
                      'Fat', 
                      '${_dailyGoals['fat'].toStringAsFixed(0)} g', 
                      Colors.yellow
                    ),
                  ],
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      children: [
                        Text(
                          'No nutrition goals available',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete your profile details to generate goals',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
  
  Widget _buildNutritionGoalBar(String label, String value, Color color) {
    return Row(
      children: [
        // Colored indicator
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Label
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
        
        // Value
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMicronutrientsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Micronutrients',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '7-day average (% of daily value)',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Micronutrients list with circular progress indicators
          ..._micronutrientsData.entries.map((entry) {
            final Color color = _getMicronutrientColor(entry.value);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${entry.value.toInt()}%',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: entry.value / 100,
                    backgroundColor: Colors.grey[800],
                    color: color,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Color _getMicronutrientColor(double percentage) {
    if (percentage < 50) {
      return Colors.red;
    } else if (percentage < 80) {
      return Colors.orange;
    } else if (percentage < 100) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }
  
  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Settings list
          _buildSettingItem(Icons.notifications_outlined, 'Notifications'),
          _buildSettingItem(Icons.lock_outline, 'Privacy'),
          _buildSettingItem(Icons.help_outline, 'Help & Support'),
          _buildSettingItem(Icons.info_outline, 'About'),
          _buildSettingItem(Icons.logout, 'Sign Out', isDestructive: true),
        ],
      ),
    );
  }
  
  Widget _buildSettingItem(IconData icon, String label, {bool isDestructive = false}) {
    return InkWell(
      onTap: () {
        if (isDestructive) {
          _handleLogout();
        } else {
          // Handle other settings options
          switch (label) {
            case 'Notifications':
              // Navigate to notifications settings
              break;
            case 'Privacy':
              // Navigate to privacy settings
              break;
            case 'Help & Support':
              // Navigate to help & support
              break;
            case 'About':
              // Show about dialog
              break;
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: isDestructive ? Colors.red : Colors.white,
              ),
            ),
            const Spacer(),
            if (!isDestructive)
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Sign Out',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to sign out?',
            style: GoogleFonts.montserrat(
              color: Colors.white,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(
                'Sign Out',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _performLogout() {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        );
      },
    );
    
    // Call the logout method from ApiService
    final apiService = ApiService();
    apiService.logout().then((_) {
      // Close the loading dialog
      Navigator.pop(context);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logged out successfully',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Navigate to login screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // This removes all previous routes from the stack
      );
    }).catchError((error) {
      // Close the loading dialog
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error logging out: $error',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }
} 