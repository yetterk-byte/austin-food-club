import 'package:flutter/foundation.dart';

enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  static Environment _currentEnvironment = Environment.development;
  
  static Environment get currentEnvironment => _currentEnvironment;
  
  static void setEnvironment(Environment environment) {
    _currentEnvironment = environment;
  }

  // API Configuration
  static String get apiBaseUrl {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'https://dev-api.austinfoodclub.com';
      case Environment.staging:
        return 'https://staging-api.austinfoodclub.com';
      case Environment.production:
        return 'https://api.austinfoodclub.com';
    }
  }

  static String get apiVersion => 'v1';
  
  static Duration get apiTimeout {
    switch (_currentEnvironment) {
      case Environment.development:
        return const Duration(seconds: 45); // Longer timeout for dev
      case Environment.staging:
        return const Duration(seconds: 30);
      case Environment.production:
        return const Duration(seconds: 20);
    }
  }

  // Supabase Configuration
  static String get supabaseUrl {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'https://your-dev-project.supabase.co';
      case Environment.staging:
        return 'https://your-staging-project.supabase.co';
      case Environment.production:
        return 'https://your-prod-project.supabase.co';
    }
  }

  static String get supabaseAnonKey {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'your_development_anon_key_here';
      case Environment.staging:
        return 'your_staging_anon_key_here';
      case Environment.production:
        return 'your_production_anon_key_here';
    }
  }

  // Firebase Configuration
  static String get firebaseProjectId {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'austin-food-club-dev';
      case Environment.staging:
        return 'austin-food-club-staging';
      case Environment.production:
        return 'austin-food-club-prod';
    }
  }

  static String get firebaseApiKey {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'your_development_firebase_api_key';
      case Environment.staging:
        return 'your_staging_firebase_api_key';
      case Environment.production:
        return 'your_production_firebase_api_key';
    }
  }

  // Google Services
  static String get googleMapsApiKey {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'your_development_google_maps_key';
      case Environment.staging:
        return 'your_staging_google_maps_key';
      case Environment.production:
        return 'your_production_google_maps_key';
    }
  }

  // Feature Flags
  static bool get enableSocialFeatures {
    switch (_currentEnvironment) {
      case Environment.development:
        return true;
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }

  static bool get enableOfflineMode {
    switch (_currentEnvironment) {
      case Environment.development:
        return true;
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }

  static bool get enableDebugLogging {
    switch (_currentEnvironment) {
      case Environment.development:
        return true;
      case Environment.staging:
        return true;
      case Environment.production:
        return false;
    }
  }

  static bool get enablePerformanceMonitoring {
    switch (_currentEnvironment) {
      case Environment.development:
        return false;
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }

  // App Configuration
  static String get appName {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'Austin Food Club (Dev)';
      case Environment.staging:
        return 'Austin Food Club (Staging)';
      case Environment.production:
        return 'Austin Food Club';
    }
  }

  static String get appVersion => '1.0.0';
  
  static String get buildNumber {
    switch (_currentEnvironment) {
      case Environment.development:
        return '${DateTime.now().millisecondsSinceEpoch}';
      case Environment.staging:
        return '1000';
      case Environment.production:
        return '1';
    }
  }

  // Cache Configuration
  static Duration get cacheDuration {
    switch (_currentEnvironment) {
      case Environment.development:
        return const Duration(minutes: 30); // Short cache for dev
      case Environment.staging:
        return const Duration(hours: 2);
      case Environment.production:
        return const Duration(hours: 6);
    }
  }

  static int get maxCacheSizeMB {
    switch (_currentEnvironment) {
      case Environment.development:
        return 25;
      case Environment.staging:
        return 50;
      case Environment.production:
        return 100;
    }
  }

  // Upload Configuration
  static int get maxPhotoSizeMB => 5;
  static int get photoQuality => 85;
  static bool get enablePhotoCompression => true;
  
  static bool get enablePhotoWatermark {
    switch (_currentEnvironment) {
      case Environment.development:
        return false;
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }

  // Security Configuration
  static bool get enableCertificatePinning {
    switch (_currentEnvironment) {
      case Environment.development:
        return false;
      case Environment.staging:
        return true;
      case Environment.production:
        return true;
    }
  }

  static bool get enableRootDetection {
    switch (_currentEnvironment) {
      case Environment.development:
        return false;
      case Environment.staging:
        return false;
      case Environment.production:
        return true;
    }
  }

  // Development Tools
  static bool get showDebugBanner {
    return _currentEnvironment == Environment.development;
  }

  static bool get enableFlutterInspector {
    return _currentEnvironment == Environment.development;
  }

  // Database Configuration
  static String get databaseUrl {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'postgresql://dev_user:dev_password@dev-db.austinfoodclub.com:5432/austin_food_club_dev';
      case Environment.staging:
        return 'postgresql://staging_user:staging_password@staging-db.austinfoodclub.com:5432/austin_food_club_staging';
      case Environment.production:
        return 'postgresql://prod_user:prod_password@prod-db.austinfoodclub.com:5432/austin_food_club_prod';
    }
  }

  // Analytics Configuration
  static String get analyticsId {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'dev-analytics-id';
      case Environment.staging:
        return 'staging-analytics-id';
      case Environment.production:
        return 'prod-analytics-id';
    }
  }

  // Error Reporting
  static String get sentryDsn {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'https://your-dev-sentry-dsn@sentry.io/project-id';
      case Environment.staging:
        return 'https://your-staging-sentry-dsn@sentry.io/project-id';
      case Environment.production:
        return 'https://your-prod-sentry-dsn@sentry.io/project-id';
    }
  }

  // Rate Limiting
  static int get maxRequestsPerMinute {
    switch (_currentEnvironment) {
      case Environment.development:
        return 200; // Higher limit for development
      case Environment.staging:
        return 100;
      case Environment.production:
        return 60;
    }
  }

  // Helper methods
  static bool get isDevelopment => _currentEnvironment == Environment.development;
  static bool get isStaging => _currentEnvironment == Environment.staging;
  static bool get isProduction => _currentEnvironment == Environment.production;
  
  static String get environmentName => _currentEnvironment.name;
  
  static Map<String, dynamic> getAllConfig() {
    return {
      'environment': environmentName,
      'apiBaseUrl': apiBaseUrl,
      'supabaseUrl': supabaseUrl,
      'firebaseProjectId': firebaseProjectId,
      'appName': appName,
      'appVersion': appVersion,
      'enableDebugLogging': enableDebugLogging,
      'enableSocialFeatures': enableSocialFeatures,
      'enableOfflineMode': enableOfflineMode,
      'cacheDurationHours': cacheDuration.inHours,
      'maxPhotoSizeMB': maxPhotoSizeMB,
      'photoQuality': photoQuality,
    };
  }

  // Initialize environment based on build mode
  static void initializeForBuild() {
    if (kDebugMode) {
      setEnvironment(Environment.development);
    } else if (kProfileMode) {
      setEnvironment(Environment.staging);
    } else {
      setEnvironment(Environment.production);
    }
  }

  // Override environment (for testing)
  static void overrideEnvironment(Environment environment) {
    if (kDebugMode) {
      _currentEnvironment = environment;
    } else {
      throw Exception('Cannot override environment in release mode');
    }
  }
}

