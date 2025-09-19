import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/friend.dart';

class FriendCardWidget extends StatelessWidget {
  final Friend friend;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool showStats;

  const FriendCardWidget({
    super.key,
    required this.friend,
    this.onTap,
    this.onRemove,
    this.showStats = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade700,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade600,
              backgroundImage: friend.profileImageUrl != null
                  ? NetworkImage(friend.profileImageUrl!)
                  : null,
              child: friend.profileImageUrl == null
                  ? Icon(
                      Icons.person,
                      color: Colors.grey.shade400,
                      size: 28,
                    )
                  : null,
            ),
            
            const SizedBox(width: 16),
            
            // Friend info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  if (showStats) ...[
                    Row(
                      children: [
                        _buildStatItem(
                          icon: Icons.restaurant,
                          value: friend.totalVisits.toString(),
                          label: 'visits',
                        ),
                        const SizedBox(width: 16),
                        _buildStatItem(
                          icon: Icons.star,
                          value: friend.averageRating.toStringAsFixed(1),
                          label: 'avg',
                        ),
                        if (friend.currentStreak > 0) ...[
                          const SizedBox(width: 16),
                          _buildStatItem(
                            icon: Icons.local_fire_department,
                            value: friend.currentStreak.toString(),
                            label: 'streak',
                            color: Colors.orange,
                          ),
                        ],
                      ],
                    ),
                  ] else ...[
                    if (friend.phoneNumber != null)
                      Text(
                        friend.phoneNumber!,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                  ],
                  
                  // Favorite cuisines
                  if (friend.favoriteCuisines.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: friend.favoriteCuisines.take(3).map((cuisine) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            cuisine,
                            style: TextStyle(
                              color: Colors.orange.shade300,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            
            // Actions
            if (onRemove != null)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey.shade400,
                ),
                color: Colors.grey.shade800,
                onSelected: (value) {
                  if (value == 'remove') {
                    onRemove?.call();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        const Icon(Icons.person_remove, color: Colors.red),
                        const SizedBox(width: 12),
                        const Text(
                          'Remove Friend',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    Color? color,
  }) {
    final statColor = color ?? Colors.grey.shade400;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: statColor,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: statColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

