import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/restaurant.dart';
import '../services/mock_data_service.dart';
import '../services/social_service.dart';
import '../providers/auth_provider.dart';
// import 'photo_verification_screen.dart'; // Temporarily disabled

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int totalVisits = 12;
  final double averageRating = 4.2;
  int friendCount = 0;
  
  List<VerifiedVisit> verifiedVisits = [];
  Restaurant? favoriteRestaurant;

  @override
  void initState() {
    super.initState();
    _loadVerifiedVisits();
    _loadFriendCount();
    _loadFavoriteRestaurant();
  }

  Future<void> _loadVerifiedVisits() async {
    try {
      // Mock verified visits using mock restaurants directly
      final restaurants = MockDataService.getAllRestaurantsMock();
      verifiedVisits = [
        VerifiedVisit(
          restaurant: restaurants[0],
          visitDate: DateTime.now().subtract(const Duration(days: 3)),
          rating: 5.0,
          photoUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400&h=300&fit=crop',
          review: 'Amazing handmade tortillas and great atmosphere!',
        ),
        VerifiedVisit(
          restaurant: restaurants[1],
          visitDate: DateTime.now().subtract(const Duration(days: 10)),
          rating: 4.5,
          photoUrl: 'https://images.unsplash.com/photo-1558030006-450675393462?w=400&h=300&fit=crop',
          review: 'Best brisket in Austin. Worth the wait!',
        ),
        VerifiedVisit(
          restaurant: restaurants[2],
          visitDate: DateTime.now().subtract(const Duration(days: 18)),
          rating: 4.0,
          photoUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400&h=300&fit=crop',
          review: 'Incredible sushi and presentation.',
        ),
      ];
    } catch (e) {
      print('Error loading verified visits: $e');
    }
  }

  Future<void> _loadFriendCount() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id ?? '1';
      final friends = await SocialService.getFriends(userId);
      
      setState(() {
        friendCount = friends.length;
      });
    } catch (e) {
      print('Error loading friend count: $e');
    }
  }

  Future<void> _loadFavoriteRestaurant() async {
    try {
      // For now, use mock data - in production this would come from user preferences
      final restaurants = MockDataService.getAllRestaurantsMock();
      setState(() {
        favoriteRestaurant = restaurants[2]; // Default to Uchi as favorite
      });
    } catch (e) {
      print('Error loading favorite restaurant: $e');
    }
  }

  void _showPhotoVerificationModal() {
    // Temporarily disabled - photo verification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo verification coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showRestaurantSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Your Favorite Restaurant',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 16),
              ...MockDataService.getAllRestaurantsMock().map((restaurant) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Text(
                      restaurant.name.substring(0, 1),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(restaurant.name),
                  subtitle: Text(restaurant.categories?.first.title ?? 'Restaurant'),
                  trailing: favoriteRestaurant?.id == restaurant.id
                      ? const Icon(Icons.favorite, color: Colors.white) // Filled for current favorite
                      : const Icon(Icons.favorite_border, color: Colors.white), // Outline for options
                  onTap: () {
                    setState(() {
                      favoriteRestaurant = restaurant;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${restaurant.name} set as favorite!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                );
              }).toList(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                children: [
                  // Avatar and basic info
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final user = authProvider.currentUser;
                      if (user == null) return const SizedBox.shrink();
                      
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.orange,
                            child: Text(
                              user.initials,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Member since ${user.memberSince}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    // TODO: Edit profile
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(120, 36),
                                  ),
                                  child: const Text('Edit Profile'),
                                ),
                              ],
                            ),
                          ),
                          // Settings menu
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'settings') {
                                // TODO: Navigate to settings
                              } else if (value == 'signout') {
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                await authProvider.signOut();
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'settings',
                                child: Row(
                                  children: [
                                    Icon(Icons.settings, size: 20),
                                    SizedBox(width: 12),
                                    Text('Settings'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'signout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, size: 20, color: Colors.red),
                                    SizedBox(width: 12),
                                    Text('Sign Out', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Events', totalVisits.toString(), Icons.event),
                      _buildStatItem('Avg Rating', averageRating.toString(), Icons.star),
                      _buildStatItem('Friends', friendCount.toString(), Icons.people),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Verify Visit',
                          Icons.camera_alt,
                          Colors.orange,
                          _showPhotoVerificationModal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          'Share Profile',
                          Icons.share,
                          Colors.blue,
                          () {
                            // TODO: Share profile
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Favorite Restaurant - Full Photo with Overlay
            if (favoriteRestaurant != null)
              _buildFavoriteRestaurantCard(favoriteRestaurant!)
            else
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  maxHeight: 300, // Reasonable max height
                ),
                child: AspectRatio(
                  aspectRatio: 1.0, // Perfect square
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[600]!, width: 2),
                    ),
                    child: Stack(
                      children: [
                        // Background pattern or placeholder
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.grey[800]!,
                                Colors.grey[900]!,
                              ],
                            ),
                          ),
                        ),
                        // "Favorite Restaurant" title overlay
                        Positioned(
                          top: 20,
                          left: 20,
                          right: 20,
                          child: const Text(
                            'Favorite Restaurant',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Center content
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite_border,
                                size: 60,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No favorite selected',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap ♡ on any verified visit',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            
            // Verified Visits
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Verified Visits',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        '${verifiedVisits.length} visits',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (verifiedVisits.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 48,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No verified visits yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Join weekly events and verify your attendance!',
                            style: TextStyle(
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: verifiedVisits.length,
                      itemBuilder: (context, index) {
                        final visit = verifiedVisits[index];
                        return _buildVerifiedVisitCard(visit);
                      },
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 100), // Bottom padding for navigation
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
                    fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteRestaurantCard(Restaurant restaurant) {
    return AspectRatio(
      aspectRatio: 1.0, // Perfect square
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.4), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background restaurant image
              Image.network(
                restaurant.imageUrl ?? 'https://via.placeholder.com/400x400?text=Restaurant',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: Icon(Icons.restaurant, size: 60, color: Colors.white54),
                    ),
                  );
                },
              ),
              // Gradient overlay for text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7), // Darker at top for titles
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.8), // Darker at bottom for details
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
              // "Favorite Restaurant" title at top-left
              Positioned(
                top: 20,
                left: 20,
                right: 80, // Leave space for heart
                child: Text(
                  'Favorite Restaurant',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
              // Favorite heart badge (top-right)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              // Bottom content - name, cuisine and stars
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Restaurant name
                    Text(
                      restaurant.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 6,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Cuisine type
                    Text(
                      restaurant.categories?.first.title ?? 'Restaurant',
                      style: TextStyle(
                        color: Colors.orange.shade300,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Star rating
                    Row(
                      children: List.generate(5, (index) {
                        final rating = restaurant.rating ?? 0.0;
                        return Icon(
                          index < rating.floor()
                              ? Icons.star
                              : (index < rating ? Icons.star_half : Icons.star_border),
                          color: Colors.white,
                          size: 18,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildVerifiedVisitCard(VerifiedVisit visit) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(visit.photoUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            // Heart button in top-right
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    favoriteRestaurant = visit.restaurant;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${visit.restaurant.name} set as favorite!'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: favoriteRestaurant?.id == visit.restaurant.id
                        ? Colors.red.withOpacity(0.9) // Red background for favorite
                        : Colors.transparent, // Transparent for clickable hearts
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6), // White border for all
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    favoriteRestaurant?.id == visit.restaurant.id
                        ? Icons.favorite // Filled heart for current favorite
                        : Icons.favorite_border, // Outline heart for clickable options
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
            // Content at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Text(
              visit.restaurant.name,
              style: const TextStyle(
                fontSize: 14,
                    fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < visit.rating.floor()
                        ? Icons.star
                        : (index < visit.rating ? Icons.star_half : Icons.star_border),
                    color: Colors.white,
                    size: 12,
                  );
                }),
                const SizedBox(width: 4),
                Text(
                  visit.rating.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
                  Text(
                    _formatDate(visit.visitDate),
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }
}

// Models for verified visits
class VerifiedVisit {
  final Restaurant restaurant;
  final DateTime visitDate;
  final double rating;
  final String photoUrl;
  final String review;

  VerifiedVisit({
    required this.restaurant,
    required this.visitDate,
    required this.rating,
    required this.photoUrl,
    required this.review,
  });
}

