import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../services/mock_data_service.dart';
import '../services/api_service.dart';

class RSVPSection extends StatefulWidget {
  final Restaurant restaurant;

  const RSVPSection({
    super.key,
    required this.restaurant,
  });

  @override
  State<RSVPSection> createState() => _RSVPSectionState();
}

class _RSVPSectionState extends State<RSVPSection> {
  String? selectedDay;
  Map<String, int> rsvpCounts = {};
  String? loadingDay; // Track which day is currently loading
  final List<String> daysOfWeek = MockDataService.getDaysOfWeek();

  @override
  void initState() {
    super.initState();
    _loadRSVPCounts();
  }

  Future<void> _loadRSVPCounts() async {
    try {
      final counts = await MockDataService.getRSVPCounts(widget.restaurant.id);
      setState(() {
        rsvpCounts = counts;
      });
    } catch (e) {
      print('Error loading RSVP counts: $e');
    }
  }

  Future<void> _handleRSVP(String day) async {
    final wasSelected = selectedDay == day;
    
    // Set loading state
    setState(() {
      loadingDay = day;
    });
    
    // Optimistic update
    setState(() {
      if (selectedDay == day) {
        // Cancel RSVP
        selectedDay = null;
        rsvpCounts[day] = (rsvpCounts[day] ?? 0) - 1;
      } else {
        // Change or create RSVP
        if (selectedDay != null) {
          rsvpCounts[selectedDay!] = (rsvpCounts[selectedDay!] ?? 0) - 1;
        }
        selectedDay = day;
        rsvpCounts[day] = (rsvpCounts[day] ?? 0) + 1;
      }
    });

    try {
      // Call API to create RSVP
      if (!wasSelected) {
        final success = await ApiService.createRSVP(widget.restaurant.id, day);
        if (!success) {
          // Revert optimistic update on failure
          setState(() {
            if (selectedDay == day) {
              selectedDay = null;
              rsvpCounts[day] = (rsvpCounts[day] ?? 0) - 1;
            }
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to RSVP for $day. Please try again.'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _handleRSVP(day),
              ),
            ),
          );
          return;
        }
      }

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            selectedDay == day
                ? 'RSVP confirmed for $day!'
                : 'RSVP cancelled for $day',
          ),
          backgroundColor: selectedDay == day ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error handling RSVP: $e');
      // Revert optimistic update on error
      setState(() {
        if (wasSelected) {
          selectedDay = day;
          rsvpCounts[day] = (rsvpCounts[day] ?? 0) + 1;
        } else {
          selectedDay = null;
          rsvpCounts[day] = (rsvpCounts[day] ?? 0) - 1;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error. Please check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Clear loading state
      setState(() {
        loadingDay = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'See You There?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w400, // Lighter font weight
              color: Colors.orange,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a day to RSVP:',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Day buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: daysOfWeek.map((day) {
              final isSelected = selectedDay == day;
              final count = rsvpCounts[day] ?? 0;
              final isLoading = loadingDay == day;
              
              return GestureDetector(
                onTap: isLoading ? null : () => _handleRSVP(day),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange : Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.orange : Colors.grey[600]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        day.substring(0, 3), // Show first 3 letters
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: isLoading 
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                count.toString(),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          // Removed status message boxes for cleaner design
        ],
      ),
    );
  }
}
