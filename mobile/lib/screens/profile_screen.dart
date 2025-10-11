import 'package:flutter/material.dart';
import '../models/verified_visit.dart';
import '../services/verified_visits_service.dart';
import '../services/wishlist_service.dart';
import '../models/restaurant.dart';
import '../services/restaurant_service.dart';
import 'photo_verification_screen.dart';
import 'select_restaurant_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<VerifiedVisit> verifiedVisits = [];
  List<dynamic> favorites = [];
  bool isLoading = true;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _loadVerifiedVisits();
    _loadFavorites();
  }

  Future<void> _loadVerifiedVisits() async {
    try {
      final visits = await VerifiedVisitsService.getMyVisits(limit: 20);
      setState(() {
        verifiedVisits = visits;
        isLoading = false;
      });

      // Seed a couple of sample visits for test user if none exist
      if (verifiedVisits.isEmpty && !_seeded) {
        _seeded = true;
        await _seedSampleVisits();
        final refreshed = await VerifiedVisitsService.getMyVisits(limit: 20);
        setState(() {
          verifiedVisits = refreshed;
        });
      }
    } catch (e) {
      print('Error loading verified visits: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _seedSampleVisits() async {
    try {
      final featured = await RestaurantService.getFeaturedRestaurant();
      if (featured != null) {
        await VerifiedVisitsService.createVerifiedVisit(
          restaurantId: featured.id,
          restaurantName: featured.name,
          restaurantAddress: featured.address,
          rating: 5,
          photoUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800',
        );
      }
    } catch (e) {
      print('Seed visits error: $e');
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final favs = await WishlistService.getMyFavorites(limit: 50);
      setState(() {
        favorites = favs;
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.orange,
                    child: Text(
                      'TU',
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
                          'Test User',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'test@example.com',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile Stats (Verified Visits, Avg Rating, Friends)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Verified Visits', verifiedVisits.length.toString(), Icons.verified),
                  _buildStatItem(
                    'Avg Rating',
                    verifiedVisits.isEmpty
                        ? '-'
                        : (verifiedVisits
                                .map((v) => v.rating)
                                .fold<int>(0, (sum, r) => sum + r) /
                            verifiedVisits.length)
                            .toStringAsFixed(1),
                    Icons.star,
                  ),
                  _buildStatItem('Friends', '0', Icons.people),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Verify Visit (moved above Favorites)
            _buildVerifyVisitBox(context),
            const SizedBox(height: 24),

            // Favorites (Wishlist)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Favorite Restaurants',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (favorites.isEmpty)
                    Text('No favorites yet', style: TextStyle(color: Colors.grey[400]))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 3 / 2,
                      ),
                      itemCount: favorites.length.clamp(0, 4),
                      itemBuilder: (context, index) {
                        final r = favorites[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                r.imageUrl ?? 'https://via.placeholder.com/300x200',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(color: Colors.grey[800]),
                              ),
                              Container(color: Colors.black45),
                              Positioned(
                                left: 8,
                                right: 8,
                                bottom: 8,
                                child: Text(
                                  r.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Verified Visits
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Verified Visits',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (verifiedVisits.isEmpty)
                    const Center(
                      child: Text(
                        'No verified visits yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...verifiedVisits.take(5).map((visit) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              visit.imageUrl ?? 'https://via.placeholder.com/60x60',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.restaurant, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  visit.restaurantName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  visit.restaurantAddress,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                Row(
                                  children: [
                                    ...List.generate(5, (index) => Icon(
                                      index < visit.rating ? Icons.star : Icons.star_border,
                                      size: 16,
                                      color: Colors.orange,
                                    )),
                                    const SizedBox(width: 8),
                                    Text(
                                      visit.formattedDate,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                ],
              ),
            ),
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
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyVisitBox(BuildContext context) {
    return Container
    (
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verify a Visit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text('Choose a restaurant to verify your visit with a photo and rating.', style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openVerifyModal(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Verify Visit'),
            ),
          ),
        ],
      ),
    );
  }

  void _openVerifyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Verify a Visit',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text('Choose how you want to verify your visit:', style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.star_rate_rounded, color: Colors.orange),
                title: const Text('Featured Restaurant', style: TextStyle(color: Colors.white)),
                subtitle: Text('Verify the current featured restaurant', style: TextStyle(color: Colors.grey[400])),
                onTap: () async {
                  Navigator.pop(context);
                  final featured = await RestaurantService.getFeaturedRestaurant();
                  if (featured != null) {
                    // ignore: use_build_context_synchronously
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PhotoVerificationScreen(restaurant: featured)));
                  } else {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No featured restaurant available'), backgroundColor: Colors.red),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.restaurant_rounded, color: Colors.white),
                title: const Text('Any Restaurant', style: TextStyle(color: Colors.white)),
                subtitle: Text('Search and select any restaurant', style: TextStyle(color: Colors.grey[400])),
                onTap: () async {
                  Navigator.pop(context);
                  final selected = await Navigator.push<Restaurant>(context, MaterialPageRoute(builder: (_) => const SelectRestaurantScreen()));
                  if (selected != null) {
                    // ignore: use_build_context_synchronously
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PhotoVerificationScreen(restaurant: selected)));
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}