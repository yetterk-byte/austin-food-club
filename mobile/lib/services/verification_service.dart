import 'dart:convert';
import 'package:http/http.dart' as http;

class VerificationService {
  static const String _baseUrl = 'https://api.austinfoodclub.com/api/verification';
  
  /// Send verification code to phone number
  static Future<Map<String, dynamic>> sendVerificationCode(String phone) async {
    try {
      print('📡 VerificationService: Sending request to $_baseUrl/send-code');
      print('📡 VerificationService: Phone number: $phone');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/send-code'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': phone,
        }),
      );

      print('📡 VerificationService: Response status code: ${response.statusCode}');
      print('📡 VerificationService: Response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ VerificationService: Success response received');
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        print('❌ VerificationService: Error response: ${data['message']}');
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to send verification code',
        };
      }
    } catch (e) {
      print('❌ VerificationService: Exception caught: $e');
      print('❌ VerificationService: Exception type: ${e.runtimeType}');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Verify code and create/login user
  static Future<Map<String, dynamic>> verifyCode({
    required String phone,
    required String code,
    String? name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verify-code'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': phone,
          'code': code,
          if (name != null) 'name': name,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to verify code',
          'errorCode': data['error'],
          'attemptsRemaining': data['attemptsRemaining'],
        };
      }
    } catch (e) {
      print('❌ VerificationService: Error verifying code: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Check verification status (for debugging)
  static Future<Map<String, dynamic>> checkStatus(String phone) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/status/$phone'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to check status',
        };
      }
    } catch (e) {
      print('❌ VerificationService: Error checking status: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}
