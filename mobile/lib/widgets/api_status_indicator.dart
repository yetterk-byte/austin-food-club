import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ApiStatusIndicator extends StatefulWidget {
  const ApiStatusIndicator({super.key});

  @override
  State<ApiStatusIndicator> createState() => _ApiStatusIndicatorState();
}

class _ApiStatusIndicatorState extends State<ApiStatusIndicator> {
  bool? _isConnected;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isConnected = await ApiService.testConnection();
      setState(() {
        _isConnected = isConnected;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 6),
            Text('Checking...', style: TextStyle(fontSize: 10)),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _checkConnection,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _isConnected == true ? Colors.green[700] : Colors.orange[700],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isConnected == true ? Icons.cloud_done : Icons.cloud_off,
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              _isConnected == true ? 'API Connected' : 'Mock Data',
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
