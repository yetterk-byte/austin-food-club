import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/main/main_shell.dart';
import '../screens/main/current_screen.dart';
import '../screens/discover/discover_screen.dart';
import '../screens/wishlist/wishlist_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/restaurant/restaurant_details_screen.dart';
import '../screens/profile/verify_visit_screen.dart';
import '../providers/auth_provider.dart';
import '../services/navigation_service.dart';

class AppRoutes {
  // Route paths
  static const String splash = '/';
  static const String auth = '/auth';
  static const String authVerify = '/auth/verify';
  static const String main = '/main';
  static const String current = '/main/current';
  static const String discover = '/main/discover';
  static const String wishlist = '/main/wishlist';
  static const String profile = '/main/profile';
  static const String restaurantDetails = '/restaurant/:id';
  static const String verifyVisit = '/verify-visit/:rsvpId';

  // Router configuration
  static final GoRouter router = GoRouter(
    navigatorKey: NavigationService.navigatorKey,
    initialLocation: splash,
    debugLogDiagnostics: true,
    redirect: _redirect,
    routes: [
      // Splash Screen
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: auth,
        name: 'auth',
        builder: (context, state) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'verify',
            name: 'auth-verify',
            builder: (context, state) => OTPScreen(
              phoneNumber: state.queryParameters['phone'] ?? '',
            ),
          ),
        ],
      ),

      // Main App Shell with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: current,
            name: 'current',
            pageBuilder: (context, state) => _buildPageWithTransition(
              state,
              const CurrentScreen(),
              TransitionType.none,
            ),
          ),
          GoRoute(
            path: discover,
            name: 'discover',
            pageBuilder: (context, state) => _buildPageWithTransition(
              state,
              const DiscoverScreen(),
              TransitionType.none,
            ),
          ),
          GoRoute(
            path: wishlist,
            name: 'wishlist',
            pageBuilder: (context, state) => _buildPageWithTransition(
              state,
              const WishlistScreen(),
              TransitionType.none,
            ),
          ),
          GoRoute(
            path: profile,
            name: 'profile',
            pageBuilder: (context, state) => _buildPageWithTransition(
              state,
              const ProfileScreen(),
              TransitionType.none,
            ),
          ),
        ],
      ),

      // Restaurant Details
      GoRoute(
        path: '/restaurant/:id',
        name: 'restaurant-details',
        pageBuilder: (context, state) {
          final restaurantId = state.pathParameters['id']!;
          return _buildPageWithTransition(
            state,
            RestaurantDetailsScreen(restaurantId: restaurantId),
            TransitionType.slide,
          );
        },
      ),

      // Verify Visit Flow
      GoRoute(
        path: '/verify-visit/:rsvpId',
        name: 'verify-visit',
        pageBuilder: (context, state) {
          final rsvpId = state.pathParameters['rsvpId']!;
          final restaurantName = state.queryParameters['restaurant'] ?? '';
          final visitDate = state.queryParameters['date'] ?? '';
          
          return _buildPageWithTransition(
            state,
            VerifyVisitScreen(
              rsvpId: rsvpId,
              restaurantName: restaurantName,
              visitDate: DateTime.tryParse(visitDate) ?? DateTime.now(),
            ),
            TransitionType.modal,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );

  // Route guard logic
  static String? _redirect(BuildContext context, GoRouterState state) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = authProvider.isAuthenticated;
    final isLoggingIn = state.location == auth || state.location.startsWith('/auth');
    final isSplash = state.location == splash;

    // Show splash screen first
    if (isSplash) {
      return null;
    }

    // If not logged in and not on auth pages, redirect to auth
    if (!isLoggedIn && !isLoggingIn) {
      return auth;
    }

    // If logged in and on auth pages, redirect to main
    if (isLoggedIn && isLoggingIn) {
      return current;
    }

    // If logged in and on splash, redirect to main
    if (isLoggedIn && isSplash) {
      return current;
    }

    return null;
  }

  // Page transition builder
  static Page<dynamic> _buildPageWithTransition(
    GoRouterState state,
    Widget child,
    TransitionType transitionType,
  ) {
    switch (transitionType) {
      case TransitionType.slide:
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
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
        );

      case TransitionType.modal:
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );

      case TransitionType.fade:
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );

      case TransitionType.none:
      default:
        return NoTransitionPage<void>(
          key: state.pageKey,
          child: child,
        );
    }
  }
}

// Transition types
enum TransitionType {
  slide,
  modal,
  fade,
  none,
}

// Custom transition page
class CustomTransitionPage<T> extends Page<T> {
  final Widget child;
  final RouteTransitionsBuilder transitionsBuilder;

  const CustomTransitionPage({
    required this.child,
    required this.transitionsBuilder,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, _) => child,
      transitionsBuilder: transitionsBuilder,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }
}

// No transition page
class NoTransitionPage<T> extends Page<T> {
  final Widget child;

  const NoTransitionPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, _) => child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}

// Error screen
class ErrorScreen extends StatelessWidget {
  final Exception? error;

  const ErrorScreen({
    super.key,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                NavigationService.goToNamed('current');
              },
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}