import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'home_screen.dart';
import 'logs_screen.dart';
import 'nutritionist_screen.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

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
  bool _isLoading = true;
  bool _hasError = false;
  
  // Sample user stats
  final Map<String, dynamic> _userData = {
    'age': 32,
    'height': '180 cm',
    'currentWeight': '72.5 kg',
    'goalWeight': '70 kg',
    'activityLevel': 'Moderate',
    'dailyCalorieGoal': 1800,
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
    _fetchUserDetails();
  }
  
  Future<void> _fetchUserDetails() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      final apiService = ApiService();
      final userData = await apiService.getUserDetails();
      
      setState(() {
        _username = userData['username'] ?? '';
        _email = userData['email'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching user details: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
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
      body: SingleChildScrollView(
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
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 80,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // User info with loading indicator
          if (_isLoading)
            const CircularProgressIndicator(color: Colors.white)
          else if (_hasError)
            Column(
              children: [
                Text(
                  'Failed to load user data',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: Colors.red[300],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _fetchUserDetails,
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                  label: Text(
                    'Retry',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
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
              ],
            ),
          
          const SizedBox(height: 16),
          
          // Edit profile button
          if (!_isLoading && !_hasError)
            TextButton.icon(
              onPressed: () {
                // TODO: Implement edit profile functionality
              },
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
            'Personal Stats',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Stats grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildStatItem('Age', _userData['age'].toString()),
              _buildStatItem('Height', _userData['height']),
              _buildStatItem('Current Weight', _userData['currentWeight']),
              _buildStatItem('Goal Weight', _userData['goalWeight']),
              _buildStatItem('Activity Level', _userData['activityLevel']),
              _buildStatItem('Daily Calorie Goal', '${_userData['dailyCalorieGoal']} kcal'),
            ],
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