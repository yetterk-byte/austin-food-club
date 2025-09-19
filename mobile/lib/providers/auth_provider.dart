import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  String? _authToken;
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;

  // Getters
  User? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;

  /// Initialize auth state on app start
  Future<void> initializeAuth() async {
    _setLoading(true);
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (isLoggedIn) {
        final user = await AuthService.getCurrentUser();
        final token = await AuthService.getAuthToken();
        
        if (user != null && token != null) {
          _currentUser = user;
          _authToken = token;
          _isLoggedIn = true;
        }
      }
    } catch (e) {
      _setError('Failed to initialize authentication: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await AuthService.signInWithEmail(email, password);
      
      if (result.isSuccess && result.user != null) {
        _currentUser = result.user;
        _authToken = result.token;
        _isLoggedIn = true;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.message ?? 'Sign in failed');
        return false;
      }
    } catch (e) {
      _setError('Sign in failed: ${e.toString()}');
      return false;
    }
  }

  /// Sign in with phone number (send OTP)
  Future<String?> signInWithPhone(String phone) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await AuthService.signInWithPhone(phone);
      
      if (result.isSuccess) {
        _setLoading(false);
        // Return OTP for demo purposes (in real app, OTP would be sent via SMS)
        return result.otp;
      } else {
        _setError(result.message ?? 'Phone sign in failed');
        return null;
      }
    } catch (e) {
      _setError('Phone sign in failed: ${e.toString()}');
      return null;
    }
  }

  /// Verify OTP
  Future<bool> verifyOTP(String phone, String otp) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await AuthService.verifyOTP(phone, otp);
      
      if (result.isSuccess && result.user != null) {
        _currentUser = result.user;
        _authToken = result.token;
        _isLoggedIn = true;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.message ?? 'OTP verification failed');
        return false;
      }
    } catch (e) {
      _setError('OTP verification failed: ${e.toString()}');
      return false;
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmail(String email, String password, String name) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await AuthService.signUpWithEmail(email, password, name);
      
      if (result.isSuccess && result.user != null) {
        _currentUser = result.user;
        _authToken = result.token;
        _isLoggedIn = true;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.message ?? 'Sign up failed');
        return false;
      }
    } catch (e) {
      _setError('Sign up failed: ${e.toString()}');
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile(User updatedUser) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await AuthService.updateProfile(updatedUser);
      
      if (result.isSuccess && result.user != null) {
        _currentUser = result.user;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result.message ?? 'Profile update failed');
        return false;
      }
    } catch (e) {
      _setError('Profile update failed: ${e.toString()}');
      return false;
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await AuthService.resetPassword(email);
      
      if (result.isSuccess) {
        _setLoading(false);
        return true;
      } else {
        _setError(result.message ?? 'Password reset failed');
        return false;
      }
    } catch (e) {
      _setError('Password reset failed: ${e.toString()}');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await AuthService.signOut();
      _currentUser = null;
      _authToken = null;
      _isLoggedIn = false;
      _clearError();
    } catch (e) {
      _setError('Sign out failed: ${e.toString()}');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}