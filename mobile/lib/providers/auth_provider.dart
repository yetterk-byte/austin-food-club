import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase show User;
import '../models/user.dart';
import '../config/supabase_config.dart';
import '../services/verification_service.dart';

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
    
    try {
      // Check if user is already signed in
      final session = SupabaseConfig.client.auth.currentSession;
      
      if (session?.user != null) {
        await _syncUserFromSupabase(session!.user);
      }
      
      // Listen for auth state changes
      SupabaseConfig.client.auth.onAuthStateChange.listen((data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        
        if (event == AuthChangeEvent.signedIn && session?.user != null) {
          await _syncUserFromSupabase(session!.user);
        } else if (event == AuthChangeEvent.signedOut) {
          _currentUser = null;
          notifyListeners();
        }
      });
      
    } catch (e) {
      print('🔐 AuthProvider: Error initializing auth: $e');
      _setError('Failed to initialize authentication: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithPhone(String phoneNumber) async {
    print('🔐 AuthProvider: Starting sign in with phone: $phoneNumber');
    _setLoading(true);
    _clearError();
    
    try {
      // Send OTP to phone number
      await SupabaseConfig.client.auth.signInWithOtp(
        phone: phoneNumber,
      );
      
      print('🔐 AuthProvider: OTP sent to $phoneNumber');
      // Note: User will be signed in after they enter the OTP
      // The auth state change listener will handle the actual sign-in
      
    } catch (e) {
      print('🔐 AuthProvider: Error during sign in: $e');
      _setError('Failed to send OTP: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Send verification code using our backend
  Future<bool> sendVerificationCode(String phoneNumber) async {
    print('🔐 AuthProvider: Sending verification code to: $phoneNumber');
    _setLoading(true);
    _clearError();
    
    try {
      final result = await VerificationService.sendVerificationCode(phoneNumber);
      
      if (result['success'] == true) {
        print('🔐 AuthProvider: Verification code sent successfully');
        
        // Log the mock code for testing
        final data = result['data'];
        if (data != null && data['mockCode'] != null) {
          print('📱 [MOCK SMS] Verification code for $phoneNumber: ${data['mockCode']}');
          print('📱 [MOCK SMS] Message: "Your Austin Food Club verification code is: ${data['mockCode']}. This code expires in 10 minutes."');
        }
        
        return true;
      } else {
        print('🔐 AuthProvider: Failed to send verification code: ${result['error']}');
        _setError(result['error']);
        return false;
      }
    } catch (e) {
      print('🔐 AuthProvider: Error sending verification code: $e');
      _setError('Failed to send verification code: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify code and create/login user using our backend
  Future<bool> verifyCodeAndLogin({
    required String phoneNumber,
    required String code,
    String? name,
  }) async {
    print('🔐 AuthProvider: Verifying code for: $phoneNumber');
    _setLoading(true);
    _clearError();
    
    try {
      final result = await VerificationService.verifyCode(
        phone: phoneNumber,
        code: code,
        name: name,
      );
      
      if (result['success'] == true) {
        final userData = result['data']['user'];
        final isNewUser = result['data']['isNewUser'] ?? false;
        
        // Create User object from backend response
        _currentUser = User(
          id: userData['id'],
          name: userData['name'],
          email: userData['email'] ?? '',
          phone: userData['phone'],
          createdAt: DateTime.parse(userData['createdAt']),
        );
        
        print('🔐 AuthProvider: ${isNewUser ? 'New user created' : 'User logged in'}: ${_currentUser!.name}');
        notifyListeners();
        return true;
      } else {
        print('🔐 AuthProvider: Failed to verify code: ${result['error']}');
        _setError(result['error']);
        return false;
      }
    } catch (e) {
      print('🔐 AuthProvider: Error verifying code: $e');
      _setError('Failed to verify code: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyOTP(String phoneNumber, String otp) async {
    print('🔐 AuthProvider: Verifying OTP for $phoneNumber');
    _setLoading(true);
    _clearError();
    
    try {
      final response = await SupabaseConfig.client.auth.verifyOTP(
        phone: phoneNumber,
        token: otp,
        type: OtpType.sms,
      );
      
      if (response.user != null) {
        await _syncUserFromSupabase(response.user!);
        print('🔐 AuthProvider: OTP verified successfully');
      }
      
    } catch (e) {
      print('🔐 AuthProvider: Error verifying OTP: $e');
      _setError('Invalid OTP: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseConfig.client.auth.signOut();
      _currentUser = null;
      _clearError();
      notifyListeners();
    } catch (e) {
      print('🔐 AuthProvider: Error signing out: $e');
      _setError('Failed to sign out: $e');
    }
  }

      Future<void> _syncUserFromSupabase(supabase.User supabaseUser) async {
    try {
      // Create User object from Supabase user
      _currentUser = User(
        id: supabaseUser.id,
        name: supabaseUser.userMetadata?['name'] ?? 
              supabaseUser.userMetadata?['full_name'] ?? 
              'User',
        email: supabaseUser.email ?? '',
        phone: supabaseUser.phone,
        createdAt: supabaseUser.createdAt != null 
            ? DateTime.parse(supabaseUser.createdAt!) 
            : DateTime.now(),
      );
      
      print('🔐 AuthProvider: User synced: ${_currentUser?.name}');
      notifyListeners();
      
    } catch (e) {
      print('🔐 AuthProvider: Error syncing user: $e');
      _setError('Failed to sync user: $e');
    }
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