import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/rsvp.dart';

class UpcomingRSVPs extends StatelessWidget {
  final List<RSVP> rsvps;
  final Function(RSVP) onVerifyVisit;
  final Function(String) onCancelRSVP;

  const UpcomingRSVPs({
    super.key,
    required this.rsvps,
    required this.onVerifyVisit,
    required this.onCancelRSVP,
  });

  @override
  Widget build(BuildContext context) {
    // Filter upcoming RSVPs (status = 'going' and future dates)
    final upcomingRSVPs = rsvps.where((rsvp) {
      return rsvp.status == 'going' && _isUpcoming(rsvp);
    }).toList();

    if (upcomingRSVPs.isEmpty) {
      return _buildEmptyState(context);
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
                Icons.event,
                color: Colors.orange.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Upcoming RSVPs',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${upcomingRSVPs.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // RSVP List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: upcomingRSVPs.length,
            itemBuilder: (context, index) {
              final rsvp = upcomingRSVPs[index];
              return _buildRSVPItem(context, rsvp);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No Upcoming RSVPs',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'RSVP to restaurants to see them here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRSVPItem(BuildContext context, RSVP rsvp) {
    final isPast = _isPast(rsvp);
    final canVerify = isPast && rsvp.status == 'going';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          color: canVerify ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant name and status
          Row(
            children: [
              Expanded(
                child: Text(
                  rsvp.restaurant?.name ?? 'Unknown Restaurant',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(rsvp.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(rsvp.status).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _getStatusText(rsvp.status),
                  style: TextStyle(
                    color: _getStatusColor(rsvp.status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Day and time
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                _formatRSVPDate(rsvp),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                _getTimeText(rsvp),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          
          if (rsvp.restaurant?.address != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rsvp.restaurant!.address,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: [
              if (canVerify) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onVerifyVisit(rsvp),
                    icon: const Icon(Icons.verified, size: 16),
                    label: const Text('Verify Visit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              // Cancel button
              OutlinedButton.icon(
                onPressed: () => onCancelRSVP(rsvp.id),
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isUpcoming(RSVP rsvp) {
    // Check if RSVP is for a future date
    // This is a simplified check - you might want to implement more sophisticated date logic
    return rsvp.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 1)));
  }

  bool _isPast(RSVP rsvp) {
    // Check if RSVP date has passed
    // This is a simplified check - you might want to implement more sophisticated date logic
    return rsvp.createdAt.isBefore(DateTime.now());
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'going':
        return Colors.green;
      case 'maybe':
        return Colors.orange;
      case 'not_going':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'going':
        return 'Going';
      case 'maybe':
        return 'Maybe';
      case 'not_going':
        return 'Not Going';
      default:
        return 'Unknown';
    }
  }

  String _formatRSVPDate(RSVP rsvp) {
    // Format the RSVP date
    return DateFormat('EEEE, MMM d').format(rsvp.createdAt);
  }

  String _getTimeText(RSVP rsvp) {
    // Get time text based on RSVP
    // This is mock data - replace with actual time logic
    return '7:00 PM';
  }
}

