import 'package:flutter/material.dart';
import '../services/restaurant_service.dart';
import '../models/restaurant.dart';
import '../widgets/rsvp_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Restaurant? featuredRestaurant;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedRestaurant();
  }

  Future<void> _loadFeaturedRestaurant() async {
    try {
      // For now, always use Austin (future: could be dynamic based on user location/preference)
      final restaurant = await RestaurantService.getFeaturedRestaurant(citySlug: 'austin');
      setState(() {
        featuredRestaurant = restaurant;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Austin Food Club',
          style: TextStyle(
            fontFamily: 'Monoton',
            fontSize: 24,
            letterSpacing: 2.0,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.orange,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : featuredRestaurant != null
              ? SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Featured Restaurant Card
                      Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Restaurant Image
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  image: featuredRestaurant!.imageUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(featuredRestaurant!.imageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  color: Colors.grey[800],
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                    ),
                                  ),
                                  child: const Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Icon(
                                        Icons.star,
                                        color: Colors.orange,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Restaurant Info
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      featuredRestaurant!.name,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      featuredRestaurant!.address,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${featuredRestaurant!.rating}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${featuredRestaurant!.reviewCount} reviews)',
                                          style: TextStyle(
                                            color: Colors.grey[300],
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          featuredRestaurant!.price ?? 'N/A',
                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // RSVP Section
                      RSVPSection(restaurant: featuredRestaurant!),
                    ],
                  ),
                )
              : const Center(
                  child: Text(
                    'No featured restaurant this week',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ),
    );
  }
}
