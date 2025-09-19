import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/verified_visit.dart';

class VerifiedVisits extends StatefulWidget {
  final List<VerifiedVisit> visits;
  final bool isGridView;
  final String sortBy;
  final VoidCallback onToggleView;
  final Function(String) onSortChanged;
  final Function(VerifiedVisit) onVisitTapped;
  final VoidCallback onLoadMore;

  const VerifiedVisits({
    super.key,
    required this.visits,
    required this.isGridView,
    required this.sortBy,
    required this.onToggleView,
    required this.onSortChanged,
    required this.onVisitTapped,
    required this.onLoadMore,
  });

  @override
  State<VerifiedVisits> createState() => _VerifiedVisitsState();
}

class _VerifiedVisitsState extends State<VerifiedVisits> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore) {
        setState(() {
          _isLoadingMore = true;
        });
        widget.onLoadMore();
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _isLoadingMore = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedVisits = _sortVisits(widget.visits);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with controls
          _buildHeader(context),
          
          const SizedBox(height: 16),
          
          // Visits content
          if (sortedVisits.isEmpty)
            _buildEmptyState(context)
          else if (widget.isGridView)
            _buildGridView(context, sortedVisits)
          else
            _buildListView(context, sortedVisits),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.verified,
          color: Colors.green.shade600,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Verified Visits',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        
        // Sort dropdown
        PopupMenuButton<String>(
          onSelected: widget.onSortChanged,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'date',
              child: Text('Sort by Date'),
            ),
            const PopupMenuItem(
              value: 'rating',
              child: Text('Sort by Rating'),
            ),
            const PopupMenuItem(
              value: 'restaurant',
              child: Text('Sort by Restaurant'),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getSortText(widget.sortBy),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 16),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // View toggle
        IconButton(
          onPressed: widget.onToggleView,
          icon: Icon(
            widget.isGridView ? Icons.view_list : Icons.grid_view,
            color: Colors.orange.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
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
            Icons.photo_camera_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No Verified Visits',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Verify your restaurant visits to see them here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(BuildContext context, List<VerifiedVisit> visits) {
    return GridView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: visits.length + (_isLoadingMore ? 2 : 0),
      itemBuilder: (context, index) {
        if (index >= visits.length) {
          return _buildLoadingCard();
        }
        
        final visit = visits[index];
        return _buildGridItem(context, visit);
      },
    );
  }

  Widget _buildListView(BuildContext context, List<VerifiedVisit> visits) {
    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visits.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= visits.length) {
          return _buildLoadingItem();
        }
        
        final visit = visits[index];
        return _buildListItem(context, visit);
      },
    );
  }

  Widget _buildGridItem(BuildContext context, VerifiedVisit visit) {
    return GestureDetector(
      onTap: () => widget.onVisitTapped(visit),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: visit.photoUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant name
                    Text(
                      visit.restaurant?.name ?? 'Unknown Restaurant',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Rating
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < visit.rating ? Icons.star : Icons.star_border,
                            color: Colors.orange,
                            size: 12,
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          '${visit.rating}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Date
                    Text(
                      _formatDate(visit.visitDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, VerifiedVisit visit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onVisitTapped(visit),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: visit.photoUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade300,
                      child: const Icon(
                        Icons.restaurant,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Restaurant name
                      Text(
                        visit.restaurant?.name ?? 'Unknown Restaurant',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Rating
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < visit.rating ? Icons.star : Icons.star_border,
                              color: Colors.orange,
                              size: 16,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            '${visit.rating}/5',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Date
                      Text(
                        _formatDate(visit.visitDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildLoadingItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  List<VerifiedVisit> _sortVisits(List<VerifiedVisit> visits) {
    final sortedVisits = List<VerifiedVisit>.from(visits);
    
    switch (widget.sortBy) {
      case 'date':
        sortedVisits.sort((a, b) => b.visitDate.compareTo(a.visitDate));
        break;
      case 'rating':
        sortedVisits.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'restaurant':
        sortedVisits.sort((a, b) => 
          (a.restaurant?.name ?? '').compareTo(b.restaurant?.name ?? ''));
        break;
    }
    
    return sortedVisits;
  }

  String _getSortText(String sortBy) {
    switch (sortBy) {
      case 'date':
        return 'Date';
      case 'rating':
        return 'Rating';
      case 'restaurant':
        return 'Name';
      default:
        return 'Date';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}

