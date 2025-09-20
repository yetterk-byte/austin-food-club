import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Testing API connection...');
  
  try {
    final response = await http.get(
      Uri.parse('http://localhost:3001/api/restaurants/current'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    
    print('📡 Response status: ${response.statusCode}');
    print('📡 Response headers: ${response.headers}');
    
    if (response.statusCode == 200) {
      print('✅ API call successful!');
      final data = json.decode(response.body);
      print('📊 Restaurant name: ${data['name']}');
      print('📊 Categories type: ${data['categories'].runtimeType}');
      print('📊 Hours type: ${data['hours'].runtimeType}');
      
      // Test parsing
      print('🔄 Testing Restaurant.fromJson...');
      // We'll need to import the model here
    } else {
      print('❌ HTTP ${response.statusCode}: ${response.body}');
    }
  } catch (e) {
    print('❌ Exception: $e');
  }
}
