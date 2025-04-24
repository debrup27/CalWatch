import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL for API
  static const String baseUrl = 'https://api.calwatch.com/api/v1';
  
  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String signupEndpoint = '/auth/signup';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String logoutEndpoint = '/auth/logout';
  static const String userProfileEndpoint = '/user/profile';
  static const String nutritionDataEndpoint = '/nutrition/data';
  static const String foodEntriesEndpoint = '/food/entries';
  static const String logsEndpoint = '/logs';
  static const String searchFoodsEndpoint = '/food/search';
  
  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();
  
  // Get JWT token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // Save JWT token to shared preferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  // Clear JWT token from shared preferences
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  // Headers builder with authorization
  Future<Map<String, String>> _buildHeaders({bool withAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (withAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  // Handle response and errors
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success response
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      }
      return null;
    } else {
      // Error handling
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'An error occurred');
    }
  }
  
  // Authentication APIs
  
  // User login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl$loginEndpoint'),
      headers: await _buildHeaders(withAuth: false),
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );
    
    final data = _handleResponse(response);
    if (data != null && data['token'] != null) {
      await _saveToken(data['token']);
    }
    return data;
  }
  
  // User signup
  Future<Map<String, dynamic>> signup(String fullName, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl$signupEndpoint'),
      headers: await _buildHeaders(withAuth: false),
      body: json.encode({
        'fullName': fullName,
        'email': email,
        'password': password,
      }),
    );
    
    final data = _handleResponse(response);
    if (data != null && data['token'] != null) {
      await _saveToken(data['token']);
    }
    return data;
  }
  
  // Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl$resetPasswordEndpoint'),
      headers: await _buildHeaders(withAuth: false),
      body: json.encode({
        'email': email,
      }),
    );
    
    return _handleResponse(response);
  }
  
  // User logout
  Future<void> logout() async {
    final response = await http.post(
      Uri.parse('$baseUrl$logoutEndpoint'),
      headers: await _buildHeaders(),
    );
    
    _handleResponse(response);
    await _clearToken();
  }
  
  // User Profile APIs
  
  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl$userProfileEndpoint'),
      headers: await _buildHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    final response = await http.post(
      Uri.parse('$baseUrl$userProfileEndpoint'),
      headers: await _buildHeaders(),
      body: json.encode(profileData),
    );
    
    return _handleResponse(response);
  }
  
  // Nutrition and Food APIs
  
  // Get nutrition data (calories, macros, etc.)
  Future<Map<String, dynamic>> getNutritionData({String? date}) async {
    final dateParam = date != null ? '?date=$date' : '';
    final response = await http.get(
      Uri.parse('$baseUrl$nutritionDataEndpoint$dateParam'),
      headers: await _buildHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  // Add food entry
  Future<Map<String, dynamic>> addFoodEntry(Map<String, dynamic> foodData) async {
    final response = await http.post(
      Uri.parse('$baseUrl$foodEntriesEndpoint'),
      headers: await _buildHeaders(),
      body: json.encode(foodData),
    );
    
    return _handleResponse(response);
  }
  
  // Get food entries
  Future<List<dynamic>> getFoodEntries({String? date, String? mealType}) async {
    String queryParams = '';
    
    if (date != null) {
      queryParams = '?date=$date';
      if (mealType != null) {
        queryParams += '&mealType=$mealType';
      }
    } else if (mealType != null) {
      queryParams = '?mealType=$mealType';
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl$foodEntriesEndpoint$queryParams'),
      headers: await _buildHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  // Delete food entry
  Future<void> deleteFoodEntry(String entryId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$foodEntriesEndpoint/$entryId'),
      headers: await _buildHeaders(),
    );
    
    _handleResponse(response);
  }
  
  // Logs APIs
  
  // Get logs (weight, water, exercise)
  Future<List<dynamic>> getLogs({String? type, String? startDate, String? endDate}) async {
    String queryParams = '';
    
    if (type != null) {
      queryParams = '?type=$type';
      if (startDate != null) {
        queryParams += '&startDate=$startDate';
      }
      if (endDate != null) {
        queryParams += '&endDate=$endDate';
      }
    } else if (startDate != null) {
      queryParams = '?startDate=$startDate';
      if (endDate != null) {
        queryParams += '&endDate=$endDate';
      }
    } else if (endDate != null) {
      queryParams = '?endDate=$endDate';
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl$logsEndpoint$queryParams'),
      headers: await _buildHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  // Add log entry (weight, water, exercise)
  Future<Map<String, dynamic>> addLogEntry(Map<String, dynamic> logData) async {
    final response = await http.post(
      Uri.parse('$baseUrl$logsEndpoint'),
      headers: await _buildHeaders(),
      body: json.encode(logData),
    );
    
    return _handleResponse(response);
  }
  
  // Delete log entry
  Future<void> deleteLogEntry(String logId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$logsEndpoint/$logId'),
      headers: await _buildHeaders(),
    );
    
    _handleResponse(response);
  }
  
  // Food search API
  Future<List<dynamic>> searchFoods(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl$searchFoodsEndpoint?query=$query'),
      headers: await _buildHeaders(),
    );
    
    return _handleResponse(response);
  }
} 