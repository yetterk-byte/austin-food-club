import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static BuildContext? get context => navigatorKey.currentContext;
  static GoRouter get router => GoRouter.of(context!);

  // Navigation methods
  static void goTo(String path, {Object? extra}) {
    if (context != null) {
      context!.go(path, extra: extra);
    }
  }

  static void goToNamed(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) {
    if (context != null) {
      context!.goNamed(
        name,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
      );
    }
  }

  static void push(String path, {Object? extra}) {
    if (context != null) {
      context!.push(path, extra: extra);
    }
  }

  static Future<T?> pushNamed<T extends Object?>(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) {
    if (context != null) {
      return context!.pushNamed<T>(
        name,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
      );
    }
    return Future.value(null);
  }

  static void pop<T extends Object?>([T? result]) {
    if (context != null) {
      context!.pop(result);
    }
  }

  static void popUntil(String path) {
    if (context != null) {
      while (context!.canPop() && GoRouterState.of(context!).location != path) {
        context!.pop();
      }
    }
  }

  static bool canPop() {
    return context?.canPop() ?? false;
  }

  // Specific navigation methods for the app
  static void goToSplash() {
    goToNamed('splash');
  }

  static void goToAuth() {
    goToNamed('auth');
  }

  static void goToAuthVerify({required String phoneNumber}) {
    goToNamed(
      'auth-verify',
      queryParameters: {'phone': phoneNumber},
    );
  }

  static void goToCurrent() {
    goToNamed('current');
  }

  static void goToDiscover() {
    goToNamed('discover');
  }

  static void goToWishlist() {
    goToNamed('wishlist');
  }

  static void goToProfile() {
    goToNamed('profile');
  }

  static void goToRestaurantDetails({required String restaurantId}) {
    goToNamed(
      'restaurant-details',
      pathParameters: {'id': restaurantId},
    );
  }

  static Future<T?> pushRestaurantDetails<T>({required String restaurantId}) {
    return pushNamed<T>(
      'restaurant-details',
      pathParameters: {'id': restaurantId},
    );
  }

  static Future<T?> pushVerifyVisit<T>({
    required String rsvpId,
    required String restaurantName,
    required DateTime visitDate,
  }) {
    return pushNamed<T>(
      'verify-visit',
      pathParameters: {'rsvpId': rsvpId},
      queryParameters: {
        'restaurant': restaurantName,
        'date': visitDate.toIso8601String(),
      },
    );
  }

  // Bottom navigation methods
  static void switchToTab(int index) {
    switch (index) {
      case 0:
        goToCurrent();
        break;
      case 1:
        goToDiscover();
        break;
      case 2:
        goToWishlist();
        break;
      case 3:
        goToProfile();
        break;
    }
  }

  static int getCurrentTabIndex(String location) {
    if (location.startsWith('/main/current')) return 0;
    if (location.startsWith('/main/discover')) return 1;
    if (location.startsWith('/main/wishlist')) return 2;
    if (location.startsWith('/main/profile')) return 3;
    return 0; // Default to current tab
  }

  // Modal and dialog methods
  static Future<T?> showModal<T>(
    Widget child, {
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
  }) {
    if (context == null) return Future.value(null);
    
    return showModalBottomSheet<T>(
      context: context!,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      isScrollControlled: true,
      builder: (context) => child,
    );
  }

  static Future<T?> showFullScreenModal<T>(Widget child) {
    if (context == null) return Future.value(null);
    
    return Navigator.of(context!).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  static Future<T?> showDialog<T>(
    Widget child, {
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    if (context == null) return Future.value(null);
    
    return showGeneralDialog<T>(
      context: context!,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black.withOpacity(0.5),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
    );
  }

  // Utility methods
  static String getCurrentLocation() {
    return GoRouterState.of(context!).location;
  }

  static Map<String, String> getCurrentPathParameters() {
    return GoRouterState.of(context!).pathParameters;
  }

  static Map<String, dynamic> getCurrentQueryParameters() {
    return GoRouterState.of(context!).queryParameters;
  }

  static void clearAndNavigateTo(String path) {
    if (context != null) {
      while (context!.canPop()) {
        context!.pop();
      }
      context!.go(path);
    }
  }

  // Deep link handling
  static Future<void> handleDeepLink(String link) async {
    // Parse the deep link and navigate accordingly
    final uri = Uri.parse(link);
    
    switch (uri.pathSegments.first) {
      case 'restaurant':
        if (uri.pathSegments.length > 1) {
          goToRestaurantDetails(restaurantId: uri.pathSegments[1]);
        }
        break;
      case 'verify-visit':
        if (uri.pathSegments.length > 1) {
          final rsvpId = uri.pathSegments[1];
          final restaurantName = uri.queryParameters['restaurant'] ?? '';
          final visitDate = DateTime.tryParse(uri.queryParameters['date'] ?? '') ?? DateTime.now();
          
          pushVerifyVisit(
            rsvpId: rsvpId,
            restaurantName: restaurantName,
            visitDate: visitDate,
          );
        }
        break;
      case 'profile':
        goToProfile();
        break;
      case 'wishlist':
        goToWishlist();
        break;
      case 'discover':
        goToDiscover();
        break;
      default:
        goToCurrent();
        break;
    }
  }
}

