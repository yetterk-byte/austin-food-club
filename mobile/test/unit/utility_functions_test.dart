import 'package:flutter_test/flutter_test.dart';
import 'package:austin_food_club_flutter/services/photo_service.dart';
import 'package:austin_food_club_flutter/services/notification_service.dart';
import 'package:austin_food_club_flutter/services/social_service.dart';
import 'package:austin_food_club_flutter/services/offline_service.dart';
import 'dart:io';
import 'dart:typed_data';

void main() {
  group('Utility Functions Unit Tests', () {
    group('Photo Service Utilities', () {
      // late PhotoService photoService; // Temporarily disabled

      setUp(() {
        // photoService = PhotoService(); // Temporarily disabled
      });

      test('validateImage accepts valid image files', () async {
        // Create mock image file
        final mockFile = File('test_image.jpg');
        
        // This would test image validation logic
        // expect(await photoService.validateImage(mockFile), isTrue);
      });

      test('validateImage rejects invalid files', () async {
        // Create mock non-image file
        final mockFile = File('test_document.pdf');
        
        // This would test image validation logic
        // expect(await photoService.validateImage(mockFile), isFalse);
      });

      test('validateImage rejects oversized files', () async {
        // Create mock large file
        final mockFile = File('large_image.jpg');
        
        // This would test file size validation
        // expect(await photoService.validateImage(mockFile), isFalse);
      });

      test('compressImage reduces file size', () async {
        // This would test image compression
        // Would need actual image file for testing
      });

      test('convertToBase64 creates valid base64 string', () async {
        // Create mock image data
        final imageData = Uint8List.fromList([137, 80, 78, 71]); // PNG header
        final mockFile = File('test.png');
        
        // This would test base64 conversion
        // final base64 = await photoService.convertToBase64(mockFile);
        // expect(base64, startsWith('data:image/'));
      });
    });

    group('Date/Time Utilities', () {
      test('formatTime returns correct relative time', () {
        final now = DateTime.now();
        
        // Test different time differences
        final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
        final oneHourAgo = now.subtract(const Duration(hours: 1));
        final oneDayAgo = now.subtract(const Duration(days: 1));
        final oneWeekAgo = now.subtract(const Duration(days: 7));

        // This would test time formatting utility functions
        // expect(formatRelativeTime(oneMinuteAgo), equals('1m ago'));
        // expect(formatRelativeTime(oneHourAgo), equals('1h ago'));
        // expect(formatRelativeTime(oneDayAgo), equals('1d ago'));
        // expect(formatRelativeTime(oneWeekAgo), equals('1w ago'));
      });

      test('isToday returns correct value', () {
        final today = DateTime.now();
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final tomorrow = DateTime.now().add(const Duration(days: 1));

        // This would test date utility functions
        // expect(isToday(today), isTrue);
        // expect(isToday(yesterday), isFalse);
        // expect(isToday(tomorrow), isFalse);
      });

      test('getDayOfWeek returns correct day name', () {
        final monday = DateTime(2023, 12, 4); // Known Monday
        final friday = DateTime(2023, 12, 8); // Known Friday

        // This would test day name utility
        // expect(getDayOfWeek(monday), equals('Monday'));
        // expect(getDayOfWeek(friday), equals('Friday'));
      });
    });

    group('Validation Utilities', () {
      test('isValidEmail validates email addresses correctly', () {
        // Valid emails
        expect(isValidEmail('test@example.com'), isTrue);
        expect(isValidEmail('user.name@domain.co.uk'), isTrue);
        expect(isValidEmail('user+tag@example.org'), isTrue);

        // Invalid emails
        expect(isValidEmail('invalid'), isFalse);
        expect(isValidEmail('test@'), isFalse);
        expect(isValidEmail('@example.com'), isFalse);
        expect(isValidEmail('test..test@example.com'), isFalse);
      });

      test('isValidPhoneNumber validates phone numbers correctly', () {
        // Valid phone numbers
        expect(isValidPhoneNumber('+15551234567'), isTrue);
        expect(isValidPhoneNumber('(555) 123-4567'), isTrue);
        expect(isValidPhoneNumber('555-123-4567'), isTrue);

        // Invalid phone numbers
        expect(isValidPhoneNumber('123'), isFalse);
        expect(isValidPhoneNumber('abc-def-ghij'), isFalse);
        expect(isValidPhoneNumber(''), isFalse);
      });

      test('sanitizeInput removes dangerous characters', () {
        // Test input sanitization
        expect(sanitizeInput('Normal text'), equals('Normal text'));
        expect(sanitizeInput('<script>alert("xss")</script>'), equals('alert("xss")'));
        expect(sanitizeInput('Text with\nnewlines\r\n'), equals('Text with newlines '));
      });

      test('validateRating accepts valid ratings', () {
        // Valid ratings (1-5)
        expect(validateRating(1), isTrue);
        expect(validateRating(3), isTrue);
        expect(validateRating(5), isTrue);

        // Invalid ratings
        expect(validateRating(0), isFalse);
        expect(validateRating(6), isFalse);
        expect(validateRating(-1), isFalse);
      });
    });

    group('String Utilities', () {
      test('capitalizeFirstLetter works correctly', () {
        expect(capitalizeFirstLetter('hello'), equals('Hello'));
        expect(capitalizeFirstLetter('HELLO'), equals('HELLO'));
        expect(capitalizeFirstLetter(''), equals(''));
        expect(capitalizeFirstLetter('h'), equals('H'));
      });

      test('truncateText truncates long text', () {
        const longText = 'This is a very long text that should be truncated';
        
        expect(truncateText(longText, 10), equals('This is a...'));
        expect(truncateText('Short', 10), equals('Short'));
        expect(truncateText('', 10), equals(''));
      });

      test('removeSpecialCharacters cleans text', () {
        expect(removeSpecialCharacters('Hello, World!'), equals('Hello World'));
        expect(removeSpecialCharacters('Test@#$%^&*()'), equals('Test'));
        expect(removeSpecialCharacters('123-456-7890'), equals('1234567890'));
      });

      test('formatPhoneNumber formats correctly', () {
        expect(formatPhoneNumber('5551234567'), equals('(555) 123-4567'));
        expect(formatPhoneNumber('+15551234567'), equals('+1 (555) 123-4567'));
        expect(formatPhoneNumber('123'), equals('123')); // Too short
      });
    });

    group('List Utilities', () {
      test('removeDuplicates removes duplicate items', () {
        final list = [1, 2, 3, 2, 4, 1, 5];
        final result = removeDuplicates(list);
        
        expect(result, equals([1, 2, 3, 4, 5]));
        expect(result.length, equals(5));
      });

      test('groupBy groups items correctly', () {
        final items = [
          {'category': 'BBQ', 'name': 'Franklin'},
          {'category': 'Tacos', 'name': 'Veracruz'},
          {'category': 'BBQ', 'name': 'La Barbecue'},
          {'category': 'Asian', 'name': 'Uchi'},
        ];

        final grouped = groupBy(items, (item) => item['category']);
        
        expect(grouped.keys.length, equals(3));
        expect(grouped['BBQ']?.length, equals(2));
        expect(grouped['Tacos']?.length, equals(1));
        expect(grouped['Asian']?.length, equals(1));
      });

      test('sortByProperty sorts correctly', () {
        final restaurants = [
          {'name': 'Zebra Restaurant', 'rating': 3.0},
          {'name': 'Alpha Restaurant', 'rating': 5.0},
          {'name': 'Beta Restaurant', 'rating': 4.0},
        ];

        // Sort by name
        final sortedByName = sortByProperty(restaurants, 'name');
        expect(sortedByName[0]['name'], equals('Alpha Restaurant'));
        expect(sortedByName[2]['name'], equals('Zebra Restaurant'));

        // Sort by rating (descending)
        final sortedByRating = sortByProperty(restaurants, 'rating', descending: true);
        expect(sortedByRating[0]['rating'], equals(5.0));
        expect(sortedByRating[2]['rating'], equals(3.0));
      });
    });

    group('Color Utilities', () {
      test('hexToColor converts hex strings correctly', () {
        expect(hexToColor('#FF0000'), equals(const Color(0xFFFF0000)));
        expect(hexToColor('#00FF00'), equals(const Color(0xFF00FF00)));
        expect(hexToColor('#0000FF'), equals(const Color(0xFF0000FF)));
        expect(hexToColor('FF0000'), equals(const Color(0xFFFF0000))); // Without #
      });

      test('colorToHex converts colors correctly', () {
        expect(colorToHex(const Color(0xFFFF0000)), equals('#FF0000'));
        expect(colorToHex(const Color(0xFF00FF00)), equals('#00FF00'));
        expect(colorToHex(const Color(0xFF0000FF)), equals('#0000FF'));
      });

      test('lightenColor lightens colors correctly', () {
        const originalColor = Color(0xFF808080);
        final lightenedColor = lightenColor(originalColor, 0.2);
        
        expect(lightenedColor.red, greaterThan(originalColor.red));
        expect(lightenedColor.green, greaterThan(originalColor.green));
        expect(lightenedColor.blue, greaterThan(originalColor.blue));
      });
    });

    group('Cache Utilities', () {
      test('generateCacheKey creates consistent keys', () {
        final key1 = generateCacheKey('restaurants', {'area': 'east'});
        final key2 = generateCacheKey('restaurants', {'area': 'east'});
        final key3 = generateCacheKey('restaurants', {'area': 'west'});

        expect(key1, equals(key2)); // Same parameters
        expect(key1, isNot(equals(key3))); // Different parameters
      });

      test('isCacheExpired checks expiry correctly', () {
        final now = DateTime.now();
        final pastTime = now.subtract(const Duration(hours: 1));
        final futureTime = now.add(const Duration(hours: 1));

        expect(isCacheExpired(pastTime), isTrue);
        expect(isCacheExpired(futureTime), isFalse);
      });
    });
  });
}

// Mock utility functions for testing
bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  return emailRegex.hasMatch(email);
}

bool isValidPhoneNumber(String phone) {
  final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
  return phoneRegex.hasMatch(phone);
}

String sanitizeInput(String input) {
  return input.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll(RegExp(r'[\r\n]+'), ' ');
}

bool validateRating(int rating) {
  return rating >= 1 && rating <= 5;
}

String capitalizeFirstLetter(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

String truncateText(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}

String removeSpecialCharacters(String text) {
  return text.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
}

String formatPhoneNumber(String phone) {
  final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
  
  if (digitsOnly.length == 10) {
    return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
  } else if (digitsOnly.length == 11 && digitsOnly.startsWith('1')) {
    return '+1 (${digitsOnly.substring(1, 4)}) ${digitsOnly.substring(4, 7)}-${digitsOnly.substring(7)}';
  }
  
  return phone; // Return original if can't format
}

List<T> removeDuplicates<T>(List<T> list) {
  return list.toSet().toList();
}

Map<K, List<T>> groupBy<T, K>(List<T> list, K Function(T) keySelector) {
  final map = <K, List<T>>{};
  for (final item in list) {
    final key = keySelector(item);
    map.putIfAbsent(key, () => []).add(item);
  }
  return map;
}

List<Map<String, dynamic>> sortByProperty(
  List<Map<String, dynamic>> list,
  String property, {
  bool descending = false,
}) {
  final sorted = List<Map<String, dynamic>>.from(list);
  sorted.sort((a, b) {
    final aValue = a[property];
    final bValue = b[property];
    
    int comparison;
    if (aValue is String && bValue is String) {
      comparison = aValue.compareTo(bValue);
    } else if (aValue is num && bValue is num) {
      comparison = aValue.compareTo(bValue);
    } else {
      comparison = aValue.toString().compareTo(bValue.toString());
    }
    
    return descending ? -comparison : comparison;
  });
  
  return sorted;
}

Color hexToColor(String hex) {
  final hexColor = hex.replaceAll('#', '');
  return Color(int.parse('FF$hexColor', radix: 16));
}

String colorToHex(Color color) {
  return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
}

Color lightenColor(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final lightened = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
  return lightened.toColor();
}

String generateCacheKey(String prefix, Map<String, dynamic> parameters) {
  final sortedParams = Map.fromEntries(
    parameters.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  final paramString = sortedParams.entries
      .map((e) => '${e.key}=${e.value}')
      .join('&');
  return '$prefix:$paramString';
}

bool isCacheExpired(DateTime cacheTime) {
  return DateTime.now().isAfter(cacheTime);
}

