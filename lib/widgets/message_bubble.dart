import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/config/theme.dart';

class MessageBubble extends StatefulWidget {
  final String message;
  final bool isMe;
  final Timestamp? timestamp;
  final bool seen;
  final VoidCallback? onDelete;

  const MessageBubble({
    required this.message,
    required this.isMe,
    required this.timestamp,
    required this.seen,
    this.onDelete,
    super.key,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  bool _showTimestamp = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: AppTheme.fastAnimation,
      vsync: this,
    );
    _slideController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.1, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _toggleTimestamp() {
    setState(() {
      _showTimestamp = !_showTimestamp;
    });
  }

  void _handleLongPress() {
    if (widget.isMe && widget.onDelete != null) {
      _slideController.forward().then((_) {
        _slideController.reverse();
      });
      _showDeleteOptions();
    } else {
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });
    }
  }

  void _showDeleteOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.mediumRadius),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.errorColor,
                ),
              ),
              title: const Text('Delete Message'),
              subtitle: const Text('This action cannot be undone'),
              onTap: () {
                Navigator.pop(context);
                widget.onDelete?.call();
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: AppTheme.textSecondary,
                ),
              ),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _slideAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: widget.isMe ? _slideAnimation.value : Offset.zero,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _toggleTimestamp,
                  onLongPress: _handleLongPress,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: widget.isMe 
                          ? MainAxisAlignment.end 
                          : MainAxisAlignment.start,
                      children: [
                        if (!widget.isMe) ...[
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: AppTheme.accentGradient,
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: widget.isMe
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: AppTheme.primaryGradient,
                                    )
                                  : null,
                              color: widget.isMe ? null : Colors.white,
                              borderRadius: BorderRadius.circular(20).copyWith(
                                bottomRight: widget.isMe 
                                    ? const Radius.circular(6) 
                                    : const Radius.circular(20),
                                bottomLeft: !widget.isMe 
                                    ? const Radius.circular(6) 
                                    : const Radius.circular(20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.isMe
                                      ? AppTheme.primaryColor.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.message,
                                  style: TextStyle(
                                    color: widget.isMe 
                                        ? Colors.white 
                                        : AppTheme.textPrimary,
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                ),
                                if (widget.isMe) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Icon(
                                        widget.seen 
                                            ? Icons.done_all_rounded 
                                            : Icons.done_rounded,
                                        color: widget.seen 
                                            ? Colors.white 
                                            : Colors.white70,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (widget.isMe) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: AppTheme.primaryGradient,
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Timestamp with smooth animation
                AnimatedContainer(
                  duration: AppTheme.mediumAnimation,
                  curve: Curves.easeInOut,
                  height: _showTimestamp ? 20 : 0,
                  child: AnimatedOpacity(
                    duration: AppTheme.mediumAnimation,
                    opacity: _showTimestamp ? 1.0 : 0.0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: widget.isMe 
                            ? MainAxisAlignment.end 
                            : MainAxisAlignment.start,
                        children: [
                          if (!widget.isMe) const SizedBox(width: 40),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.mutedTextColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatTime(widget.timestamp),
                              style: TextStyle(
                                color: AppTheme.mutedTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (widget.isMe) const SizedBox(width: 40),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}