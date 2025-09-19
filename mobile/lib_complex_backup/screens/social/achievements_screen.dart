import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/social_provider.dart';
import '../../widgets/social/achievement_card_widget.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/error_view.dart';
import '../../services/navigation_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().loadAchievements();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => NavigationService.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Achievements',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade400,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unlocked'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress header
          _buildProgressHeader(),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllAchievementsTab(),
                _buildUnlockedAchievementsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        if (socialProvider.isAchievementsLoading) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: ShimmerContainer(
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        }

        final progress = socialProvider.achievementProgress;
        final unlockedCount = socialProvider.unlockedAchievements.length;
        final totalCount = socialProvider.achievements.length;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.withOpacity(0.2),
                Colors.deepOrange.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.orange.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Colors.orange,
                      size: 30,
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Achievement Progress',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$unlockedCount of $totalCount unlocked',
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Progress bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAllAchievementsTab() {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        if (socialProvider.isAchievementsLoading && socialProvider.achievements.isEmpty) {
          return _buildLoadingState();
        }

        if (socialProvider.error != null && socialProvider.achievements.isEmpty) {
          return _buildErrorState(socialProvider.error!);
        }

        if (socialProvider.achievements.isEmpty) {
          return _buildEmptyState();
        }

        // Group achievements by type
        final achievementsByType = <AchievementType, List<Achievement>>{};
        for (final achievement in socialProvider.achievements) {
          achievementsByType.putIfAbsent(achievement.type, () => []).add(achievement);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: achievementsByType.length,
          itemBuilder: (context, index) {
            final type = achievementsByType.keys.elementAt(index);
            final achievements = achievementsByType[type]!;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _getAchievementTypeName(type),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Achievement cards
                ...achievements.map((achievement) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AchievementCardWidget(
                    achievement: achievement,
                    onTap: () => _showAchievementDetails(achievement),
                  ),
                )),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUnlockedAchievementsTab() {
    return Consumer<SocialProvider>(
      builder: (context, socialProvider, child) {
        if (socialProvider.isAchievementsLoading && socialProvider.unlockedAchievements.isEmpty) {
          return _buildLoadingState();
        }

        if (socialProvider.unlockedAchievements.isEmpty) {
          return _buildEmptyUnlockedState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: socialProvider.unlockedAchievements.length,
          itemBuilder: (context, index) {
            final achievement = socialProvider.unlockedAchievements[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AchievementCardWidget(
                achievement: achievement,
                onTap: () => _showAchievementDetails(achievement),
                showUnlockedDate: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerContainer(
              child: Container(
                height: 100,
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
        context.read<SocialProvider>().loadAchievements();
      },
    );
  }

  Widget _buildEmptyState() {
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
                Icons.emoji_events_outlined,
                size: 60,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'No Achievements Available',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Start visiting restaurants to unlock achievements',
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

  Widget _buildEmptyUnlockedState() {
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
                Icons.lock_outline,
                size: 60,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'No Achievements Unlocked',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Complete activities to unlock your first achievement',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: () => NavigationService.goToCurrent(),
              icon: const Icon(Icons.restaurant),
              label: const Text('Visit Restaurants'),
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

  void _showAchievementDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Achievement icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: achievement.isUnlocked 
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.grey.shade700,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  achievement.iconUrl,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Achievement name
            Text(
              achievement.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Achievement description
            Text(
              achievement.description,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Progress
            if (!achievement.isUnlocked) ...[
              Text(
                'Progress: ${achievement.currentProgress}/${achievement.targetValue}',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: achievement.progressPercentage,
                backgroundColor: Colors.grey.shade600,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getAchievementTypeName(AchievementType type) {
    switch (type) {
      case AchievementType.visits:
        return 'Visits';
      case AchievementType.cuisines:
        return 'Cuisines';
      case AchievementType.streak:
        return 'Streaks';
      case AchievementType.rating:
        return 'Ratings';
      case AchievementType.social:
        return 'Social';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return 'on ${date.month}/${date.day}/${date.year}';
    }
  }
}

