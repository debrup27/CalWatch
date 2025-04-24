import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';
import 'logs_screen.dart';
import 'profile_screen.dart';

class NutritionistScreen extends StatefulWidget {
  const NutritionistScreen({Key? key}) : super(key: key);

  @override
  State<NutritionistScreen> createState() => _NutritionistScreenState();
}

class _NutritionistScreenState extends State<NutritionistScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 1; // Nutritionist tab selected
  bool _isTyping = false;
  
  // Sample chat messages
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'message': 'Hello! I\'m your AI Nutritionist. How can I help you with your diet and nutrition goals today?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
    },
    {
      'isUser': true,
      'message': 'I want to lose weight but I\'m struggling with my diet.',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 29)),
    },
    {
      'isUser': false,
      'message': 'I understand how challenging weight loss can be. Based on the profile details you provided, I can help create a personalized plan. Let\'s first talk about your current eating habits. What does your typical daily food intake look like?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 27)),
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
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

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final newMessage = {
      'isUser': true,
      'message': _messageController.text.trim(),
      'timestamp': DateTime.now(),
    };
    
    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
      _isTyping = true;
    });
    
    // Scroll to bottom after sending message
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
    
    // Simulate AI response after 1 second
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      final aiResponse = {
        'isUser': false,
        'message': _getAIResponse(newMessage['message'] as String),
        'timestamp': DateTime.now(),
      };
      
      setState(() {
        _messages.add(aiResponse);
        _isTyping = false;
      });
      
      // Scroll to bottom after receiving response
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    });
  }
  
  // Sample AI responses based on user input
  String _getAIResponse(String userMessage) {
    final lowercaseMsg = userMessage.toLowerCase();
    
    if (lowercaseMsg.contains('calorie') || lowercaseMsg.contains('calories')) {
      return 'Based on your profile details (age, height, weight, and activity level), your daily caloric needs are approximately 1800-2000 calories for maintenance. For weight loss, a moderate deficit of 300-500 calories per day is generally recommended, which would be around 1500-1700 calories daily.';
    } else if (lowercaseMsg.contains('protein') || lowercaseMsg.contains('fat') || lowercaseMsg.contains('carb')) {
      return 'A balanced macronutrient distribution would be approximately: 30% protein (115-130g), 30% fat (50-60g), and 40% carbohydrates (150-170g). This can vary based on your specific goals and preferences.';
    } else if (lowercaseMsg.contains('meal plan') || lowercaseMsg.contains('diet plan')) {
      return 'I can help create a personalized meal plan for you. For sustainable weight loss, focus on whole foods like lean proteins (chicken, fish, tofu), complex carbs (brown rice, sweet potatoes), healthy fats (avocado, nuts), and plenty of vegetables. Would you like me to suggest a sample day of eating?';
    } else if (lowercaseMsg.contains('exercise') || lowercaseMsg.contains('workout')) {
      return 'Exercise is a key component of weight management. Based on your activity level, I recommend a combination of 150 minutes of moderate cardio per week plus 2-3 strength training sessions. This, combined with proper nutrition, will help you reach your goal weight of ${_getRandomWeight()}.';
    } else if (lowercaseMsg.contains('hungry') || lowercaseMsg.contains('craving')) {
      return 'Hunger and cravings are normal! Try drinking water first, as thirst is often confused with hunger. For snacks, choose high-protein, high-fiber options like Greek yogurt with berries, apple with almond butter, or a small handful of nuts to stay satisfied between meals.';
    } else {
      return 'Thank you for sharing. Based on your goals and profile information, I recommend focusing on creating a sustainable calorie deficit through balanced nutrition and regular physical activity. Would you like specific advice on meal planning, exercise routines, or strategies to overcome common obstacles?';
    }
  }
  
  String _getRandomWeight() {
    final weights = ['65kg', '140lbs', '62kg', '135lbs'];
    return weights[DateTime.now().millisecond % weights.length];
  }
  
  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 1,
        title: Text(
          'AI Nutritionist',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: ListView.builder(
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
                    'AI Nutritionist is typing',
                    style: GoogleFonts.montserrat(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          
          // Message input area
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _messageController,
                    style: GoogleFonts.montserrat(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ask me about nutrition...',
                      hintStyle: GoogleFonts.montserrat(color: Colors.grey[500]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.send,
                    onFieldSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(
                    Icons.send_rounded,
                    color: Colors.green,
                  ),
                  tooltip: 'Send message',
                ),
              ],
            ),
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
  
  Widget _buildMessageBubble(String message, bool isUser, DateTime timestamp) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? Colors.green : Colors.grey[800],
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(0),
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: GoogleFonts.montserrat(
                color: isUser ? Colors.white : Colors.grey[300],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(timestamp),
              style: GoogleFonts.montserrat(
                color: isUser ? Colors.white.withOpacity(0.7) : Colors.grey[500],
                fontSize: 10,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }
} 