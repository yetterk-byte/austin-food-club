import 'package:flutter/material.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Social'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey[400],
          tabs: const [
            Tab(text: 'Following'),
            Tab(text: 'City Activity'),
            Tab(text: 'My Friends'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlaceholder(
            icon: Icons.timeline,
            title: 'No activity yet',
            subtitle: 'Your friends\' activity will appear here.',
          ),
          _buildPlaceholder(
            icon: Icons.location_city,
            title: 'No city activity yet',
            subtitle: 'Public activity from Austin Food Club members will appear here.',
          ),
          _buildPlaceholder(
            icon: Icons.people_outline,
            title: 'No friends yet',
            subtitle: 'Find and add friends to get started.',
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 20, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}