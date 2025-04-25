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
} 