import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _glowAnimation = Tween<double>(begin: 2.0, end: 8.0)
        .animate(CurvedAnimation(
            parent: _controller,
            curve: Curves.easeInOut,
        ));
        
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(
            parent: _controller,
            curve: Curves.easeInOut,
        ));

    _controller.repeat(reverse: true);
    
    // Check login status and navigate accordingly after splash delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _checkLoginAndNavigate();
      }
    });
  }
  
  Future<void> _checkLoginAndNavigate() async {
    final apiService = ApiService();
    final isLoggedIn = await apiService.isLoggedIn();
    
    if (!mounted) return;
    
    if (isLoggedIn) {
      // User is logged in, navigate to home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // User is not logged in, navigate to login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient circles
          Positioned(
            top: -size.height * 0.1,
            left: -size.width * 0.2,
            child: Container(
              height: size.height * 0.3,
              width: size.width * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.05,
            right: -size.width * 0.1,
            child: Container(
              height: size.height * 0.25,
              width: size.width * 0.25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Main content
          Center(
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Fire Logo with enhanced Saberglow
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        height: size.height * 0.2,
                        width: size.width * 0.4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(_pulseAnimation.value),
                              blurRadius: _glowAnimation.value * 12,
                              spreadRadius: _glowAnimation.value,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glow
                            Icon(
                              Icons.local_fire_department,
                              size: size.width * 0.22,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            // Inner fire icon
                            Icon(
                              Icons.local_fire_department,
                              size: size.width * 0.18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                  
                  SizedBox(height: size.height * 0.04),
                  
                  // App Name
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.white.withOpacity(0.8), Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'CALWATCH',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: size.width * 0.09,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: size.height * 0.02),
                  
                  // App description in Hindi
                  Text(
                    'नमस्ते',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: size.width * 0.06,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                  
                  SizedBox(height: size.height * 0.01),
                  
                  // App description
                  Text(
                    'Your calorie tracker app',
                    style: GoogleFonts.montserrat(
                      color: Colors.grey[400],
                      fontSize: size.width * 0.035,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 