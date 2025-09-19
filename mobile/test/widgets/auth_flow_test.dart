import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:austin_food_club_flutter/screens/auth/login_screen.dart';
import 'package:austin_food_club_flutter/screens/auth/otp_screen.dart';
import 'package:austin_food_club_flutter/providers/auth_provider.dart';
import 'package:austin_food_club_flutter/widgets/common/custom_button.dart';
import 'package:austin_food_club_flutter/widgets/common/custom_text_field.dart';

void main() {
  group('Authentication Flow Widget Tests', () {
    late AuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = AuthProvider();
    });

    testWidgets('LoginScreen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>(
            create: (_) => mockAuthProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Verify login screen elements
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.byType(CustomTextField), findsOneWidget);
      expect(find.byType(CustomButton), findsAtLeastNWidgets(1));
    });

    testWidgets('Phone number input validation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>(
            create: (_) => mockAuthProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Find phone input field
      final phoneField = find.byType(CustomTextField);
      expect(phoneField, findsOneWidget);

      // Enter invalid phone number
      await tester.enterText(phoneField, '123');
      await tester.pump();

      // Verify validation (this would depend on your validation logic)
      // expect(find.text('Invalid phone number'), findsOneWidget);

      // Enter valid phone number
      await tester.enterText(phoneField, '+15551234567');
      await tester.pump();

      // Verify no validation error
      expect(find.text('Invalid phone number'), findsNothing);
    });

    testWidgets('Login button triggers authentication', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>(
            create: (_) => mockAuthProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      // Enter phone number
      await tester.enterText(find.byType(CustomTextField), '+15551234567');
      await tester.pump();

      // Tap login button
      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      // Verify loading state or navigation
      // This would depend on your implementation
    });

    testWidgets('OTPScreen displays 6 digit input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>(
            create: (_) => mockAuthProvider,
            child: const OTPScreen(phoneNumber: '+15551234567'),
          ),
        ),
      );

      // Verify OTP screen elements
      expect(find.text('Verify Your Phone'), findsOneWidget);
      expect(find.text('+15551234567'), findsOneWidget);
      
      // Verify 6 OTP input fields
      expect(find.byType(TextField), findsNWidgets(6));
      
      // Verify verify button
      expect(find.text('Verify Code'), findsOneWidget);
    });

    testWidgets('OTP input auto-advances', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>(
            create: (_) => mockAuthProvider,
            child: const OTPScreen(phoneNumber: '+15551234567'),
          ),
        ),
      );

      // Get all OTP input fields
      final otpFields = find.byType(TextField);
      
      // Enter digit in first field
      await tester.enterText(otpFields.first, '1');
      await tester.pump();
      
      // Verify focus moved to next field (implementation dependent)
      // This would require checking focus state
    });

    testWidgets('OTP verification with complete code', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>(
            create: (_) => mockAuthProvider,
            child: const OTPScreen(phoneNumber: '+15551234567'),
          ),
        ),
      );

      // Enter complete OTP code
      final otpFields = find.byType(TextField);
      for (int i = 0; i < 6; i++) {
        await tester.enterText(otpFields.at(i), '${i + 1}');
        await tester.pump();
      }

      // Verify auto-verification triggers
      await tester.pump(const Duration(seconds: 1));
      
      // Check if verification was triggered
      // This would depend on your implementation
    });

    testWidgets('Resend code functionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>(
            create: (_) => mockAuthProvider,
            child: const OTPScreen(phoneNumber: '+15551234567'),
          ),
        ),
      );

      // Initially resend should be disabled (timer running)
      expect(find.text('Resend Code'), findsNothing);
      expect(find.textContaining('Resend code in'), findsOneWidget);

      // Fast forward timer (would need to mock timer)
      // await tester.pump(const Duration(seconds: 61));
      
      // Verify resend button appears
      // expect(find.text('Resend Code'), findsOneWidget);
    });

    testWidgets('Authentication error handling', (WidgetTester tester) async {
      // Mock error state in auth provider
      mockAuthProvider.setError('Invalid OTP code');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>(
            create: (_) => mockAuthProvider,
            child: const OTPScreen(phoneNumber: '+15551234567'),
          ),
        ),
      );

      await tester.pump();

      // Verify error message is displayed
      expect(find.text('Invalid OTP code'), findsOneWidget);
    });

    testWidgets('Loading states display correctly', (WidgetTester tester) async {
      // Mock loading state in auth provider
      mockAuthProvider.setLoading(true);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>(
            create: (_) => mockAuthProvider,
            child: const LoginScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

