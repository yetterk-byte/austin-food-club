import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://ezhrkkmdydgxrzqouyab.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV6aHJra21keWRneHJ6cW91eWFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc4NzQ1NTksImV4cCI6MjA3MzQ1MDU1OX0.XN1rUaoALDhBBS6sIC2kTwI9IIS1AKUq8Jk33BikTnA';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}
