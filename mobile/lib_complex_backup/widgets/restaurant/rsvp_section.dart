import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/restaurant.dart';
import '../../providers/rsvp_provider.dart';

class RSVPSection extends StatefulWidget {
  final Restaurant restaurant;
  final Function(String day, String status) onRSVP;
  final Function(String day) onShowDetails;

  const RSVPSection({
    super.key,
    required this.restaurant,
    required this.onRSVP,
    required this.onShowDetails,
  });

  @override
  State<RSVPSection> createState() => _RSVPSectionState();
}

class _RSVPSectionState extends State<RSVPSection>
    with TickerProviderStateMixin {
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonAnimation;
  
  String? _selectedDay;
  String _selectedStatus = 'going';

  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _buttonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),
          
          const SizedBox(height: 20),
          
          // Day Selector
          _buildDaySelector(context),
          
          const SizedBox(height: 20),
          
          // Status Selector
          _buildStatusSelector(context),
          
          const SizedBox(height: 20),
          
          // RSVP Button
          _buildRSVPButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.event,
            color: Colors.orange,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'See You There',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Join others for a great meal',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDaySelector(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select a day',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Consumer<RSVPProvider>(
          builder: (context, rsvpProvider, child) {
            return Row(
              children: days.asMap().entries.map((entry) {
                final index = entry.key;
                final day = entry.value;
                final isSelected = _selectedDay == day;
                final rsvpCount = rsvpProvider.getRSVPCount(day);
                final hasUserRSVP = rsvpProvider.hasRSVPForDay(
                  widget.restaurant.id,
                  day,
                );

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = day;
                      });
                    },
                    onLongPress: () {
                      widget.onShowDetails(day);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(
                        right: index < days.length - 1 ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.orange
                            : hasUserRSVP
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.orange
                              : hasUserRSVP
                                  ? Colors.green
                                  : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            day,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : hasUserRSVP
                                      ? Colors.green.shade700
                                      : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$rsvpCount',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white
                                  : hasUserRSVP
                                      ? Colors.green.shade700
                                      : Colors.grey.shade600,
                            ),
                          ),
                          if (hasUserRSVP)
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green.shade700,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusSelector(BuildContext context) {
    final statuses = [
      {'value': 'going', 'label': 'Going', 'icon': Icons.check_circle, 'color': Colors.green},
      {'value': 'maybe', 'label': 'Maybe', 'icon': Icons.help_outline, 'color': Colors.orange},
      {'value': 'not_going', 'label': 'Not Going', 'icon': Icons.cancel, 'color': Colors.red},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your status',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: statuses.map((status) {
            final isSelected = _selectedStatus == status['value'];
            final color = status['color'] as Color;
            
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedStatus = status['value'] as String;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        status['icon'] as IconData,
                        color: isSelected ? color : Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? color : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRSVPButton(BuildContext context) {
    final isEnabled = _selectedDay != null;
    
    return AnimatedBuilder(
      animation: _buttonAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonAnimation.value,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isEnabled ? _handleRSVP : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_available, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isEnabled
                        ? 'RSVP for $_selectedDay'
                        : 'Select a day to RSVP',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleRSVP() {
    if (_selectedDay != null) {
      _buttonAnimationController.forward().then((_) {
        _buttonAnimationController.reverse();
      });
      
      widget.onRSVP(_selectedDay!, _selectedStatus);
    }
  }
}

