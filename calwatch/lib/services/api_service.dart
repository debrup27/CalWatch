import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ApiService {
  // Base URL for API
  static const String baseUrl = 'http://192.168.0.174:8000';
  
  // Djoser Authentication Endpoints
  static const String registerEndpoint = '/auth/users/';
  static const String loginEndpoint = '/auth/jwt/create/';
  static const String refreshTokenEndpoint = '/auth/jwt/refresh/';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  
  // API Endpoints
  static const String userProfileEndpoint = '/api/user/profile';
  static const String userMeEndpoint = '/users/me/';
  static const String userDetailsEndpoint = '/users/userDetails/';
  static const String userProfileUpdateEndpoint = '/users/profile/';
  static const String nutritionDataEndpoint = '/api/nutrition/data';
  static const String foodEntriesEndpoint = '/api/food/entries';
  static const String logsEndpoint = '/api/logs';
  static const String searchFoodsEndpoint = '/api/food/search';
  static const String dailyGoalEndpoint = '/food/dailyGoal/';
  static const String foodAutocompleteEndpoint = '/food/foodAutocomplete/';
  static const String getFoodEndpoint = '/food/getFood/';
  static const String addFoodEndpoint = '/food/addFood/';
  static const String waterIntakeEndpoint = '/food/waterIntake/';
  static const String listFoodEndpoint = '/food/listFood/';
  
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
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  // Handle API response
  dynamic _handleResponse(http.Response response) {
    final int statusCode = response.statusCode;
    
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isNotEmpty) {
        final dynamic responseData = json.decode(response.body);
        
        // Convert timestamps from GMT to local time
        if (responseData is Map<String, dynamic>) {
          return _convertTimestampsToLocal(responseData);
        } else if (responseData is List) {
          return responseData.map((item) {
            if (item is Map<String, dynamic>) {
              return _convertTimestampsToLocal(item);
            }
            return item;
          }).toList();
        }
        
        return responseData;
      }
      return null;
    } else if (statusCode == 401) {
      // Token expired or unauthorized
      throw Exception('Unauthorized: ${response.body}');
    } else {
      throw Exception('API Error: Status $statusCode - ${response.body}');
    }
  }
  
  // Convert timestamps in response from GMT to local time
  Map<String, dynamic> _convertTimestampsToLocal(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    
    // List of common timestamp field names
    final timestampFields = [
      'timestamp', 'created_at', 'updated_at', 'date', 
      'start_time', 'end_time', 'log_date', 'entry_date'
    ];
    
    // Process top-level timestamp fields
    for (final field in timestampFields) {
      if (result.containsKey(field) && result[field] != null) {
        final value = result[field];
        if (value is String) {
          try {
            final gmtTime = DateTime.parse(value);
            final localTime = gmtTime.toLocal();
            result[field] = localTime.toIso8601String();
          } catch (e) {
            print('Error parsing timestamp for field $field: $e');
          }
        }
      }
    }
    
    // Process nested objects
    _processNestedObjectsToLocal(result);
    
    return result;
  }
  
  // Process nested objects for GMT to local time conversion
  void _processNestedObjectsToLocal(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        data[key] = _convertTimestampsToLocal(value);
      } else if (value is List) {
        data[key] = _processTimestampsToLocal(value);
      }
    });
  }
  
  // Process timestamps in lists for GMT to local time conversion
  List _processTimestampsToLocal(List items) {
    return items.map((item) {
      if (item is Map<String, dynamic>) {
        return _convertTimestampsToLocal(item);
      }
      return item;
    }).toList();
  }
  
  // Convert timestamps in request to GMT
  Map<String, dynamic> _convertTimestampsToGMT(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    
    // List of common timestamp field names
    final timestampFields = [
      'timestamp', 'created_at', 'updated_at', 'date', 
      'start_time', 'end_time', 'log_date', 'entry_date'
    ];
    
    // Process top-level timestamp fields
    for (final field in timestampFields) {
      if (result.containsKey(field) && result[field] != null) {
        final value = result[field];
        if (value is String) {
          try {
            final localTime = DateTime.parse(value);
            final gmtTime = localTime.toUtc();
            result[field] = gmtTime.toIso8601String();
          } catch (e) {
            print('Error parsing timestamp for field $field: $e');
          }
        }
      }
    }
    
    // Process nested objects
    _processNestedObjectsToGMT(result);
    
    return result;
  }
  
  // Process nested objects for local time to GMT conversion
  void _processNestedObjectsToGMT(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        data[key] = _convertTimestampsToGMT(value);
      } else if (value is List) {
        data[key] = _processTimestampsToGMT(value);
      }
    });
  }
  
  // Process timestamps in lists for local time to GMT conversion
  List _processTimestampsToGMT(List items) {
    return items.map((item) {
      if (item is Map<String, dynamic>) {
        return _convertTimestampsToGMT(item);
      }
      return item;
    }).toList();
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
      // Convert timestamps to GMT
      final gmtFoodData = _convertTimestampsToGMT(foodData);
      
      final response = await http.post(
        Uri.parse('$baseUrl$foodEntriesEndpoint'),
        headers: await _buildHeaders(),
        body: json.encode(gmtFoodData),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.post(
            Uri.parse('$baseUrl$foodEntriesEndpoint'),
            headers: await _buildHeaders(),
            body: json.encode(gmtFoodData),
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
      // Convert timestamps to GMT
      final gmtLogData = _convertTimestampsToGMT(logData);
      
      final response = await http.post(
        Uri.parse('$baseUrl$logsEndpoint'),
        headers: await _buildHeaders(),
        body: json.encode(gmtLogData),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.post(
            Uri.parse('$baseUrl$logsEndpoint'),
            headers: await _buildHeaders(),
            body: json.encode(gmtLogData),
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
    print(token);
    return token != null;
  }

  // Get user details
  Future<Map<String, dynamic>> getUserDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$userDetailsEndpoint'),
        headers: await _buildHeaders(),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.get(
            Uri.parse('$baseUrl$userDetailsEndpoint'),
            headers: await _buildHeaders(),
          );
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      print('Error fetching user details: $e');
      rethrow;
    }
  }

  // Get daily goals from dedicated endpoint
  Future<Map<String, dynamic>> getDailyGoals() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$dailyGoalEndpoint'),
        headers: await _buildHeaders(),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.get(
            Uri.parse('$baseUrl$dailyGoalEndpoint'),
            headers: await _buildHeaders(),
          );
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      print('Error fetching daily goals: $e');
      // Return empty map instead of throwing to prevent UI crashes
      return {};
    }
  }
  
  // Update daily goals with nutrition values recommended by Padma
  Future<Map<String, dynamic>> updateDailyGoals(Map<String, dynamic> nutritionValues) async {
    try {
      print('Updating daily goals with data: $nutritionValues');
      final headers = await _buildHeaders();
      print('Request headers: $headers');
      
      // Convert timestamps to GMT
      final gmtNutritionValues = _convertTimestampsToGMT(nutritionValues);
      
      final requestBody = json.encode(gmtNutritionValues);
      print('Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl$dailyGoalEndpoint'),
        headers: headers,
        body: requestBody,
      );
      
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.post(
            Uri.parse('$baseUrl$dailyGoalEndpoint'),
            headers: await _buildHeaders(),
            body: requestBody,
          );
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      print('Error updating daily goals: $e');
      // Return empty map instead of throwing to prevent UI crashes
      return {};
    }
  }
  
  // Create user details (first time)
  Future<Map<String, dynamic>> createUserDetails(Map<String, dynamic> details) async {
    try {
      print('Creating user details with data: $details');
      final headers = await _buildHeaders();
      print('Request headers: $headers');
      
      // Convert timestamps to GMT
      final gmtDetails = _convertTimestampsToGMT(details);
      
      final requestBody = json.encode(gmtDetails);
      print('Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl$userDetailsEndpoint'),
        headers: headers,
        body: requestBody,
      );
      
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.post(
            Uri.parse('$baseUrl$userDetailsEndpoint'),
            headers: await _buildHeaders(),
            body: json.encode(gmtDetails),
          );
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      print('Error creating user details: $e');
      rethrow;
    }
  }
  
  // Update existing user details (from profile)
  Future<Map<String, dynamic>> updateUserDetails(Map<String, dynamic> details) async {
    try {
      // Convert timestamps to GMT
      final gmtDetails = _convertTimestampsToGMT(details);
      
      final response = await http.patch(
        Uri.parse('$baseUrl$userDetailsEndpoint'),
        headers: await _buildHeaders(),
        body: json.encode(gmtDetails),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.patch(
            Uri.parse('$baseUrl$userDetailsEndpoint'),
            headers: await _buildHeaders(),
            body: json.encode(gmtDetails),
          );
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      print('Error updating user details: $e');
      rethrow;
    }
  }
  
  // Update user profile (bio, profile image)
  Future<Map<String, dynamic>> updateUserProfileBio(Map<String, dynamic> profileData) async {
    try {
      // Convert timestamps to GMT
      final gmtProfileData = _convertTimestampsToGMT(profileData);
      
      // For profile image uploads, we would need to use multipart/form-data
      // This simplified version handles text-only updates
      final response = await http.patch(
        Uri.parse('$baseUrl$userProfileUpdateEndpoint'),
        headers: await _buildHeaders(),
        body: json.encode(gmtProfileData),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.patch(
            Uri.parse('$baseUrl$userProfileUpdateEndpoint'),
            headers: await _buildHeaders(),
            body: json.encode(gmtProfileData),
          );
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Get user me data (includes username, email, first_name, last_name, profile)
  Future<Map<String, dynamic>> getUserMe() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$userMeEndpoint'),
        headers: await _buildHeaders(),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.get(
            Uri.parse('$baseUrl$userMeEndpoint'),
            headers: await _buildHeaders(),
          );
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      print('Error fetching user me data: $e');
      rethrow;
    }
  }

  // Get food autocomplete suggestions
  Future<List<Map<String, dynamic>>> getFoodAutocomplete(String query) async {
    if (query.isEmpty) {
      return [];
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$foodAutocompleteEndpoint?q=$query'),
        headers: await _buildHeaders(),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.get(
            Uri.parse('$baseUrl$foodAutocompleteEndpoint?q=$query'),
            headers: await _buildHeaders(),
          );
          final data = _handleResponse(retryResponse);
          if (data != null && data['results'] != null) {
            return List<Map<String, dynamic>>.from(data['results']);
          }
        }
      }
      
      final data = _handleResponse(response);
      if (data != null && data['results'] != null) {
        return List<Map<String, dynamic>>.from(data['results']);
      }
      
      return [];
    } catch (e) {
      print('Error fetching food autocomplete: $e');
      return [];
    }
  }
  
  // Get food details by ID
  Future<Map<String, dynamic>> getFoodDetails(String foodId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$getFoodEndpoint?id=$foodId'),
        headers: await _buildHeaders(),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.get(
            Uri.parse('$baseUrl$getFoodEndpoint?id=$foodId'),
            headers: await _buildHeaders(),
          );
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      print('Error fetching food details: $e');
      rethrow;
    }
  }

  // Get food details with index as primary option, falling back to id
  Future<Map<String, dynamic>> getFoodDetailsWithIndexFallback(dynamic foodItem) async {
    try {
      // First try to use food_index if available
      if (foodItem['food_index'] != null) {
        print('Getting food details using index: ${foodItem['food_index']}');
        final response = await http.get(
          Uri.parse('$baseUrl$getFoodEndpoint?index=${foodItem['food_index']}'),
          headers: await _buildHeaders(),
        );
        
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return _handleResponse(response);
        }
      }
      
      // Fall back to food_id if index failed or isn't available
      if (foodItem['food_id'] != null) {
        print('Getting food details using id: ${foodItem['food_id']}');
        final response = await http.get(
          Uri.parse('$baseUrl$getFoodEndpoint?id=${foodItem['food_id']}'),
          headers: await _buildHeaders(),
        );
        
        if (response.statusCode == 401) {
          // Token expired, try to refresh
          final refreshed = await refreshAccessToken();
          if (refreshed) {
            // Retry with new token
            final retryResponse = await http.get(
              Uri.parse('$baseUrl$getFoodEndpoint?id=${foodItem['food_id']}'),
              headers: await _buildHeaders(),
            );
            return _handleResponse(retryResponse);
          }
        }
        
        return _handleResponse(response);
      }
      
      throw Exception('Neither food_index nor food_id available for food item');
    } catch (e) {
      print('Error fetching food details: $e');
      return {}; // Return empty map to avoid crashes
    }
  }

  // Add food consumption entry
  Future<Map<String, dynamic>> addFoodConsumption({
    String? foodId, 
    int? foodIndex,
    double? calories,
    double? protein,
    double? carbohydrates,
    double? fat
  }) async {
    try {
      // Prepare request body based on what's available
      final Map<String, dynamic> requestBody = {};
      
      if (foodId != null && foodId.isNotEmpty) {
        requestBody['food_id'] = foodId;
      } else if (foodIndex != null) {
        requestBody['food_index'] = foodIndex;
      } else {
        throw Exception('Either food_id or food_index must be provided');
      }
      
      // Add optional nutrition parameters if provided
      if (calories != null) requestBody['calories'] = calories;
      if (protein != null) requestBody['protein'] = protein;
      if (carbohydrates != null) requestBody['carbohydrates'] = carbohydrates;
      if (fat != null) requestBody['fat'] = fat;
      
      // Convert timestamps to GMT
      final gmtRequestBody = _convertTimestampsToGMT(requestBody);
      
      print('Adding food with request body: $gmtRequestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl$addFoodEndpoint'),
        headers: await _buildHeaders(),
        body: json.encode(gmtRequestBody),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.post(
            Uri.parse('$baseUrl$addFoodEndpoint'),
            headers: await _buildHeaders(),
            body: json.encode(gmtRequestBody),
          );
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      print('Error adding food consumption: $e');
      rethrow;
    }
  }

  // Get water intake history
  Future<List<Map<String, dynamic>>> getWaterIntake() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$waterIntakeEndpoint'),
        headers: await _buildHeaders(),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.get(
            Uri.parse('$baseUrl$waterIntakeEndpoint'),
            headers: await _buildHeaders(),
          );
          final data = _handleResponse(retryResponse);
          if (data is List) {
            return List<Map<String, dynamic>>.from(data);
          }
          return [];
        }
      }
      
      final data = _handleResponse(response);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Error fetching water intake: $e');
      return [];
    }
  }
  
  // Get water intake for a specific date
  Future<double> getWaterIntakeForDate(DateTime date) async {
    try {
      // Normalize the date to remove time component
      final targetDate = DateTime(date.year, date.month, date.day);
      
      final waterIntakeList = await getWaterIntake();
      
      double totalForDate = 0.0;
      for (final intake in waterIntakeList) {
        // Parse timestamp string to DateTime
        final timestamp = DateTime.parse(intake['timestamp'] as String);
        final intakeDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
        
        // Check if the intake is from the target date
        if (intakeDate.isAtSameMomentAs(targetDate)) {
          // Handle both int and double types safely
          final amount = intake['amount'];
          if (amount is int) {
            totalForDate += amount.toDouble();
          } else if (amount is double) {
            totalForDate += amount;
          } else {
            // Try to parse as double if it's a string
            totalForDate += double.tryParse(amount.toString()) ?? 0.0;
          }
        }
      }
      
      return totalForDate;
    } catch (e) {
      print('Error fetching water intake for date: $e');
      return 0.0;
    }
  }
  
  // Add water intake
  Future<Map<String, dynamic>> addWaterIntake(double amount) async {
    try {
      // Convert potential timestamp data to GMT
      final Map<String, dynamic> waterData = {'amount': amount};
      final gmtWaterData = _convertTimestampsToGMT(waterData);
      
      final response = await http.post(
        Uri.parse('$baseUrl$waterIntakeEndpoint'),
        headers: await _buildHeaders(),
        body: json.encode(gmtWaterData),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.post(
            Uri.parse('$baseUrl$waterIntakeEndpoint'),
            headers: await _buildHeaders(),
            body: json.encode(gmtWaterData),
          );
          return _handleResponse(retryResponse);
        }
      }
      
      return _handleResponse(response);
    } catch (e) {
      print('Error adding water intake: $e');
      rethrow;
    }
  }

  // Get food consumption logs by date range
  Future<List<Map<String, dynamic>>> getFoodLogs(DateTime startDate, DateTime endDate) async {
    // Format dates to YYYY-MM-DD
    final startDateStr = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final endDateStr = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$listFoodEndpoint?start_date=$startDateStr&end_date=$endDateStr'),
        headers: await _buildHeaders(),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.get(
            Uri.parse('$baseUrl$listFoodEndpoint?start_date=$startDateStr&end_date=$endDateStr'),
            headers: await _buildHeaders(),
          );
          final data = _handleResponse(retryResponse);
          if (data is List) {
            return List<Map<String, dynamic>>.from(data);
          }
          return [];
        }
      }
      
      final data = _handleResponse(response);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Error fetching food logs: $e');
      return [];
    }
  }

  // Get list of common food items
  Future<List<Map<String, dynamic>>> getFoodList({int limit = 20}) async {
    try {
      // Get list of predefined common foods - using a fixed date range for recent items
      // Using a wide date range to ensure we get enough results
      final today = DateTime.now().add(const Duration(days: 1)); // Include today
      final oneYearAgo = today.subtract(const Duration(days: 30));
      
      // Format dates to YYYY-MM-DD
      final startDateStr = '${oneYearAgo.year}-${oneYearAgo.month.toString().padLeft(2, '0')}-${oneYearAgo.day.toString().padLeft(2, '0')}';
      final endDateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      print('Fetching common foods from $startDateStr to $endDateStr');
      
      final response = await http.get(
        Uri.parse('$baseUrl$listFoodEndpoint?start_date=$startDateStr&end_date=$endDateStr'),
        headers: await _buildHeaders(),
      );
      
      if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          // Retry with new token
          final retryResponse = await http.get(
            Uri.parse('$baseUrl$listFoodEndpoint?start_date=$startDateStr&end_date=$endDateStr'),
            headers: await _buildHeaders(),
          );
          final data = _handleResponse(retryResponse);
          if (data is List) {
            // Limit and filter the results to get unique foods
            final foods = List<Map<String, dynamic>>.from(data);
            return _getUniqueFoods(foods, limit);
          }
          return [];
        }
      }
      
      final data = _handleResponse(response);
      if (data is List) {
        // Limit and filter the results to get unique foods
        final foods = List<Map<String, dynamic>>.from(data);
        return _getUniqueFoods(foods, limit);
      }
      return [];
    } catch (e) {
      print('Error fetching food list: $e');
      return [];
    }
  }

  // Helper method to get unique foods by name and limit results
  List<Map<String, dynamic>> _getUniqueFoods(List<Map<String, dynamic>> foods, int limit) {
    // Use a set to track seen food names
    final Set<String> seenFoodNames = {};
    final List<Map<String, dynamic>> uniqueFoods = [];
    
    for (final food in foods) {
      final name = food['food_name'] ?? '';
      if (name.isNotEmpty && !seenFoodNames.contains(name)) {
        seenFoodNames.add(name);
        uniqueFoods.add(food);
        
        // Stop when we have enough unique foods
        if (uniqueFoods.length >= limit) {
          break;
        }
      }
    }
    
    return uniqueFoods;
  }

  // Get all daily data for a specific date
  Future<Map<String, dynamic>> getDailyData(DateTime date) async {
    // Get date for the next day since end date is exclusive
    final nextDate = date.add(const Duration(days: 1));
    
    try {
      // Fetch daily goals
      final dailyGoals = await getDailyGoals();
      
      // Fetch food logs for the specific date
      final foodLogs = await getFoodLogs(date, nextDate);
      
      // Fetch water intake for the specific date
      final waterIntake = await getWaterIntakeForDate(date);
      
      // Process food logs
      final timeFormat = DateFormat('h:mm a');
      final dayFoodEntries = <Map<String, dynamic>>[];
      
      // Calculate consumed nutrition values
      double caloriesConsumed = 0.0;
      double proteinConsumed = 0.0;
      double carbsConsumed = 0.0;
      double fatConsumed = 0.0;
      
      for (final log in foodLogs) {
        final timestamp = DateTime.parse(log['timestamp'] as String);
        // Add formatted time to the log
        log['formatted_time'] = timeFormat.format(timestamp);
        
        // Add to food entries for display
        dayFoodEntries.add(log);
        
        // Sum up nutrients
        caloriesConsumed += (log['calories'] as num?)?.toDouble() ?? 0.0;
        proteinConsumed += (log['protein'] as num?)?.toDouble() ?? 0.0;
        carbsConsumed += (log['carbohydrates'] as num?)?.toDouble() ?? 0.0;
        fatConsumed += (log['fat'] as num?)?.toDouble() ?? 0.0;
      }
      
      // Sort food entries by timestamp (newest first)
      dayFoodEntries.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return bTime.compareTo(aTime);
      });
      
      // Create nutrition data structure
      final nutritionData = {
        'calories': {
          'consumed': caloriesConsumed,
          'goal': dailyGoals['calories']?.toDouble() ?? 2000.0,
        },
        'protein': {
          'consumed': proteinConsumed,
          'goal': dailyGoals['protein']?.toDouble() ?? 50.0,
        },
        'carbohydrates': {
          'consumed': carbsConsumed,
          'goal': dailyGoals['carbohydrates']?.toDouble() ?? 250.0,
        },
        'fat': {
          'consumed': fatConsumed,
          'goal': dailyGoals['fat']?.toDouble() ?? 70.0,
        },
      };
      
      return {
        'nutritionData': nutritionData,
        'foodEntries': dayFoodEntries,
        'waterIntake': waterIntake,
      };
    } catch (e) {
      print('Error fetching daily data: $e');
      // Return empty data structure in case of error
      return {
        'nutritionData': {
          'calories': {'consumed': 0.0, 'goal': 2000.0},
          'protein': {'consumed': 0.0, 'goal': 50.0},
          'carbohydrates': {'consumed': 0.0, 'goal': 250.0},
          'fat': {'consumed': 0.0, 'goal': 70.0},
        },
        'foodEntries': [],
        'waterIntake': 0.0,
      };
    }
  }

  // Calculate 7-day average micronutrient consumption
  Future<Map<String, double>> get7DayMicronutrientAverages() async {
    try {
      // Define recommended daily values (RDV) for micronutrients
      final Map<String, double> recommendedDailyValues = {
        'Vitamin A': 900.0, // in mcg (ug)
        'Vitamin C': 90.0,  // in mg
        'Calcium': 1000.0,  // in mg
        'Iron': 8.0,        // in mg
        'Potassium': 3500.0 // in mg
      };
      
      // Initialize totals map
      final Map<String, double> totalMicronutrients = {
        'Vitamin A': 0.0,
        'Vitamin C': 0.0,
        'Calcium': 0.0,
        'Iron': 0.0,
        'Potassium': 0.0
      };
      
      // Get today's date and date 7 days ago
      final today = DateTime.now();
      final sevenDaysAgo = today.subtract(const Duration(days: 7));
      
      // Get food logs for the last 7 days
      final foodLogs = await getFoodLogs(sevenDaysAgo, today.add(const Duration(days: 1)));
      
      if (foodLogs.isEmpty) {
        print('No food logs found for the last 7 days');
        return {
          'Vitamin A': 0.0,
          'Vitamin C': 0.0,
          'Calcium': 0.0,
          'Iron': 0.0,
          'Potassium': 0.0
        };
      }
      
      print('Found ${foodLogs.length} food logs for the last 7 days');
      
      // Process each food log to get its detailed nutritional information
      for (final foodLog in foodLogs) {
        try {
          // Get detailed food info using the index first, then id as fallback
          final foodDetails = await getFoodDetailsWithIndexFallback(foodLog);
          
          if (foodDetails.isEmpty) {
            print('No details found for food: ${foodLog['food_name']}');
            continue;
          }
          
          // Parse the micronutrient values
          // The keys we're looking for in the API response
          final double vitaminA = _parseNutrientValue(foodDetails['vita_ug']);
          final double vitaminC = _parseNutrientValue(foodDetails['vitc_mg']);
          final double calcium = _parseNutrientValue(foodDetails['calcium_mg']);
          final double iron = _parseNutrientValue(foodDetails['iron_mg']);
          final double potassium = _parseNutrientValue(foodDetails['potassium_mg']);
          
          // Add to totals
          totalMicronutrients['Vitamin A'] = totalMicronutrients['Vitamin A']! + vitaminA;
          totalMicronutrients['Vitamin C'] = totalMicronutrients['Vitamin C']! + vitaminC;
          totalMicronutrients['Calcium'] = totalMicronutrients['Calcium']! + calcium;
          totalMicronutrients['Iron'] = totalMicronutrients['Iron']! + iron;
          totalMicronutrients['Potassium'] = totalMicronutrients['Potassium']! + potassium;
          
        } catch (e) {
          print('Error processing food log: $e');
          continue; // Skip this food item and continue with the next
        }
      }
      
      // Calculate daily averages
      final Map<String, double> averagePercentages = {};
      
      for (final nutrient in totalMicronutrients.keys) {
        // Calculate the daily average amount
        final double dailyAverage = totalMicronutrients[nutrient]! / 7.0;
        
        // Calculate the percentage of the RDV
        final double percentage = (dailyAverage / recommendedDailyValues[nutrient]!) * 100;
        
        // Cap at 200% for visual purposes
        averagePercentages[nutrient] = percentage > 200 ? 200 : percentage;
      }
      
      return averagePercentages;
    } catch (e) {
      print('Error calculating micronutrient averages: $e');
      // Return default values in case of error
      return {
        'Vitamin A': 0.0,
        'Vitamin C': 0.0,
        'Calcium': 0.0,
        'Iron': 0.0,
        'Potassium': 0.0
      };
    }
  }
  
  // Helper method to parse nutrient values that could be strings, nulls, etc.
  double _parseNutrientValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing nutrient value "$value": $e');
        return 0.0;
      }
    }
    return 0.0;
  }
} 