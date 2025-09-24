import 'package:chat_app/chat_room_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/screens/profile_screen.dart';
import 'package:chat_app/config/theme.dart';
import 'package:badges/badges.dart' as badges;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late AnimationController _listController;
  late AnimationController _searchController;
  final TextEditingController _searchController2 = TextEditingController();
  String _searchQuery = '';
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      duration: AppTheme.slowAnimation,
      vsync: this,
    );
    _searchController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );
    _listController.forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    _searchController.dispose();
    _searchController2.dispose();
    super.dispose();
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }

  String _displayNameFor(Map<String, dynamic> userData) {
    final username = (userData['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty) {
      return username;
    }
    
    final email = (userData['email'] as String?)?.trim();
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    
    return 'User';
  }

  String _presenceText(Map<String, dynamic> userData) {
    final bool online = userData['online'] == true;
    if (online) return 'Online';
    final Timestamp? lastSeenTs = userData['lastSeen'] as Timestamp?;
    if (lastSeenTs == null) return 'Offline';
    final dt = lastSeenTs.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Active now';
    if (diff.inMinutes < 60) return 'Active ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Active ${diff.inHours}h ago';
    return 'Last seen ${dt.day}/${dt.month}/${dt.year}';
  }

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _searchQuery = '';
        _searchController2.clear();
        _searchController.reverse();
      } else {
        _searchController.forward();
      }
    });
  }

  Future<void> _signOut() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'online': false,
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      FirebaseAuth.instance.signOut();
      return const Scaffold(
        body: Center(child: Text('Please login again')),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern app bar with search
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (!_isSearchActive) ...[
                          Text(
                            'Messages',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 28,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          _buildActionButton(
                            icon: Icons.search_rounded,
                            onTap: _toggleSearch,
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.person_rounded,
                             onTap: () {
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(
                                   builder: (context) => const ProfileScreen(),
                                 ),
                               );
                             },
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.logout_rounded,
                            onTap: _signOut,
                          ),
                        ] else ...[
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _searchController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _searchController.value,
                                  child: Opacity(
                                    opacity: _searchController.value,
                                    child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppTheme.backgroundLight,
                                        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                                        border: Border.all(
                                          color: AppTheme.primaryColor.withOpacity(0.2),
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _searchController2,
                                        autofocus: true,
                                        onChanged: (value) {
                                          setState(() => _searchQuery = value.toLowerCase());
                                        },
                                        decoration: const InputDecoration(
                                          hintText: 'Search conversations...',
                                          prefixIcon: Icon(Icons.search_rounded),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16, 
                                            vertical: 12
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildActionButton(
                            icon: Icons.close_rounded,
                            onTap: _toggleSearch,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Chat list with enhanced animations
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: AppTheme.errorColor,
                            ),
                            const SizedBox(height: 16),
                            Text('Something went wrong'),
                          ],
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      );
                    }

                    final allUsers = snapshot.data?.docs ?? [];
                    final otherUsers = allUsers.where((doc) => doc.id != currentUser.uid).toList();

                    if (otherUsers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 64,
                              color: AppTheme.mutedTextColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.mutedTextColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start a conversation when other users join!',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                    .collection('chat_rooms')
                    .where('participants', arrayContains: currentUser.uid)
                    .snapshots(),
                    builder: (context, roomsSnap) {
                    final rooms = roomsSnap.data?.docs ?? [];
                    final Map<String, Map<String, dynamic>> roomMap = {};
                    
                    for (final room in rooms) {
                    final roomData = room.data() as Map<String, dynamic>;
                    final participants = (roomData['participants'] as List).cast<String>();
                    final partnerId = participants.firstWhere((id) => id != currentUser.uid, orElse: () => '');
                    if (partnerId.isNotEmpty) {
                    roomMap[partnerId] = roomData;
                    }
                    }
                    
                    // Filter and sort users
                    var filteredUsers = otherUsers.where((user) {
                    if (_searchQuery.isEmpty) return true;
                    final userData = user.data() as Map<String, dynamic>;
                    final displayName = _displayNameFor(userData).toLowerCase();
                    return displayName.contains(_searchQuery);
                    }).toList();
                    
                    // Chats with unread for me first, then by lastActivity
                    filteredUsers.sort((a, b) {
                    final aId = a.id;
                    final bId = b.id;
                    final aRoom = roomMap[aId];
                    final bRoom = roomMap[bId];
                    
                    int unreadA = 0;
                    int unreadB = 0;
                    Timestamp? aTs;
                    Timestamp? bTs;
                    
                    if (aRoom != null) {
                    unreadA = (aRoom['unread_${currentUser.uid}'] ?? 0) as int;
                    aTs = aRoom['lastActivity'] as Timestamp?;
                    }
                    if (bRoom != null) {
                    unreadB = (bRoom['unread_${currentUser.uid}'] ?? 0) as int;
                    bTs = bRoom['lastActivity'] as Timestamp?;
                    }
                    
                    if (unreadA > 0 && unreadB == 0) return -1;
                    if (unreadA == 0 && unreadB > 0) return 1;
                    
                    if (aTs == null && bTs == null) return 0;
                    if (aTs == null) return 1;
                    if (bTs == null) return -1;
                    return bTs.compareTo(aTs);
                    });
                    
                    return AnimatedBuilder(
                    animation: _listController,
                    builder: (context, child) {
                    return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                    // Staggered animation
                    final animationDelay = index * 0.1;
                    final animation = Tween<double>(
                    begin: 0,
                    end: 1,
                    ).animate(CurvedAnimation(
                    parent: _listController,
                    curve: Interval(
                    animationDelay,
                    (animationDelay + 0.3).clamp(0.0, 1.0),
                    curve: Curves.easeOutCubic,
                    ),
                    ));
                    
                    final userDoc = filteredUsers[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final userId = userDoc.id;
                    final roomData = roomMap[userId];
                    final displayName = _displayNameFor(userData);
                    final lastMessageText = roomData?['lastMessageText'] as String?;
                    final lastMessageTs = roomData?['lastMessageTimestamp'] as Timestamp?;
                    final unreadCount = (roomData?['unread_${currentUser.uid}'] ?? 0) as int;
                    
                    return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                    return Transform.translate(
                    offset: Offset(50 * (1 - animation.value), 0),
                    child: Opacity(
                    opacity: animation.value,
                    child: Container(
                    margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                    ),
                    decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                    boxShadow: AppTheme.softShadow,
                    ),
                    child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                    onTap: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                    builder: (context) => ChatRoomScreen(
                    currentUser: currentUser,
                    chatPartnerId: userId,
                    chatPartnerName: displayName,
                    ),
                    ),
                    );
                    },
                    child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                    children: [
                    badges.Badge(
                    position: badges.BadgePosition.topEnd(top: -4, end: -2),
                    showBadge: unreadCount > 0,
                    badgeStyle: const badges.BadgeStyle(
                    badgeColor: Colors.red,
                    ),
                    badgeContent: Text(
                    unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    child: _ModernAvatarWithPresence(
                    name: displayName,
                    online: userData['online'] == true,
                    ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: unreadCount > 0 ? FontWeight.w800 : FontWeight.w600,
                    ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                    (lastMessageText?.isNotEmpty == true)
                    ? lastMessageText!
                    : _presenceText(userData),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: (lastMessageText?.isNotEmpty == true)
                    ? (unreadCount > 0 ? AppTheme.textPrimary : AppTheme.textSecondary)
                    : AppTheme.mutedTextColor,
                    fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w400,
                    ),
                    ),
                    ],
                    ),
                    ),
                    Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                    if (lastMessageTs != null)
                    Container(
                    padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                    ),
                    decoration: BoxDecoration(
                    color: unreadCount > 0 ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                    _formatTime(lastMessageTs),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: unreadCount > 0 ? Colors.white : AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    ),
                    ),
                    ),
                    ],
                    ),
                    ],
                    ),
                    ),
                    ),
                    ),
                    ),
                    ),
                    );
                    },
                    );
                    },
                    );
                    },
                    );
                    },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _ModernAvatarWithPresence extends StatelessWidget {
  final String name;
  final bool online;

  const _ModernAvatarWithPresence({required this.name, required this.online});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.primaryGradient,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: online ? AppTheme.successColor : AppTheme.mutedTextColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
      ],
    );
  }
}