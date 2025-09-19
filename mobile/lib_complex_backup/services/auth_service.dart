import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

import '../config/constants.dart';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalAuthentication _localAuth = LocalAuthentication();
  User? _currentUser;
  String? _authToken;
  Stream<AuthState>? _authStateStream;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && _authToken != null;
  String? get authToken => _authToken;

  // Initialize auth service
  Future<void> initialize() async {
    await _loadStoredUser();
    _authStateStream = _supabase.auth.onAuthStateChange;
    _authStateStream!.listen(_onAuthStateChange);
    
    // Set up deep linking for OTP
    await _setupDeepLinking();
  }

  Future<void> _setupDeepLinking() async {
    // Configure deep linking for OTP verification
    await Supabase.instance.client.auth.signInWithOtp(
      phone: '+1234567890', // Placeholder - will be replaced with actual phone
      options: const AuthOptions(
        redirectTo: 'io.supabase.austinfoodclub://login-callback/',
      ),
    );
  }

  // Auth state change listener
  void _onAuthStateChange(AuthState data) {
    final session = data.session;
    if (session != null) {
      _authToken = session.accessToken;
      _loadUserFromSession(session);
    } else {
      _currentUser = null;
      _authToken = null;
    }
  }

  // Load user from stored data
  Future<void> _loadStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.userDataKey);
      final token = prefs.getString(AppConstants.userTokenKey);
      
      if (userJson != null && token != null) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = User.fromJson(userData);
        _authToken = token;
      }
    } catch (e) {
      print('Error loading stored user: $e');
    }
  }

  // Load user from Supabase session
  Future<void> _loadUserFromSession(Session session) async {
    try {
      final user = session.user;
      if (user != null) {
        _currentUser = User(
          id: user.id,
          email: user.email,
          name: user.userMetadata?['name'] ?? user.email?.split('@').first ?? 'User',
          phoneNumber: user.phone,
          avatarUrl: user.userMetadata?['avatar_url'],
          createdAt: DateTime.parse(user.createdAt),
        );
        await _storeUserData();
      }
    } catch (e) {
      print('Error loading user from session: $e');
    }
  }

  // Store user data locally
  Future<void> _storeUserData() async {
    if (_currentUser != null && _authToken != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userDataKey, jsonEncode(_currentUser!.toJson()));
        await prefs.setString(AppConstants.userTokenKey, _authToken!);
      } catch (e) {
        print('Error storing user data: $e');
      }
    }
  }

  // Phone Authentication
  Future<void> signInWithPhone(String phoneNumber) async {
    try {
      await _supabase.auth.signInWithOtp(
        phone: phoneNumber,
        options: const AuthOptions(
          redirectTo: 'io.supabase.austinfoodclub://login-callback/',
        ),
      );
    } on AuthException catch (e) {
      throw Exception('Phone sign-in failed: ${e.message}');
    }
  }

  Future<AuthResponse> verifyPhoneOTP(String phone, String token) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      
      if (response.user != null) {
        _currentUser = User(
          id: response.user!.id,
          phoneNumber: phone,
          name: response.user!.userMetadata?['name'] ?? 'User',
          email: response.user!.email,
          avatarUrl: response.user!.userMetadata?['avatar_url'],
          createdAt: DateTime.parse(response.user!.createdAt),
        );
        _authToken = response.session?.accessToken;
        await _storeUserData();
      }
      
      return response;
    } on AuthException catch (e) {
      throw Exception('OTP verification failed: ${e.message}');
    }
  }

  // Email Authentication (fallback)
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        _currentUser = User(
          id: response.user!.id,
          email: email,
          name: response.user!.userMetadata?['name'] ?? email.split('@').first,
          phoneNumber: response.user!.phone,
          avatarUrl: response.user!.userMetadata?['avatar_url'],
          createdAt: DateTime.parse(response.user!.createdAt),
        );
        _authToken = response.session?.accessToken;
        await _storeUserData();
      }
      
      return response;
    } on AuthException catch (e) {
      throw Exception('Email sign-in failed: ${e.message}');
    }
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': email.split('@').first,
        },
      );
      
      if (response.user != null) {
        _currentUser = User(
          id: response.user!.id,
          email: email,
          name: email.split('@').first,
          createdAt: DateTime.parse(response.user!.createdAt),
        );
        _authToken = response.session?.accessToken;
        await _storeUserData();
      }
      
      return response;
    } on AuthException catch (e) {
      throw Exception('Email sign-up failed: ${e.message}');
    }
  }

  // Session Management
  User? getCurrentUser() {
    return _currentUser;
  }

  Stream<AuthState> authStateChanges() {
    return _authStateStream ?? _supabase.auth.onAuthStateChange;
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      _authToken = null;
      
      // Clear stored data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userDataKey);
      await prefs.remove(AppConstants.userTokenKey);
    } on AuthException catch (e) {
      throw Exception('Sign out failed: ${e.message}');
    }
  }

  Future<String?> getAccessToken() async {
    if (_authToken != null) {
      return _authToken;
    }
    
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _authToken = session.accessToken;
      return _authToken;
    }
    
    return null;
  }

  // Profile Management
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      await _supabase.auth.updateUser(UserAttributes(data: updates));
      
      // Update local user data
      _currentUser = _currentUser!.copyWith(
        name: updates['name'] ?? _currentUser!.name,
        phoneNumber: updates['phone'] ?? _currentUser!.phoneNumber,
        avatarUrl: updates['avatar_url'] ?? _currentUser!.avatarUrl,
      );
      
      await _storeUserData();
    } on AuthException catch (e) {
      throw Exception('Profile update failed: ${e.message}');
    }
  }

  Future<String> uploadAvatar(String filePath) async {
    try {
      final file = File(filePath);
      final fileName = 'avatars/${_currentUser?.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final response = await _supabase.storage
          .from('avatars')
          .upload(fileName, file);
      
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);
      
      // Update user profile with new avatar URL
      await updateProfile({'avatar_url': publicUrl});
      
      return publicUrl;
    } catch (e) {
      throw Exception('Avatar upload failed: $e');
    }
  }

  // Biometric Authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw Exception('Biometric authentication not available');
      }

      final result = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your account',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return result;
    } catch (e) {
      throw Exception('Biometric authentication failed: $e');
    }
  }

  Future<void> enableBiometricAuth() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw Exception('Biometric authentication not available on this device');
      }

      // Store biometric preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', true);
    } catch (e) {
      throw Exception('Failed to enable biometric authentication: $e');
    }
  }

  Future<void> disableBiometricAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', false);
    } catch (e) {
      throw Exception('Failed to disable biometric authentication: $e');
    }
  }

  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('biometric_enabled') ?? false;
    } catch (e) {
      return false;
    }
  }

  // Token Refresh
  Future<void> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      if (response.session != null) {
        _authToken = response.session!.accessToken;
        await _storeUserData();
      }
    } on AuthException catch (e) {
      throw Exception('Session refresh failed: ${e.message}');
    }
  }

  // Legacy methods for backward compatibility
  Future<User> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          if (phoneNumber != null) 'phone': phoneNumber,
        },
      );

      if (response.user == null) {
        throw Exception('Failed to create user');
      }

      _currentUser = User(
        id: response.user!.id,
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        createdAt: DateTime.parse(response.user!.createdAt),
      );

      _authToken = response.session?.accessToken;
      await _storeUserData();

      return _currentUser!;
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Sign in with email and password
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Failed to sign in');
      }

      _currentUser = User(
        id: response.user!.id,
        email: email,
        name: response.user!.userMetadata?['name'] ?? email.split('@').first,
        phoneNumber: response.user!.phone,
        avatarUrl: response.user!.userMetadata?['avatar_url'],
        createdAt: DateTime.parse(response.user!.createdAt),
      );

      _authToken = response.session?.accessToken;
      await _storeUserData();

      return _currentUser!;
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Sign in with phone number
  Future<void> signInWithPhone({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        phone: phoneNumber,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Failed to sign in');
      }

      _currentUser = User(
        id: response.user!.id,
        phoneNumber: phoneNumber,
        name: response.user!.userMetadata?['name'] ?? 'User',
        email: response.user!.email,
        avatarUrl: response.user!.userMetadata?['avatar_url'],
        createdAt: DateTime.parse(response.user!.createdAt),
      );

      _authToken = response.session?.accessToken;
      await _storeUserData();
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Send OTP for phone verification
  Future<void> sendOTP(String phoneNumber) async {
    try {
      await _supabase.auth.signInWithOtp(phone: phoneNumber);
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Verify OTP
  Future<User> verifyOTP({
    required String phoneNumber,
    required String token,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phoneNumber,
        token: token,
        type: OtpType.sms,
      );

      if (response.user == null) {
        throw Exception('Failed to verify OTP');
      }

      _currentUser = User(
        id: response.user!.id,
        phoneNumber: phoneNumber,
        name: response.user!.userMetadata?['name'] ?? 'User',
        email: response.user!.email,
        avatarUrl: response.user!.userMetadata?['avatar_url'],
        createdAt: DateTime.parse(response.user!.createdAt),
      );

      _authToken = response.session?.accessToken;
      await _storeUserData();

      return _currentUser!;
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Sign in with Google
  Future<User> signInWithGoogle() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        Provider.google,
        redirectTo: 'io.supabase.austinfoodclub://login-callback/',
      );

      if (response.user == null) {
        throw Exception('Failed to sign in with Google');
      }

      _currentUser = User(
        id: response.user!.id,
        email: response.user!.email,
        name: response.user!.userMetadata?['name'] ?? 'User',
        phoneNumber: response.user!.phone,
        avatarUrl: response.user!.userMetadata?['avatar_url'],
        createdAt: DateTime.parse(response.user!.createdAt),
      );

      _authToken = response.session?.accessToken;
      await _storeUserData();

      return _currentUser!;
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Sign in with Apple
  Future<User> signInWithApple() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        Provider.apple,
        redirectTo: 'io.supabase.austinfoodclub://login-callback/',
      );

      if (response.user == null) {
        throw Exception('Failed to sign in with Apple');
      }

      _currentUser = User(
        id: response.user!.id,
        email: response.user!.email,
        name: response.user!.userMetadata?['name'] ?? 'User',
        phoneNumber: response.user!.phone,
        avatarUrl: response.user!.userMetadata?['avatar_url'],
        createdAt: DateTime.parse(response.user!.createdAt),
      );

      _authToken = response.session?.accessToken;
      await _storeUserData();

      return _currentUser!;
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Update user profile
  Future<User> updateProfile({
    String? name,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phone'] = phoneNumber;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await _supabase.auth.updateUser(UserAttributes(data: updates));

      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
        avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
      );

      await _storeUserData();
      return _currentUser!;
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      _authToken = null;
      
      // Clear stored data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userDataKey);
      await prefs.remove(AppConstants.userTokenKey);
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    if (_currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      await _supabase.auth.admin.deleteUser(_currentUser!.id);
      await signOut();
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // Refresh session
  Future<void> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      if (response.session != null) {
        _authToken = response.session!.accessToken;
        await _storeUserData();
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    }
  }
}
