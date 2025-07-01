import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/patient.dart';
import '../models/omron_data.dart';

enum ApiEnvironment {
  development,
  staging,
  production,
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final Map<String, dynamic>? details;

  ApiException(
    this.message, {
    this.statusCode,
    this.errorCode,
    this.details,
  });

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode, Code: $errorCode)';
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? errorCode;
  final Map<String, dynamic>? metadata;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errorCode,
    this.metadata,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJson) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] != null && fromJson != null ? fromJson(json['data']) : json['data'],
      message: json['message'],
      errorCode: json['error_code'],
      metadata: json['metadata'],
    );
  }
}

class PaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final List<dynamic> items = json['data'] ?? [];
    return PaginatedResponse<T>(
      data: items.map((item) => fromJson(item as Map<String, dynamic>)).toList(),
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      totalItems: json['total_items'] ?? 0,
      itemsPerPage: json['items_per_page'] ?? 10,
      hasNextPage: json['has_next_page'] ?? false,
      hasPreviousPage: json['has_previous_page'] ?? false,
    );
  }
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Configuration
  static const Map<ApiEnvironment, String> _baseUrls = {
    ApiEnvironment.development: 'http://localhost:3000/api/v1',
    ApiEnvironment.staging: 'https://staging-api.omronapp.com/api/v1',
    ApiEnvironment.production: 'https://api.omronapp.com/api/v1',
  };

  ApiEnvironment _currentEnvironment = ApiEnvironment.development;
  String? _authToken;
  String? _refreshToken;
  String? _deviceId;
  
  // HTTP Client with timeout
  late http.Client _client;
  static const Duration _defaultTimeout = Duration(seconds: 30);

  // Preferences keys
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _deviceIdKey = 'device_id';
  static const String _environmentKey = 'api_environment';

  String get baseUrl => _baseUrls[_currentEnvironment]!;
  bool get isAuthenticated => _authToken != null;

  /// Initialize API service
  Future<void> initialize({ApiEnvironment? environment}) async {
    _client = http.Client();
    
    if (environment != null) {
      _currentEnvironment = environment;
    }
    
    await _loadStoredCredentials();
    await _generateDeviceId();
  }

  /// Load stored credentials from SharedPreferences
  Future<void> _loadStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_authTokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
    _deviceId = prefs.getString(_deviceIdKey);
    
    final envString = prefs.getString(_environmentKey);
    if (envString != null) {
      _currentEnvironment = ApiEnvironment.values.firstWhere(
        (e) => e.toString() == envString,
        orElse: () => ApiEnvironment.development,
      );
    }
  }

  /// Generate or load device ID
  Future<void> _generateDeviceId() async {
    if (_deviceId == null) {
      final prefs = await SharedPreferences.getInstance();
      _deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString(_deviceIdKey, _deviceId!);
    }
  }

  /// Save credentials to SharedPreferences
  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_authToken != null) {
      await prefs.setString(_authTokenKey, _authToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString(_refreshTokenKey, _refreshToken!);
    }
    await prefs.setString(_environmentKey, _currentEnvironment.toString());
  }

  /// Get default headers
  Map<String, String> get _defaultHeaders {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Device-ID': _deviceId ?? '',
      'X-App-Version': '1.0.0',
      'X-Platform': Platform.isAndroid ? 'android' : 'ios',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// Make HTTP request with error handling and retry logic
  Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
    int retryCount = 0,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = {..._defaultHeaders, ...?headers};
    final requestTimeout = timeout ?? _defaultTimeout;

    http.Response response;

    try {
      switch (method.toLowerCase()) {
        case 'get':
          response = await _client.get(uri, headers: requestHeaders)
              .timeout(requestTimeout);
          break;
        case 'post':
          response = await _client.post(
            uri,
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          ).timeout(requestTimeout);
          break;
        case 'put':
          response = await _client.put(
            uri,
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          ).timeout(requestTimeout);
          break;
        case 'patch':
          response = await _client.patch(
            uri,
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          ).timeout(requestTimeout);
          break;
        case 'delete':
          response = await _client.delete(uri, headers: requestHeaders)
              .timeout(requestTimeout);
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }

      return await _handleResponse(response, method, endpoint, body: body, retryCount: retryCount);
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet');
    } on TimeoutException {
      throw ApiException('Request timeout - server tidak merespons');
    } on FormatException {
      throw ApiException('Format response tidak valid');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  /// Handle HTTP response and errors with token refresh
  Future<http.Response> _handleResponse(
    http.Response response, 
    String method, 
    String endpoint, {
    Map<String, dynamic>? body,
    int retryCount = 0,
  }) async {
    switch (response.statusCode) {
      case 200:
      case 201:
      case 202:
        return response;
      case 401:
        // Try to refresh token only once per request
        if (_refreshToken != null && retryCount == 0) {
          final refreshed = await _refreshAuthToken();
          if (refreshed) {
            // Retry original request with new token
            return await _makeRequest(method, endpoint, body: body, retryCount: retryCount + 1);
          }
        }
        
        await _clearCredentials();
        throw ApiException(
          'Session expired - please login again',
          statusCode: 401,
          errorCode: 'UNAUTHORIZED',
        );
      case 403:
        throw ApiException(
          'Access forbidden',
          statusCode: 403,
          errorCode: 'FORBIDDEN',
        );
      case 404:
        throw ApiException(
          'Resource not found',
          statusCode: 404,
          errorCode: 'NOT_FOUND',
        );
      case 422:
        final errorBody = _parseErrorBody(response.body);
        throw ApiException(
          errorBody['message'] ?? 'Validation error',
          statusCode: 422,
          errorCode: 'VALIDATION_ERROR',
          details: errorBody['errors'],
        );
      case 429:
        throw ApiException(
          'Too many requests - please wait',
          statusCode: 429,
          errorCode: 'RATE_LIMITED',
        );
      case 500:
        throw ApiException(
          'Server error - please try again later',
          statusCode: 500,
          errorCode: 'SERVER_ERROR',
        );
      default:
        final errorBody = _parseErrorBody(response.body);
        throw ApiException(
          errorBody['message'] ?? 'Unknown error occurred',
          statusCode: response.statusCode,
          errorCode: errorBody['error_code'],
        );
    }
  }

  /// Parse error response body
  Map<String, dynamic> _parseErrorBody(String body) {
    try {
      return json.decode(body);
    } catch (e) {
      return {'message': 'Failed to parse error response'};
    }
  }

  /// Refresh authentication token
  Future<bool> _refreshAuthToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_refreshToken',
        },
        body: json.encode({'refresh_token': _refreshToken}),
      ).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _authToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        await _saveCredentials();
        return true;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }

    return false;
  }

  /// Clear stored credentials
  Future<void> _clearCredentials() async {
    _authToken = null;
    _refreshToken = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  // ==================== AUTH ENDPOINTS ====================

  /// Login user
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    final response = await _makeRequest('POST', '/auth/login', body: {
      'email': email,
      'password': password,
      'device_id': _deviceId,
    });

    final data = json.decode(response.body);
    
    if (data['success'] == true) {
      _authToken = data['data']['access_token'];
      _refreshToken = data['data']['refresh_token'];
      await _saveCredentials();
    }

    return ApiResponse.fromJson(data, (json) => json);
  }

  /// Register user
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    final response = await _makeRequest('POST', '/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'phone_number': phoneNumber,
      'device_id': _deviceId,
    });

    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, (json) => json);
  }

  /// Logout user
  Future<ApiResponse<void>> logout() async {
    try {
      await _makeRequest('POST', '/auth/logout');
    } catch (e) {
      // Continue with local logout even if server request fails
      debugPrint('Logout request failed: $e');
    }

    await _clearCredentials();
    return ApiResponse(success: true, message: 'Logged out successfully');
  }

  // ==================== PATIENT ENDPOINTS ====================

  /// Get all patients with pagination
  Future<PaginatedResponse<Patient>> getPatients({
    int page = 1,
    int limit = 20,
    String? search,
    String? sortBy,
    String? sortOrder,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (sortBy != null && sortBy.isNotEmpty) queryParams['sort_by'] = sortBy;
    if (sortOrder != null && sortOrder.isNotEmpty) queryParams['sort_order'] = sortOrder;

    final uri = Uri.parse('$baseUrl/patients').replace(queryParameters: queryParams);
    final response = await _client.get(uri, headers: _defaultHeaders).timeout(_defaultTimeout);
    final handledResponse = await _handleResponse(response, 'GET', '/patients');

    final data = json.decode(handledResponse.body);
    return PaginatedResponse.fromJson(data, (json) => Patient.fromJson(json));
  }

  /// Get patient by ID
  Future<ApiResponse<Patient>> getPatient(int id) async {
    final response = await _makeRequest('GET', '/patients/$id');
    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, (json) => Patient.fromJson(json));
  }

  /// Get patient by WhatsApp number
  Future<ApiResponse<Patient>> getPatientByWhatsApp(String whatsappNumber) async {
    final encodedNumber = Uri.encodeComponent(whatsappNumber);
    final response = await _makeRequest('GET', '/patients/whatsapp/$encodedNumber');
    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, (json) => Patient.fromJson(json));
  }

  /// Create new patient
  Future<ApiResponse<Patient>> createPatient(Patient patient) async {
    final response = await _makeRequest('POST', '/patients', body: patient.toJson());
    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, (json) => Patient.fromJson(json));
  }

  /// Update patient
  Future<ApiResponse<Patient>> updatePatient(Patient patient) async {
    if (patient.id == null) {
      throw ApiException('Patient ID is required for update');
    }
    final response = await _makeRequest('PUT', '/patients/${patient.id}', body: patient.toJson());
    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, (json) => Patient.fromJson(json));
  }

  /// Delete patient
  Future<ApiResponse<void>> deletePatient(int id) async {
    final response = await _makeRequest('DELETE', '/patients/$id');
    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, null);
  }

  /// Bulk create patients
  Future<ApiResponse<Map<String, dynamic>>> bulkCreatePatients(List<Patient> patients) async {
    final response = await _makeRequest('POST', '/patients/bulk', body: {
      'patients': patients.map((p) => p.toJson()).toList(),
    });
    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, (json) => json);
  }

  // ==================== OMRON DATA ENDPOINTS ====================

  /// Get all Omron data with pagination
  Future<PaginatedResponse<OmronData>> getOmronData({
    int page = 1,
    int limit = 20,
    String? patientName,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    String? sortOrder,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (patientName != null && patientName.isNotEmpty) queryParams['patient_name'] = patientName;
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
    if (sortBy != null && sortBy.isNotEmpty) queryParams['sort_by'] = sortBy;
    if (sortOrder != null && sortOrder.isNotEmpty) queryParams['sort_order'] = sortOrder;

    final uri = Uri.parse('$baseUrl/omron-data').replace(queryParameters: queryParams);
    final response = await _client.get(uri, headers: _defaultHeaders).timeout(_defaultTimeout);
    final handledResponse = await _handleResponse(response, 'GET', '/omron-data');

    final data = json.decode(handledResponse.body);
    return PaginatedResponse.fromJson(data, (json) => OmronData.fromMap(json));
  }

  /// Get Omron data by ID
  Future<ApiResponse<OmronData>> getOmronDataById(int id) async {
    final response = await _makeRequest('GET', '/omron-data/$id');
    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, (json) => OmronData.fromMap(json));
  }

  /// Create new Omron data
  Future<ApiResponse<OmronData>> createOmronData(OmronData omronData) async {
    final response = await _makeRequest('POST', '/omron-data', body: omronData.toMap());
    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, (json) => OmronData.fromMap(json));
  }

  /// Update Omron data
  Future<ApiResponse<OmronData>> updateOmronData(OmronData omronData) async {
    if (omronData.id == null) {
      throw ApiException('Omron data ID is required for update');
    }
    final response = await _makeRequest('PUT', '/omron-data/${omronData.id}', body: omronData.toMap());
    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, (json) => OmronData.fromMap(json));
  }

  /// Delete Omron data
  Future<ApiResponse<void>> deleteOmronData(int id) async {
    final response = await _makeRequest('DELETE', '/omron-data/$id');
    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, null);
  }

  /// Bulk upload Omron data
  Future<ApiResponse<Map<String, dynamic>>> bulkUploadOmronData(List<OmronData> dataList) async {
    final response = await _makeRequest('POST', '/omron-data/bulk', body: {
      'data': dataList.map((data) => data.toMap()).toList(),
    });
    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, (json) => json);
  }

  /// Get Omron data by patient
  Future<PaginatedResponse<OmronData>> getOmronDataByPatient({
    required String patientName,
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await getOmronData(
      page: page,
      limit: limit,
      patientName: patientName,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // ==================== ANALYTICS ENDPOINTS ====================

  /// Get analytics data
  Future<ApiResponse<Map<String, dynamic>>> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? patientName,
  }) async {
    final queryParams = <String, String>{};
    
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
    if (patientName != null && patientName.isNotEmpty) queryParams['patient_name'] = patientName;

    final uri = Uri.parse('$baseUrl/analytics').replace(queryParameters: queryParams);
    final response = await _client.get(uri, headers: _defaultHeaders).timeout(_defaultTimeout);
    final handledResponse = await _handleResponse(response, 'GET', '/analytics');

    final data = json.decode(handledResponse.body);
    return ApiResponse.fromJson(data, (json) => json);
  }

  /// Get patient analytics
  Future<ApiResponse<Map<String, dynamic>>> getPatientAnalytics(String patientName) async {
    final encodedName = Uri.encodeComponent(patientName);
    final response = await _makeRequest('GET', '/analytics/patient/$encodedName');
    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, (json) => json);
  }

  // ==================== WHATSAPP ENDPOINTS ====================

  /// Send WhatsApp message
  Future<ApiResponse<Map<String, dynamic>>> sendWhatsAppMessage({
    required String phoneNumber,
    required String message,
    String? templateName,
    Map<String, dynamic>? templateData,
  }) async {
    final response = await _makeRequest('POST', '/whatsapp/send', body: {
      'phone_number': phoneNumber,
      'message': message,
      'template_name': templateName,
      'template_data': templateData,
    });

    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, (json) => json);
  }

  /// Get WhatsApp message status
  Future<ApiResponse<Map<String, dynamic>>> getWhatsAppStatus(String messageId) async {
    final response = await _makeRequest('GET', '/whatsapp/status/$messageId');
    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, (json) => json);
  }

  /// Send Omron report via WhatsApp
  Future<ApiResponse<Map<String, dynamic>>> sendOmronReport({
    required int omronDataId,
    required String phoneNumber,
    String? customMessage,
  }) async {
    final response = await _makeRequest('POST', '/whatsapp/send-report', body: {
      'omron_data_id': omronDataId,
      'phone_number': phoneNumber,
      'custom_message': customMessage,
    });

    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, (json) => json);
  }

  // ==================== SYNC ENDPOINTS ====================

  /// Sync data with server
  Future<ApiResponse<Map<String, dynamic>>> syncData({
    List<Patient>? patients,
    List<OmronData>? omronData,
    DateTime? lastSyncTime,
  }) async {
    final response = await _makeRequest('POST', '/sync', body: {
      'patients': patients?.map((p) => p.toJson()).toList(),
      'omron_data': omronData?.map((d) => d.toMap()).toList(),
      'last_sync_time': lastSyncTime?.toIso8601String(),
    });

    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, (json) => json);
  }

  /// Get sync status
  Future<ApiResponse<Map<String, dynamic>>> getSyncStatus() async {
    final response = await _makeRequest('GET', '/sync/status');
    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, (json) => json);
  }

  // ==================== UTILITY METHODS ====================

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      final response = await _makeRequest('GET', '/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get server info
  Future<ApiResponse<Map<String, dynamic>>> getServerInfo() async {
    try {
      final response = await _makeRequest('GET', '/info');
      final data = json.decode(response.body);
      return ApiResponse.fromJson(data, (json) => json);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to get server info: $e',
      );
    }
  }

  /// Set API environment
  Future<void> setEnvironment(ApiEnvironment environment) async {
    _currentEnvironment = environment;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_environmentKey, environment.toString());
  }

  /// Get current environment
  ApiEnvironment getCurrentEnvironment() => _currentEnvironment;

  /// Get current user info
  Future<ApiResponse<Map<String, dynamic>>> getCurrentUser() async {
    if (!isAuthenticated) {
      return ApiResponse(
        success: false,
        message: 'User not authenticated',
        errorCode: 'NOT_AUTHENTICATED',
      );
    }

    try {
      final response = await _makeRequest('GET', '/auth/me');
      final data = json.decode(response.body);
      return ApiResponse.fromJson(data, (json) => json);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to get user info: $e',
      );
    }
  }

  /// Update user profile
  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    String? name,
    String? email,
    String? phoneNumber,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;

    final response = await _makeRequest('PUT', '/auth/profile', body: body);
    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, (json) => json);
  }

  /// Change password
  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _makeRequest('PUT', '/auth/password', body: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
    final data = json.decode(response.body);
    return ApiResponse.fromJson(data, null);
  }

  /// Get API usage statistics
  Future<ApiResponse<Map<String, dynamic>>> getApiUsageStats() async {
    try {
      final response = await _makeRequest('GET', '/stats/usage');
      final data = json.decode(response.body);
      return ApiResponse.fromJson(data, (json) => json);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to get usage stats: $e',
      );
    }
  }

  /// Set custom base URL (for testing)
  void setCustomBaseUrl(String url) {
    // For testing purposes - would need to modify implementation
    // This is a placeholder for custom URL functionality
    debugPrint('Custom base URL set to: $url');
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _clearCredentials();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Get connection status
  Future<Map<String, dynamic>> getConnectionStatus() async {
    try {
      final stopwatch = Stopwatch()..start();
      final isConnected = await testConnection();
      stopwatch.stop();
      
      return {
        'connected': isConnected,
        'response_time': stopwatch.elapsedMilliseconds,
        'environment': _currentEnvironment.toString(),
        'base_url': baseUrl,
        'authenticated': isAuthenticated,
      };
    } catch (e) {
      return {
        'connected': false,
        'error': e.toString(),
        'environment': _currentEnvironment.toString(),
        'base_url': baseUrl,
        'authenticated': isAuthenticated,
      };
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
