import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/restaurant.dart';

class RSVPBottomSheet extends StatelessWidget {
  final Restaurant restaurant;
  final String day;
  final int rsvpCount;
  final VoidCallback onAddToCalendar;
  final VoidCallback onSetReminder;

  const RSVPBottomSheet({
    super.key,
    required this.restaurant,
    required this.day,
    required this.rsvpCount,
    required this.onAddToCalendar,
    required this.onSetReminder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  'RSVP Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${restaurant.name} - $day',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // RSVP Count
          _buildRSVPCount(context),
          
          const SizedBox(height: 20),
          
          // Who's Going Section
          _buildWhosGoing(context),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          _buildActionButtons(context),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRSVPCount(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people,
            color: Colors.orange.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            '$rsvpCount people are going',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhosGoing(BuildContext context) {
    // Mock data - replace with actual friends/attendees
    final attendees = [
      {'name': 'Sarah Johnson', 'avatar': 'SJ', 'isFriend': true},
      {'name': 'Mike Chen', 'avatar': 'MC', 'isFriend': true},
      {'name': 'Alex Rodriguez', 'avatar': 'AR', 'isFriend': false},
      {'name': 'Emma Wilson', 'avatar': 'EW', 'isFriend': true},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who\'s Going',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          if (attendees.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Be the first to RSVP!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attendees.length,
              itemBuilder: (context, index) {
                final attendee = attendees[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.orange.shade100,
                        child: Text(
                          attendee['avatar'] as String,
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Name
                      Expanded(
                        child: Text(
                          attendee['name'] as String,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      // Friend indicator
                      if (attendee['isFriend'] as bool)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Friend',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Add to Calendar Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddToCalendar,
              icon: const Icon(Icons.calendar_today, size: 20),
              label: const Text('Add to Calendar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Set Reminder Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSetReminder,
              icon: const Icon(Icons.notifications, size: 20),
              label: const Text('Set Reminder'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Share Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _shareRSVP(context),
              icon: const Icon(Icons.share, size: 20),
              label: const Text('Share with Friends'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareRSVP(BuildContext context) {
    final message = 'Join me at ${restaurant.name} on $day! ${restaurant.address}';
    
    // Show share dialog or use share_plus package
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share RSVP'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('RSVP shared!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }
}

