import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/restaurant.dart';
import '../services/mock_data_service.dart';

class FriendProfileScreen extends StatefulWidget {
  final User friend;
  
  const FriendProfileScreen({
    super.key,
    required this.friend,
  });

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
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
      // Generate mock verified visits for the friend based on their ID
      final restaurants = await MockDataService.getAllRestaurantsMock();
      
      // Create different verified visits based on friend ID
      switch (widget.friend.id) {
        case '3': // Sarah Johnson
          verifiedVisits = [
            VerifiedVisit(
              restaurant: restaurants[0],
              visitDate: DateTime.now().subtract(const Duration(days: 2)),
              rating: 4.5,
              photoUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=300&fit=crop',
              review: 'Amazing BBQ and great atmosphere!',
            ),
            VerifiedVisit(
              restaurant: restaurants[1],
              visitDate: DateTime.now().subtract(const Duration(days: 8)),
              rating: 4.8,
              photoUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&h=300&fit=crop',
              review: 'Worth the wait! Best brisket in Austin.',
            ),
            VerifiedVisit(
              restaurant: restaurants[2],
              visitDate: DateTime.now().subtract(const Duration(days: 15)),
              rating: 4.3,
              photoUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400&h=300&fit=crop',
              review: 'Creative sushi and amazing service!',
            ),
            VerifiedVisit(
              restaurant: restaurants[0],
              visitDate: DateTime.now().subtract(const Duration(days: 22)),
              rating: 4.6,
              photoUrl: 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=400&h=300&fit=crop',
              review: 'Perfect fusion of Asian and BBQ flavors!',
            ),
            VerifiedVisit(
              restaurant: restaurants[1],
              visitDate: DateTime.now().subtract(const Duration(days: 30)),
              rating: 4.7,
              photoUrl: 'https://images.unsplash.com/photo-1558030006-450675393462?w=400&h=300&fit=crop',
              review: 'Best brisket in Austin. Worth the wait!',
            ),
            VerifiedVisit(
              restaurant: restaurants[2],
              visitDate: DateTime.now().subtract(const Duration(days: 37)),
              rating: 4.4,
              photoUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400&h=300&fit=crop',
              review: 'Incredible sushi and presentation.',
            ),
            VerifiedVisit(
              restaurant: restaurants[0],
              visitDate: DateTime.now().subtract(const Duration(days: 45)),
              rating: 4.5,
              photoUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=300&fit=crop',
              review: 'Amazing handmade tortillas and great atmosphere!',
            ),
            VerifiedVisit(
              restaurant: restaurants[1],
              visitDate: DateTime.now().subtract(const Duration(days: 52)),
              rating: 4.9,
              photoUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&h=300&fit=crop',
              review: 'Absolutely perfect BBQ experience!',
            ),
          ];
          break;
        case '4': // Mike Chen
          verifiedVisits = [
            VerifiedVisit(
              restaurant: restaurants[2],
              visitDate: DateTime.now().subtract(const Duration(days: 5)),
              rating: 4.9,
              photoUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400&h=300&fit=crop',
              review: 'Incredible omakase experience!',
            ),
            VerifiedVisit(
              restaurant: restaurants[1],
              visitDate: DateTime.now().subtract(const Duration(days: 12)),
              rating: 4.6,
              photoUrl: 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=400&h=300&fit=crop',
              review: 'Perfect fusion of Asian and BBQ flavors!',
            ),
            VerifiedVisit(
              restaurant: restaurants[0],
              visitDate: DateTime.now().subtract(const Duration(days: 19)),
              rating: 4.7,
              photoUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=300&fit=crop',
              review: 'Amazing BBQ and great atmosphere!',
            ),
            VerifiedVisit(
              restaurant: restaurants[2],
              visitDate: DateTime.now().subtract(const Duration(days: 26)),
              rating: 4.8,
              photoUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400&h=300&fit=crop',
              review: 'Creative sushi and amazing service!',
            ),
            VerifiedVisit(
              restaurant: restaurants[1],
              visitDate: DateTime.now().subtract(const Duration(days: 33)),
              rating: 4.5,
              photoUrl: 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=400&h=300&fit=crop',
              review: 'Perfect fusion of Asian and BBQ flavors!',
            ),
            VerifiedVisit(
              restaurant: restaurants[0],
              visitDate: DateTime.now().subtract(const Duration(days: 40)),
              rating: 4.6,
              photoUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=300&fit=crop',
              review: 'Amazing BBQ and great atmosphere!',
            ),
            VerifiedVisit(
              restaurant: restaurants[2],
              visitDate: DateTime.now().subtract(const Duration(days: 47)),
              rating: 4.9,
              photoUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400&h=300&fit=crop',
              review: 'Incredible omakase experience!',
            ),
            VerifiedVisit(
              restaurant: restaurants[1],
              visitDate: DateTime.now().subtract(const Duration(days: 54)),
              rating: 4.7,
              photoUrl: 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=400&h=300&fit=crop',
              review: 'Perfect fusion of Asian and BBQ flavors!',
            ),
            VerifiedVisit(
              restaurant: restaurants[0],
              visitDate: DateTime.now().subtract(const Duration(days: 61)),
              rating: 4.8,
              photoUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=300&fit=crop',
              review: 'Amazing BBQ and great atmosphere!',
            ),
            VerifiedVisit(
              restaurant: restaurants[2],
              visitDate: DateTime.now().subtract(const Duration(days: 68)),
              rating: 4.9,
              photoUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400&h=300&fit=crop',
              review: 'Incredible omakase experience!',
            ),
            VerifiedVisit(
              restaurant: restaurants[1],
              visitDate: DateTime.now().subtract(const Duration(days: 75)),
              rating: 4.6,
              photoUrl: 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=400&h=300&fit=crop',
              review: 'Perfect fusion of Asian and BBQ flavors!',
            ),
            VerifiedVisit(
              restaurant: restaurants[0],
              visitDate: DateTime.now().subtract(const Duration(days: 82)),
              rating: 4.7,
              photoUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=300&fit=crop',
              review: 'Amazing BBQ and great atmosphere!',
            ),
          ];
          break;
        case '5': // Alex Rivera
          verifiedVisits = [
            VerifiedVisit(
              restaurant: restaurants[0],
              visitDate: DateTime.now().subtract(const Duration(days: 7)),
              rating: 4.0,
              photoUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=300&fit=crop',
              review: 'Good BBQ, nice atmosphere.',
            ),
            VerifiedVisit(
              restaurant: restaurants[1],
              visitDate: DateTime.now().subtract(const Duration(days: 21)),
              rating: 4.2,
              photoUrl: 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=400&h=300&fit=crop',
              review: 'Interesting fusion concept.',
            ),
            VerifiedVisit(
              restaurant: restaurants[2],
              visitDate: DateTime.now().subtract(const Duration(days: 35)),
              rating: 4.1,
              photoUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400&h=300&fit=crop',
              review: 'Decent sushi, good service.',
            ),
          ];
          break;
        case '6': // Emma Wilson
          verifiedVisits = [
            VerifiedVisit(
              restaurant: restaurants[1],
              visitDate: DateTime.now().subtract(const Duration(days: 7)),
              rating: 4.3,
              photoUrl: 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=400&h=300&fit=crop',
              review: 'Perfect fusion of Asian and BBQ flavors!',
            ),
            VerifiedVisit(
              restaurant: restaurants[0],
              visitDate: DateTime.now().subtract(const Duration(days: 14)),
              rating: 4.4,
              photoUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=300&fit=crop',
              review: 'Amazing BBQ and great atmosphere!',
            ),
            VerifiedVisit(
              restaurant: restaurants[2],
              visitDate: DateTime.now().subtract(const Duration(days: 21)),
              rating: 4.5,
              photoUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400&h=300&fit=crop',
              review: 'Incredible sushi and presentation.',
            ),
            VerifiedVisit(
              restaurant: restaurants[1],
              visitDate: DateTime.now().subtract(const Duration(days: 28)),
              rating: 4.2,
              photoUrl: 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=400&h=300&fit=crop',
              review: 'Perfect fusion of Asian and BBQ flavors!',
            ),
            VerifiedVisit(
              restaurant: restaurants[0],
              visitDate: DateTime.now().subtract(const Duration(days: 35)),
              rating: 4.6,
              photoUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=300&fit=crop',
              review: 'Amazing BBQ and great atmosphere!',
            ),
          ];
          break;
        case '7': // David Martinez
          verifiedVisits = [
            VerifiedVisit(
              restaurant: restaurants[0],
              visitDate: DateTime.now().subtract(const Duration(days: 3)),
              rating: 4.7,
              photoUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=300&fit=crop',
              review: 'Amazing BBQ and great atmosphere!',
            ),
            VerifiedVisit(
              restaurant: restaurants[1],
              visitDate: DateTime.now().subtract(const Duration(days: 10)),
              rating: 4.5,
              photoUrl: 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=400&h=300&fit=crop',
              review: 'Perfect fusion of Asian and BBQ flavors!',
            ),
            VerifiedVisit(
              restaurant: restaurants[2],
              visitDate: DateTime.now().subtract(const Duration(days: 17)),
              rating: 4.8,
              photoUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400&h=300&fit=crop',
              review: 'Incredible sushi and presentation.',
            ),
            VerifiedVisit(
              restaurant: restaurants[0],
              visitDate: DateTime.now().subtract(const Duration(days: 24)),
              rating: 4.6,
              photoUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=300&fit=crop',
              review: 'Amazing BBQ and great atmosphere!',
            ),
            VerifiedVisit(
              restaurant: restaurants[1],
              visitDate: DateTime.now().subtract(const Duration(days: 31)),
              rating: 4.4,
              photoUrl: 'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=400&h=300&fit=crop',
              review: 'Perfect fusion of Asian and BBQ flavors!',
            ),
            VerifiedVisit(
              restaurant: restaurants[2],
              visitDate: DateTime.now().subtract(const Duration(days: 38)),
              rating: 4.9,
              photoUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400&h=300&fit=crop',
              review: 'Incredible sushi and presentation.',
            ),
            VerifiedVisit(
              restaurant: restaurants[0],
              visitDate: DateTime.now().subtract(const Duration(days: 45)),
              rating: 4.5,
              photoUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400&h=300&fit=crop',
              review: 'Amazing BBQ and great atmosphere!',
            ),
          ];
          break;
        default:
          verifiedVisits = [];
      }
      
      setState(() {
        // Trigger UI update to show the new verified visits count
      });
    } catch (e) {
      print('Error loading verified visits: $e');
      setState(() {
        verifiedVisits = [];
      });
    }
  }

  Future<void> _loadFriendCount() async {
    try {
      // Mock friend count based on friend ID
      switch (widget.friend.id) {
        case '3': // Sarah Johnson
          friendCount = 12;
          break;
        case '4': // Mike Chen
          friendCount = 8;
          break;
        case '5': // Alex Rivera
          friendCount = 5;
          break;
        case '6': // Emma Wilson
          friendCount = 15;
          break;
        case '7': // David Martinez
          friendCount = 10;
          break;
        default:
          friendCount = 0;
      }
      
      setState(() {
        // Trigger UI update
      });
    } catch (e) {
      print('Error loading friend count: $e');
    }
  }

  Future<void> _loadFavoriteRestaurant() async {
    try {
      // Set favorite restaurant based on friend ID
      final restaurants = await MockDataService.getAllRestaurantsMock();
      switch (widget.friend.id) {
        case '3': // Sarah Johnson
          favoriteRestaurant = restaurants[1]; // Franklin Barbecue
          break;
        case '4': // Mike Chen
          favoriteRestaurant = restaurants[2]; // Uchi
          break;
        case '5': // Alex Rivera
          favoriteRestaurant = restaurants[0]; // Sundance BBQ
          break;
        case '6': // Emma Wilson
          favoriteRestaurant = restaurants[1]; // Loro
          break;
        case '7': // David Martinez
          favoriteRestaurant = restaurants[2]; // Uchi
          break;
        default:
          favoriteRestaurant = restaurants[0];
      }
      
      setState(() {
        // Trigger UI update
      });
    } catch (e) {
      print('Error loading favorite restaurant: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.friend.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Friend Header
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
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.orange,
                        child: Text(
                          widget.friend.initials,
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
                              widget.friend.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Member since ${widget.friend.memberSince}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Verification badge
                            if (widget.friend.isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified, color: Colors.green, size: 16),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Verified',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Verified Visits', verifiedVisits.length.toString(), Icons.verified),
                      _buildStatItem('Avg Rating', averageRating.toString(), Icons.star),
                      _buildStatItem('Friends', friendCount.toString(), Icons.people),
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
                            'This friend hasn\'t verified any visits yet!',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              visit.restaurant.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
                  visit.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
