import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class Helpers {
  // Date formatting
  static String formatDate(DateTime date, {String pattern = 'MMM dd, yyyy'}) {
    return DateFormat(pattern).format(date);
  }

  static String formatTime(DateTime date, {String pattern = 'h:mm a'}) {
    return DateFormat(pattern).format(date);
  }

  static String formatDateTime(DateTime date, {String pattern = 'MMM dd, yyyy h:mm a'}) {
    return DateFormat(pattern).format(date);
  }

  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // File size formatting
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Currency formatting
  static String formatCurrency(double amount, {String symbol = '\$'}) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  // Rating formatting
  static String formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  // Phone number formatting
  static String formatPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (cleaned.length == 10) {
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    } else if (cleaned.length == 11 && cleaned.startsWith('1')) {
      return '+1 (${cleaned.substring(1, 4)}) ${cleaned.substring(4, 7)}-${cleaned.substring(7)}';
    }
    
    return phoneNumber;
  }

  // Text truncation
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Capitalize first letter
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Capitalize each word
  static String capitalizeWords(String text) {
    return text.split(' ').map((word) => capitalizeFirst(word)).join(' ');
  }

  // Generate initials
  static String generateInitials(String name) {
    if (name.isEmpty) return 'U';
    
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    }
    
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  // Color utilities
  static Color hexToColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  static Color lightenColor(Color color, double amount) {
    return Color.fromARGB(
      color.alpha,
      (color.red + (255 - color.red) * amount).round(),
      (color.green + (255 - color.green) * amount).round(),
      (color.blue + (255 - color.blue) * amount).round(),
    );
  }

  static Color darkenColor(Color color, double amount) {
    return Color.fromARGB(
      color.alpha,
      (color.red * (1 - amount)).round(),
      (color.green * (1 - amount)).round(),
      (color.blue * (1 - amount)).round(),
    );
  }

  // Platform detection
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isWeb => !isAndroid && !isIOS;

  // Device info
  static String getPlatformName() {
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    return 'Web';
  }

  // Validation helpers
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(cleaned);
  }

  static bool isValidUrl(String url) {
    return RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'
    ).hasMatch(url);
  }

  // String utilities
  static String removeSpecialCharacters(String text) {
    return text.replaceAll(RegExp(r'[^\w\s]'), '');
  }

  static String removeWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), '');
  }

  static String slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  // Number utilities
  static String formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}K';
    if (number < 1000000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    return '${(number / 1000000000).toStringAsFixed(1)}B';
  }

  static double clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  static int clampInt(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  // List utilities
  static List<T> removeDuplicates<T>(List<T> list) {
    return list.toSet().toList();
  }

  static List<T> shuffleList<T>(List<T> list) {
    final shuffled = List<T>.from(list);
    shuffled.shuffle();
    return shuffled;
  }

  static T? getRandomItem<T>(List<T> list) {
    if (list.isEmpty) return null;
    return list[DateTime.now().millisecondsSinceEpoch % list.length];
  }

  static List<T> getRandomItems<T>(List<T> list, int count) {
    if (list.isEmpty || count <= 0) return [];
    
    final shuffled = shuffleList(list);
    return shuffled.take(count).toList();
  }

  // Map utilities
  static Map<String, dynamic> removeNullValues(Map<String, dynamic> map) {
    return Map.fromEntries(
      map.entries.where((entry) => entry.value != null)
    );
  }

  static Map<String, dynamic> filterMap(
    Map<String, dynamic> map,
    bool Function(String key, dynamic value) predicate,
  ) {
    return Map.fromEntries(
      map.entries.where((entry) => predicate(entry.key, entry.value))
    );
  }

  // Time utilities
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }

  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return date.isAfter(weekStart.subtract(const Duration(days: 1))) && 
           date.isBefore(weekEnd.add(const Duration(days: 1)));
  }

  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  static bool isThisYear(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year;
  }

  // UI helpers
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static bool isTablet(BuildContext context) {
    return getScreenWidth(context) > 600;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  static double getStatusBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  static double getBottomPadding(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  // Animation helpers
  static Duration getAnimationDuration(int milliseconds) {
    return Duration(milliseconds: milliseconds);
  }

  static Curve getAnimationCurve(CurveType type) {
    switch (type) {
      case CurveType.easeIn:
        return Curves.easeIn;
      case CurveType.easeOut:
        return Curves.easeOut;
      case CurveType.easeInOut:
        return Curves.easeInOut;
      case CurveType.bounceIn:
        return Curves.bounceIn;
      case CurveType.bounceOut:
        return Curves.bounceOut;
      case CurveType.elasticIn:
        return Curves.elasticIn;
      case CurveType.elasticOut:
        return Curves.elasticOut;
      default:
        return Curves.easeInOut;
    }
  }

  // Error handling
  static String getErrorMessage(dynamic error) {
    if (error is String) return error;
    if (error is Exception) return error.toString();
    return 'An unexpected error occurred';
  }

  static String getNetworkErrorMessage(dynamic error) {
    final message = getErrorMessage(error);
    if (message.contains('SocketException') || message.contains('NetworkException')) {
      return 'Please check your internet connection';
    }
    if (message.contains('TimeoutException')) {
      return 'Request timed out. Please try again';
    }
    if (message.contains('FormatException')) {
      return 'Invalid data format received';
    }
    return message;
  }

  // Debug helpers
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      print('${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void logError(String message, dynamic error, {String? tag}) {
    if (kDebugMode) {
      print('${tag != null ? '[$tag] ' : ''}ERROR: $message');
      print('${tag != null ? '[$tag] ' : ''}Details: $error');
    }
  }

  // Performance helpers
  static Future<T> measurePerformance<T>(
    Future<T> Function() function,
    String operationName,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await function();
      stopwatch.stop();
      log('$operationName completed in ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      logError('$operationName failed after ${stopwatch.elapsedMilliseconds}ms', e);
      rethrow;
    }
  }

  static T measureSyncPerformance<T>(
    T Function() function,
    String operationName,
  ) {
    final stopwatch = Stopwatch()..start();
    try {
      final result = function();
      stopwatch.stop();
      log('$operationName completed in ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      logError('$operationName failed after ${stopwatch.elapsedMilliseconds}ms', e);
      rethrow;
    }
  }
}

enum CurveType {
  easeIn,
  easeOut,
  easeInOut,
  bounceIn,
  bounceOut,
  elasticIn,
  elasticOut,
}

