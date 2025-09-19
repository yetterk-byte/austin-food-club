import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/verified_visit.dart';

class AchievementsSection extends StatelessWidget {
  final User user;
  final List<VerifiedVisit> visits;

  const AchievementsSection({
    super.key,
    required this.user,
    required this.visits,
  });

  @override
  Widget build(BuildContext context) {
    final achievements = _calculateAchievements(visits);
    
    if (achievements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.amber.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Achievements',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${achievements.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Achievements grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return _buildAchievementCard(context, achievement);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(BuildContext context, Achievement achievement) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: achievement.isUnlocked 
              ? achievement.color.withOpacity(0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Achievement icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: achievement.isUnlocked 
                  ? achievement.color.withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              achievement.icon,
              color: achievement.isUnlocked 
                  ? achievement.color
                  : Colors.grey.shade400,
              size: 32,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Achievement title
          Text(
            achievement.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: achievement.isUnlocked 
                  ? Colors.black
                  : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // Achievement description
          Text(
            achievement.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: achievement.isUnlocked 
                  ? Colors.grey.shade600
                  : Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          if (achievement.isUnlocked) ...[
            const SizedBox(height: 8),
            
            // Progress or completion
            if (achievement.progress != null)
              LinearProgressIndicator(
                value: achievement.progress!,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(achievement.color),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: achievement.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Unlocked!',
                  style: TextStyle(
                    color: achievement.color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  List<Achievement> _calculateAchievements(List<VerifiedVisit> visits) {
    final achievements = <Achievement>[];
    
    // First Visit Achievement
    achievements.add(Achievement(
      id: 'first_visit',
      title: 'First Bite',
      description: 'Complete your first verified visit',
      icon: Icons.restaurant,
      color: Colors.green,
      isUnlocked: visits.isNotEmpty,
    ));
    
    // Visit Count Achievements
    final visitCount = visits.length;
    achievements.add(Achievement(
      id: 'visits_5',
      title: 'Food Explorer',
      description: 'Complete 5 verified visits',
      icon: Icons.explore,
      color: Colors.blue,
      isUnlocked: visitCount >= 5,
      progress: visitCount >= 5 ? 1.0 : visitCount / 5.0,
    ));
    
    achievements.add(Achievement(
      id: 'visits_10',
      title: 'Restaurant Regular',
      description: 'Complete 10 verified visits',
      icon: Icons.local_dining,
      color: Colors.purple,
      isUnlocked: visitCount >= 10,
      progress: visitCount >= 10 ? 1.0 : visitCount / 10.0,
    ));
    
    achievements.add(Achievement(
      id: 'visits_25',
      title: 'Foodie Master',
      description: 'Complete 25 verified visits',
      icon: Icons.star,
      color: Colors.amber,
      isUnlocked: visitCount >= 25,
      progress: visitCount >= 25 ? 1.0 : visitCount / 25.0,
    ));
    
    // Rating Achievements
    if (visits.isNotEmpty) {
      final averageRating = visits.fold(0, (sum, visit) => sum + visit.rating) / visits.length;
      
      achievements.add(Achievement(
        id: 'high_rating',
        title: 'Quality Critic',
        description: 'Maintain 4.5+ average rating',
        icon: Icons.star_rate,
        color: Colors.orange,
        isUnlocked: averageRating >= 4.5,
      ));
    }
    
    // Monthly Achievements
    final thisMonth = DateTime.now();
    final thisMonthVisits = visits.where((visit) {
      return visit.visitDate.year == thisMonth.year && 
             visit.visitDate.month == thisMonth.month;
    }).length;
    
    achievements.add(Achievement(
      id: 'monthly_5',
      title: 'Monthly Explorer',
      description: 'Complete 5 visits this month',
      icon: Icons.calendar_month,
      color: Colors.teal,
      isUnlocked: thisMonthVisits >= 5,
      progress: thisMonthVisits >= 5 ? 1.0 : thisMonthVisits / 5.0,
    ));
    
    // Streak Achievements
    final currentStreak = _calculateCurrentStreak(visits);
    achievements.add(Achievement(
      id: 'streak_7',
      title: 'Consistent Diner',
      description: '7-day visit streak',
      icon: Icons.local_fire_department,
      color: Colors.red,
      isUnlocked: currentStreak >= 7,
      progress: currentStreak >= 7 ? 1.0 : currentStreak / 7.0,
    ));
    
    // Variety Achievements
    final uniqueRestaurants = visits.map((visit) => visit.restaurantId).toSet().length;
    achievements.add(Achievement(
      id: 'variety_10',
      title: 'Diverse Palate',
      description: 'Visit 10 different restaurants',
      icon: Icons.restaurant_menu,
      color: Colors.indigo,
      isUnlocked: uniqueRestaurants >= 10,
      progress: uniqueRestaurants >= 10 ? 1.0 : uniqueRestaurants / 10.0,
    ));
    
    return achievements;
  }

  int _calculateCurrentStreak(List<VerifiedVisit> visits) {
    if (visits.isEmpty) return 0;
    
    // Sort visits by date (newest first)
    final sortedVisits = List<VerifiedVisit>.from(visits);
    sortedVisits.sort((a, b) => b.visitDate.compareTo(a.visitDate));
    
    int streak = 0;
    DateTime currentDate = DateTime.now();
    
    for (final visit in sortedVisits) {
      final visitDate = DateTime(visit.visitDate.year, visit.visitDate.month, visit.visitDate.day);
      final expectedDate = DateTime(currentDate.year, currentDate.month, currentDate.day);
      
      if (visitDate.isAtSameMomentAs(expectedDate)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else if (visitDate.isBefore(expectedDate)) {
        break;
      }
    }
    
    return streak;
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final double? progress;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    this.progress,
  });
}

