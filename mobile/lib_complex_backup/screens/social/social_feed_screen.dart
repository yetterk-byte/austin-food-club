import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/social_provider.dart';
import '../../widgets/social/social_feed_item_widget.dart';
import '../../widgets/social/trending_restaurants_widget.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/error_view.dart';
import '../../services/navigation_service.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().loadSocialFeed();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Tab bar
            _buildTabBar(),
            
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFeedTab(),
                  _buildTrendingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Social Feed',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'See what your friends are eating',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => NavigationService.goToNamed('friends'),
            icon: Stack(
              children: [
                const Icon(
                  Icons.person_add,
                  color: Colors.white,
                  size: 24,
                ),
                Consumer<SocialProvider>(
                  builder: (context, socialProvider, child) {
                    final pendingCount = socialProvider.pendingRequestsCount;
                    if (pendingCount > 0) {
                      return Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            pendingCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade400,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 16,
        ),
        tabs: const [
          Tab(text: 'Feed'),
          Tab(text: 'Trending'),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        if (socialProvider.isFeedLoading && socialProvider.socialFeed.isEmpty) {
          return _buildLoadingState();
        }

        if (socialProvider.error != null && socialProvider.socialFeed.isEmpty) {
          return _buildErrorState(socialProvider.error!);
        }

        if (socialProvider.socialFeed.isEmpty) {
          return _buildEmptyFeedState();
        }

        return RefreshIndicator(
          onRefresh: () => socialProvider.loadSocialFeed(refresh: true),
          color: Colors.orange,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: socialProvider.socialFeed.length,
            itemBuilder: (context, index) {
              final item = socialProvider.socialFeed[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SocialFeedItemWidget(
                  item: item,
                  onLike: () => socialProvider.likeFeedItem(item.id),
                  onUnlike: () => socialProvider.unlikeFeedItem(item.id),
                  onTap: () => _handleFeedItemTap(item),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTrendingTab() {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        if (socialProvider.isFeedLoading && socialProvider.trendingRestaurants.isEmpty) {
          return _buildLoadingState();
        }

        if (socialProvider.error != null && socialProvider.trendingRestaurants.isEmpty) {
          return _buildErrorState(socialProvider.error!);
        }

        if (socialProvider.trendingRestaurants.isEmpty) {
          return _buildEmptyTrendingState();
        }

        return RefreshIndicator(
          onRefresh: () => socialProvider.loadSocialFeed(refresh: true),
          color: Colors.orange,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: TrendingRestaurantsWidget(
              trendingItems: socialProvider.trendingRestaurants,
              onRestaurantTap: (restaurantId) {
                NavigationService.goToRestaurantDetails(restaurantId: restaurantId);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ShimmerContainer(
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return ErrorViewVariants.server(
      customMessage: error,
      onRetry: () {
        context.read<SocialProvider>().loadSocialFeed(refresh: true);
      },
    );
  }

  Widget _buildEmptyFeedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 60,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'No Activity Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Add friends to see their restaurant visits and activity',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: () => NavigationService.goToNamed('friends'),
              icon: const Icon(Icons.person_add),
              label: const Text('Find Friends'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTrendingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.trending_up,
                size: 60,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'No Trending Restaurants',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Check back later for trending restaurants in Austin',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleFeedItemTap(item) {
    if (item.restaurantId != null) {
      NavigationService.goToRestaurantDetails(restaurantId: item.restaurantId!);
    }
  }
}

