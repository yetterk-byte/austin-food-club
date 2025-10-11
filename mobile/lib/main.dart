import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/main_app.dart';
import 'config/app_theme.dart';
import 'services/auth_storage.dart';

void main() async {
  // Add error handler to catch all errors
  FlutterError.onError = (FlutterErrorDetails details) {
    print('🔴 Flutter Error: ${details.exception}');
    print('🔴 Stack trace: ${details.stack}');
    FlutterError.presentError(details);
  };
  
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const AustinFoodClubApp());
}

class AustinFoodClubApp extends StatelessWidget {
  const AustinFoodClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Austin Food Club',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: AuthStorage.hasToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.orange),
              ),
            );
          }
          final bool hasToken = snapshot.data == true;
          return hasToken ? const MainApp() : const AuthScreen();
        },
      ),
    );
  }
}