import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Initialize auth provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      await _authService.initialize();
      
      // Listen to auth state changes
      _authService.authStateChanges().listen((authState) {
        _currentUser = _authService.getCurrentUser();
        _clearError();
        notifyListeners();
      });
      
      // Set initial user
      _currentUser = _authService.getCurrentUser();
      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Phone Authentication
  Future<void> signIn(String phoneNumber) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.signInWithPhone(phoneNumber);
      // OTP will be sent, user needs to verify
    } catch (e) {
      _setError('Failed to send OTP: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyOTP(String otp) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (_currentUser?.phoneNumber == null) {
        throw Exception('No phone number found for verification');
      }
      
      final response = await _authService.verifyPhoneOTP(
        _currentUser!.phoneNumber!,
        otp,
      );
      
      if (response.user != null) {
        _currentUser = _authService.getCurrentUser();
        _clearError();
      } else {
        _setError('OTP verification failed');
      }
    } catch (e) {
      _setError('Failed to verify OTP: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Email Authentication (fallback)
  Future<void> signInWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();
      
      final response = await _authService.signInWithEmail(email, password);
      
      if (response.user != null) {
        _currentUser = _authService.getCurrentUser();
        _clearError();
      } else {
        _setError('Email sign-in failed');
      }
    } catch (e) {
      _setError('Failed to sign in with email: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();
      
      final response = await _authService.signUpWithEmail(email, password);
      
      if (response.user != null) {
        _currentUser = _authService.getCurrentUser();
        _clearError();
      } else {
        _setError('Email sign-up failed');
      }
    } catch (e) {
      _setError('Failed to sign up with email: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Profile Management
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.updateProfile(updates);
      _currentUser = _authService.getCurrentUser();
    } catch (e) {
      _setError('Failed to update profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> uploadAvatar(String filePath) async {
    try {
      _setLoading(true);
      _clearError();
      
      final avatarUrl = await _authService.uploadAvatar(filePath);
      _currentUser = _authService.getCurrentUser();
    } catch (e) {
      _setError('Failed to upload avatar: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Biometric Authentication
  Future<bool> authenticateWithBiometrics() async {
    try {
      _clearError();
      return await _authService.authenticateWithBiometrics();
    } catch (e) {
      _setError('Biometric authentication failed: $e');
      return false;
    }
  }

  Future<void> enableBiometricAuth() async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.enableBiometricAuth();
    } catch (e) {
      _setError('Failed to enable biometric authentication: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> disableBiometricAuth() async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.disableBiometricAuth();
    } catch (e) {
      _setError('Failed to disable biometric authentication: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> isBiometricEnabled() async {
    try {
      return await _authService.isBiometricEnabled();
    } catch (e) {
      _setError('Failed to check biometric status: $e');
      return false;
    }
  }

  // Session Management
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _setError('Failed to sign out: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshSession() async {
    try {
      _setLoading(true);
      _clearError();
      
      await _authService.refreshSession();
      _currentUser = _authService.getCurrentUser();
    } catch (e) {
      _setError('Failed to refresh session: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Error Management
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}