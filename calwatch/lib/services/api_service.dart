import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL for API
  static const String baseUrl = 'http://192.168.0.174:8000';
  
  // Djoser Authentication Endpoints
  static const String registerEndpoint = '/auth/users/';
  static const String loginEndpoint = '/auth/jwt/create/';
  static const String refreshTokenEndpoint = '/auth/jwt/refresh/';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String logoutEndpoint = '/auth/logout';
  
  // API Endpoints
  static const String userProfileEndpoint = '/api/user/profile';
  static const String nutritionDataEndpoint = '/api/nutrition/data';
  static const String foodEntriesEndpoint = '/api/food/entries';
  static const String logsEndpoint = '/api/logs';
  static const String searchFoodsEndpoint = '/api/food/search';
  
  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();
  
  // Get access token from shared preferences
  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
  
  // Get refresh token from shared preferences
  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }
  
  // Save JWT tokens to shared preferences
  Future<void> _saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }
  
  // Clear JWT tokens from shared preferences
  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
  
  // Headers builder with authorization
  Future<Map<String, String>> _buildHeaders({bool withAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (withAuth) {
      final token = await _getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'JWT $token';
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
      try {
        final error = json.decode(response.body);
        final errorMessage = error is Map ? 
          (error['detail'] ?? error['message'] ?? 'An error occurred') : 
          'An error occurred';
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception('An error occurred: ${response.statusCode}');
      }
    }
  }
  
  // Refresh access token using refresh token
  Future<bool> refreshAccessToken() async {
    final refreshToken = await _getRefreshToken();
    
    if (refreshToken == null) {
      return false;
    }
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$refreshTokenEndpoint'),
        headers: await _buildHeaders(withAuth: false),
        body: json.encode({
          'refresh': refreshToken,
        }),
      );
      
      final data = _handleResponse(response);
      if (data != null && data['access'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Authentication APIs
  
  // User registration
  Future<Map<String, dynamic>> signup(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl$registerEndpoint'),
      headers: await _buildHeaders(withAuth: false),
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
        're_password': password,
      }),
    );
    
    final data = _handleResponse(response);
    
    // After registration, immediately log in to get tokens
    if (data != null) {
      return await login(username, password);
    }
    
    return data;
  }
  
  // User login
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl$loginEndpoint'),
      headers: await _buildHeaders(withAuth: false),
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );
    
    final data = _handleResponse(response);
    if (data != null && data['access'] != null && data['refresh'] != null) {
      await _saveTokens(data['access'], data['refresh']);
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
    await _clearTokens();
  }
  
  // User Profile APIs
  
  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$userProfileEndpoint'),
        headers: await _buildHeaders(),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.get(
            Uri.parse('$baseUrl$userProfileEndpoint'),
            headers: await _buildHeaders(),
          );
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
  
  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$userProfileEndpoint'),
        headers: await _buildHeaders(),
        body: json.encode(profileData),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.post(
            Uri.parse('$baseUrl$userProfileEndpoint'),
            headers: await _buildHeaders(),
            body: json.encode(profileData),
          );
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
  
  // Nutrition and Food APIs
  
  // Get nutrition data (calories, macros, etc.)
  Future<Map<String, dynamic>> getNutritionData({String? date}) async {
    final dateParam = date != null ? '?date=$date' : '';
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$nutritionDataEndpoint$dateParam'),
        headers: await _buildHeaders(),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.get(
            Uri.parse('$baseUrl$nutritionDataEndpoint$dateParam'),
            headers: await _buildHeaders(),
          );
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
  
  // Add food entry
  Future<Map<String, dynamic>> addFoodEntry(Map<String, dynamic> foodData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$foodEntriesEndpoint'),
        headers: await _buildHeaders(),
        body: json.encode(foodData),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.post(
            Uri.parse('$baseUrl$foodEntriesEndpoint'),
            headers: await _buildHeaders(),
            body: json.encode(foodData),
          );
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
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
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$foodEntriesEndpoint$queryParams'),
        headers: await _buildHeaders(),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.get(
            Uri.parse('$baseUrl$foodEntriesEndpoint$queryParams'),
            headers: await _buildHeaders(),
          );
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete food entry
  Future<void> deleteFoodEntry(String entryId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$foodEntriesEndpoint/$entryId'),
        headers: await _buildHeaders(),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.delete(
            Uri.parse('$baseUrl$foodEntriesEndpoint/$entryId'),
            headers: await _buildHeaders(),
          );
          _handleResponse(retryResponse);
          return;
        }
      }
      
      _handleResponse(response);
    } catch (e) {
      rethrow;
    }
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
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$logsEndpoint$queryParams'),
        headers: await _buildHeaders(),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.get(
            Uri.parse('$baseUrl$logsEndpoint$queryParams'),
            headers: await _buildHeaders(),
          );
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
  
  // Add log entry (weight, water, exercise)
  Future<Map<String, dynamic>> addLogEntry(Map<String, dynamic> logData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$logsEndpoint'),
        headers: await _buildHeaders(),
        body: json.encode(logData),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.post(
            Uri.parse('$baseUrl$logsEndpoint'),
            headers: await _buildHeaders(),
            body: json.encode(logData),
          );
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete log entry
  Future<void> deleteLogEntry(String logId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$logsEndpoint/$logId'),
        headers: await _buildHeaders(),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.delete(
            Uri.parse('$baseUrl$logsEndpoint/$logId'),
            headers: await _buildHeaders(),
          );
          _handleResponse(retryResponse);
          return;
        }
      }
      
      _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
  
  // Food search API
  Future<List<dynamic>> searchFoods(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$searchFoodsEndpoint?query=$query'),
        headers: await _buildHeaders(),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.get(
            Uri.parse('$baseUrl$searchFoodsEndpoint?query=$query'),
            headers: await _buildHeaders(),
          );
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _getAccessToken();
    return token != null;
  }
} 