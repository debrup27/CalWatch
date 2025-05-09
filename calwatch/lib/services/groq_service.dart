import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  // Groq API base URL
  static const String baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  // API Key should be stored securely, consider using environment variables
  // For now, we'll store it in shared preferences, but this is not ideal for production
  static const String _apiKeyPrefsKey = 'groq_api_key';
  
  // Singleton instance
  static final GroqService _instance = GroqService._internal();
  
  factory GroqService() {
    return _instance;
  }
  
  GroqService._internal();
  
  // Get API key from environment if available, otherwise from shared preferences
  Future<String?> getApiKey() async {
    // First try to get from environment
    final envApiKey = dotenv.env['GROQ_API_KEY'];
    print("Trying to get GROQ_API_KEY from .env: ${envApiKey != null ? 'found' : 'not found'}");
    
    if (envApiKey != null && envApiKey.isNotEmpty) {
      print("Using API key from .env file");
      return envApiKey;
    }
    
    // Fall back to shared preferences
    print("Falling back to shared preferences for API key");
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_apiKeyPrefsKey);
    print("API key from shared preferences: ${savedKey != null ? 'found' : 'not found'}");
    
    return savedKey;
  }
  
  // Set API key (call this during app initialization or in settings)
  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefsKey, apiKey);
  }
  
  // Main method to get a response from Groq
  Future<String> getNutritionistResponse(String userMessage, List<Map<String, dynamic>> chatHistory) async {
    final apiKey = await getApiKey();
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Groq API key is not set');
    }
    
    // Prepare messages for Groq API
    final List<Map<String, String>> messages = [];
    
    // System message to define the AI's role
    messages.add({
      'role': 'system',
      'content': 'You are a knowledgeable nutrition assistant helping users with their diet, nutrition, and health questions. '
          'Provide helpful, accurate information based on modern nutrition science. '
          'Be friendly and supportive. If you don\'t know something, admit it rather than making up information. '
          'Keep responses concise and focused on nutrition and health topics.'
          'When recommending diet plans, ALWAYS include clear numeric values in this format: XXX calories, XX g protein, XX g carbohydrates, XX g fat. '
          'Use bold text with ** for important values, like **2000 calories**. '
          'Your recommendations will be used to update the user\'s nutrition targets in the app.'
          'ALWAYS include nutrition values in this exact format at the beginning of your message: '
          '**Calories: 2000 calories**'
          '**Protein: 70g**'
          '**Carbohydrates: 250g**'
          '**Fat: 65g**'
          'Always provide specific single values, not ranges. Approximations are okay, but always give one specific number.'
    });
    
    // Add chat history for context
    for (final message in chatHistory) {
      messages.add({
        'role': message['isUser'] ? 'user' : 'assistant',
        'content': message['message'] as String,
      });
    }
    
    // Add current user message
    messages.add({
      'role': 'user',
      'content': userMessage,
    });
    
    // Prepare request body
    final body = jsonEncode({
      'model': 'llama3-8b-8192', // You can adjust the model as needed
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': 800,
    });
    
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: body,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return content;
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {'error': 'Unknown error'};
        final errorMessage = errorBody['error']?['message'] ?? 'Unknown error: ${response.statusCode}';
        throw Exception('Failed to get response from Groq API: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error communicating with Groq API: ${e.toString()}');
    }
  }
  
  // Add a new method to get streak-based motivational quotes
  Future<String> getStreakMotivationalQuote(int streakCount) async {
    final apiKey = await getApiKey();
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Groq API key is not set');
    }
    
    // Prepare messages for Groq API
    final List<Map<String, String>> messages = [];
    
    // Define streak milestone categories
    String streakCategory;
    if (streakCount == 0) {
      streakCategory = "just starting out";
    } else if (streakCount == 1) {
      streakCategory = "first day";
    } else if (streakCount <= 3) {
      streakCategory = "early days (2-3 days)";
    } else if (streakCount <= 7) {
      streakCategory = "building momentum (4-7 days)";
    } else if (streakCount <= 14) {
      streakCategory = "establishing habits (1-2 weeks)";
    } else if (streakCount <= 30) {
      streakCategory = "strong commitment (2-4 weeks)";
    } else if (streakCount <= 60) {
      streakCategory = "impressive dedication (1-2 months)";
    } else if (streakCount <= 90) {
      streakCategory = "major achievement (2-3 months)";
    } else {
      streakCategory = "exceptional consistency (3+ months)";
    }
    
    // System message to define the AI's role
    messages.add({
      'role': 'system',
      'content': 'You are Padma, a supportive nutrition coach who provides motivational quotes related to health, nutrition, and consistency. '
          'Keep responses short (1-2 sentences), inspiring, and personalized to the user\'s current streak milestone. '
          'No greetings or explanations - just deliver the motivational quote.'
    });
    
    // Add current user message
    messages.add({
      'role': 'user',
      'content': 'I have a $streakCount day streak of meeting my nutrition goals. I\'m $streakCategory. Give me a motivational quote that\'s specific to my current streak milestone and will inspire me to maintain my streak.',
    });
    
    // Prepare request body
    final body = jsonEncode({
      'model': 'llama3-8b-8192', // Using Llama 3 for quick and efficient responses
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': 100, // Short quotes only
    });
    
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: body,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return content.trim();
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {'error': 'Unknown error'};
        final errorMessage = errorBody['error']?['message'] ?? 'Unknown error: ${response.statusCode}';
        throw Exception('Failed to get motivational quote from Groq API: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error communicating with Groq API: ${e.toString()}');
    }
  }
} 