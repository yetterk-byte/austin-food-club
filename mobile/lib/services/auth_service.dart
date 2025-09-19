import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/user.dart';

class AuthService {
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';
  static const String _isLoggedInKey = 'is_logged_in';

  // Mock users database
  static final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': '1',
      'email': 'kenny@austinfoodclub.com',
      'phone': '+1 (512) 555-0123',
      'name': 'Kenny Yetter',
      'avatar': null,
      'password': _hashPassword('password123'),
      'createdAt': DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
      'lastLoginAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'isVerified': true,
      'preferences': {
        'notifications': true,
        'newsletter': true,
        'theme': 'dark',
      },
    },
    {
      'id': '2',
      'email': 'demo@austinfoodclub.com',
      'phone': '+1 (512) 555-0456',
      'name': 'Demo User',
      'avatar': null,
      'password': _hashPassword('demo123'),
      'createdAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      'lastLoginAt': null,
      'isVerified': false,
      'preferences': null,
    },
  ];

  /// Hash password for storage (simple implementation for demo)
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'austin_food_club_salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate a mock JWT token
  static String _generateToken(String userId) {
    final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
    final payload = base64Url.encode(utf8.encode('{"sub":"$userId","exp":${DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch},"iat":${DateTime.now().millisecondsSinceEpoch}}'));
    final signature = base64Url.encode(utf8.encode('mock_signature_${Random().nextInt(10000)}'));
    return '$header.$payload.$signature';
  }

  /// Sign in with email and password
  static Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      final hashedPassword = _hashPassword(password);
      final userData = _mockUsers.firstWhere(
        (user) => user['email'] == email && user['password'] == hashedPassword,
        orElse: () => {},
      );

      if (userData.isEmpty) {
        return AuthResult.error('Invalid email or password');
      }

      // Update last login
      userData['lastLoginAt'] = DateTime.now().toIso8601String();

      final user = User.fromJson(userData);
      final token = _generateToken(user.id);

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      await prefs.setString(_tokenKey, token);
      await prefs.setBool(_isLoggedInKey, true);

      return AuthResult.success(user, token);
    } catch (e) {
      return AuthResult.error('Sign in failed: ${e.toString()}');
    }
  }

  /// Sign in with phone number (OTP simulation)
  static Future<AuthResult> signInWithPhone(String phone) async {
    try {
      // Simulate sending OTP
      await Future.delayed(const Duration(seconds: 1));

      // For demo, we'll just check if phone exists in our mock users
      final userData = _mockUsers.firstWhere(
        (user) => user['phone'] == phone,
        orElse: () => {},
      );

      if (userData.isEmpty) {
        return AuthResult.error('Phone number not found');
      }

      // In a real app, you would send an OTP here
      // For demo, we'll return a success with a mock OTP
      return AuthResult.otpSent(phone, '123456'); // Mock OTP
    } catch (e) {
      return AuthResult.error('Phone sign in failed: ${e.toString()}');
    }
  }

  /// Verify OTP (simulation)
  static Future<AuthResult> verifyOTP(String phone, String otp) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // For demo, accept any 6-digit OTP
      if (otp.length != 6) {
        return AuthResult.error('Invalid OTP format');
      }

      final userData = _mockUsers.firstWhere(
        (user) => user['phone'] == phone,
        orElse: () => {},
      );

      if (userData.isEmpty) {
        return AuthResult.error('Phone number not found');
      }

      // Update last login
      userData['lastLoginAt'] = DateTime.now().toIso8601String();

      final user = User.fromJson(userData);
      final token = _generateToken(user.id);

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      await prefs.setString(_tokenKey, token);
      await prefs.setBool(_isLoggedInKey, true);

      return AuthResult.success(user, token);
    } catch (e) {
      return AuthResult.error('OTP verification failed: ${e.toString()}');
    }
  }

  /// Sign up with email and password
  static Future<AuthResult> signUpWithEmail(String email, String password, String name) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Check if email already exists
      final existingUser = _mockUsers.where((user) => user['email'] == email);
      if (existingUser.isNotEmpty) {
        return AuthResult.error('Email already registered');
      }

      // Create new user
      final newUser = {
        'id': (DateTime.now().millisecondsSinceEpoch % 10000).toString(),
        'email': email,
        'phone': null,
        'name': name,
        'avatar': null,
        'password': _hashPassword(password),
        'createdAt': DateTime.now().toIso8601String(),
        'lastLoginAt': DateTime.now().toIso8601String(),
        'isVerified': false,
        'preferences': {
          'notifications': true,
          'newsletter': false,
          'theme': 'dark',
        },
      };

      _mockUsers.add(newUser);

      final user = User.fromJson(newUser);
      final token = _generateToken(user.id);

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      await prefs.setString(_tokenKey, token);
      await prefs.setBool(_isLoggedInKey, true);

      return AuthResult.success(user, token);
    } catch (e) {
      return AuthResult.error('Sign up failed: ${e.toString()}');
    }
  }

  /// Get current user from local storage
  static Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        return User.fromJson(jsonDecode(userJson));
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
    return null;
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get current auth token
  static Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_tokenKey);
      await prefs.setBool(_isLoggedInKey, false);
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Update user profile
  static Future<AuthResult> updateProfile(User user) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Update in mock database
      final userIndex = _mockUsers.indexWhere((u) => u['id'] == user.id);
      if (userIndex != -1) {
        _mockUsers[userIndex] = user.toJson();
        
        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(user.toJson()));
        
        return AuthResult.success(user, await getAuthToken() ?? '');
      } else {
        return AuthResult.error('User not found');
      }
    } catch (e) {
      return AuthResult.error('Profile update failed: ${e.toString()}');
    }
  }

  /// Reset password (email)
  static Future<AuthResult> resetPassword(String email) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      final userData = _mockUsers.where((user) => user['email'] == email);
      if (userData.isEmpty) {
        return AuthResult.error('Email not found');
      }

      // In a real app, you would send a reset email here
      return AuthResult.success(null, 'Password reset email sent');
    } catch (e) {
      return AuthResult.error('Password reset failed: ${e.toString()}');
    }
  }
}

/// Auth result wrapper
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? token;
  final String? message;
  final String? phone;
  final String? otp;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.token,
    this.message,
    this.phone,
    this.otp,
  });

  factory AuthResult.success(User? user, String? token) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      token: token,
    );
  }

  factory AuthResult.error(String message) {
    return AuthResult._(
      isSuccess: false,
      message: message,
    );
  }

  factory AuthResult.otpSent(String phone, String otp) {
    return AuthResult._(
      isSuccess: true,
      phone: phone,
      otp: otp,
      message: 'OTP sent successfully',
    );
  }
}