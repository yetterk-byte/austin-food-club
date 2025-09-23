import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get error => _error;

  Future<void> initializeAuth() async {
    _setLoading(true);
    
    // Simulate checking for stored auth state
    await Future.delayed(const Duration(seconds: 2));
    
    // For now, just set loading to false
    // In a real app, you'd check for stored tokens here
    _setLoading(false);
  }

  Future<void> signInWithPhone(String phoneNumber) async {
    print('🔐 AuthProvider: Starting sign in with phone: $phoneNumber');
    _setLoading(true);
    _clearError();
    
    try {
      // Simulate API call
      print('🔐 AuthProvider: Simulating API call...');
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock successful login
      print('🔐 AuthProvider: Creating user...');
      _currentUser = User(
        id: '1',
        name: 'Demo User',
        email: 'demo@example.com',
        phone: phoneNumber,
        createdAt: DateTime.now(),
      );
      
      print('🔐 AuthProvider: User created: ${_currentUser?.name}');
      print('🔐 AuthProvider: isLoggedIn: $isLoggedIn');
      print('🔐 AuthProvider: Calling notifyListeners...');
      notifyListeners();
      print('🔐 AuthProvider: notifyListeners called');
    } catch (e) {
      print('🔐 AuthProvider: Error during sign in: $e');
      _setError('Failed to sign in: $e');
    } finally {
      print('🔐 AuthProvider: Setting loading to false');
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    _clearError();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}