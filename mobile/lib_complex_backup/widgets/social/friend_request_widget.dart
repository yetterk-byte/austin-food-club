import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/friend.dart';
import '../../widgets/common/custom_button.dart';

class FriendRequestWidget extends StatefulWidget {
  final FriendRequest request;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const FriendRequestWidget({
    super.key,
    required this.request,
    this.onAccept,
    this.onDecline,
  });

  @override
  State<FriendRequestWidget> createState() => _FriendRequestWidgetState();
}

class _FriendRequestWidgetState extends State<FriendRequestWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(300 * (1 - _slideAnimation.value), 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade600,
                        backgroundImage: widget.request.fromUserProfileImage != null
                            ? NetworkImage(widget.request.fromUserProfileImage!)
                            : null,
                        child: widget.request.fromUserProfileImage == null
                            ? Icon(
                                Icons.person,
                                color: Colors.grey.shade400,
                                size: 24,
                              )
                            : null,
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.request.fromUserName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            
                            const SizedBox(height: 4),
                            
                            if (widget.request.fromUserPhone != null)
                              Text(
                                widget.request.fromUserPhone!,
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                              ),
                            
                            const SizedBox(height: 4),
                            
                            Text(
                              'Sent ${_formatTime(widget.request.createdAt)}',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  if (!_isProcessing)
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Decline',
                            type: ButtonType.outline,
                            borderColor: Colors.grey.shade600,
                            textColor: Colors.grey.shade300,
                            onPressed: _handleDecline,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        Expanded(
                          child: CustomButton(
                            text: 'Accept',
                            onPressed: _handleAccept,
                          ),
                        ),
                      ],
                    )
                  else
                    const Center(
                      child: CircularProgressIndicator(
                        color: Colors.orange,
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

  void _handleAccept() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      HapticFeedback.mediumImpact();
      widget.onAccept?.call();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.request.fromUserName} is now your friend!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _handleDecline() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      HapticFeedback.lightImpact();
      
      // Animate out
      await _animationController.forward();
      
      widget.onDecline?.call();
      
      // Show message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Declined friend request from ${widget.request.fromUserName}'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

