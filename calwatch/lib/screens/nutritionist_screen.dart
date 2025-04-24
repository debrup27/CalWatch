import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/groq_service.dart';
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
  final GroqService _groqService = GroqService();
  
  int _selectedIndex = 1; // Nutritionist tab selected
  bool _isTyping = false;
  bool _isGroqConfigured = false;
  
  // Chat messages
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'message': 'Hello! I\'m your AI Nutritionist. How can I help you with your diet and nutrition goals today?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkGroqConfiguration();
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
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? Colors.white : Colors.grey[800],
          borderRadius: BorderRadius.circular(18),
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
                color: isUser ? Colors.black : Colors.white,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(timestamp),
              style: GoogleFonts.montserrat(
                color: isUser ? Colors.black54 : Colors.grey[400],
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
                      fontSize: 14,
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(color: Colors.grey[800]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send),
                    color: Colors.black,
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _handleNavigation,
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety),
            label: 'Nutritionist',
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
    );
  }
} 