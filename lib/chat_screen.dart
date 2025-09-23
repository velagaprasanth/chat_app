import 'package:chat_app/chat_room_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/screens/profile_screen.dart';

import 'package:chat_app/config/theme.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final date = timestamp.toDate();
    if (now.difference(date).inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }

  String _displayNameFor(Map<String, dynamic> userData) {
    // ALWAYS prioritize username if it exists and is not empty
    final username = (userData['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty) {
      return username;
    }
    
    // Fallback to email local-part only if no username
    final email = (userData['email'] as String?)?.trim();
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    
    // Final fallback
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
    if (diff.inMinutes < 1) return 'Last seen just now';
    if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
    return 'Last seen on ${dt.day}/${dt.month}/${dt.year}';
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
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
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
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

                final allUsers = snapshot.data?.docs ?? [];
                final otherUsers = allUsers.where((doc) => doc.id != currentUser.uid).toList();

                if (otherUsers.isEmpty) {
            return const Center(child: Text('No other users found'));
          }

                // Debug: Print user data to console
                for (final user in otherUsers) {
                  final data = user.data() as Map<String, dynamic>;
                  print('User ${user.id}: username="${data['username']}", email="${data['email']}"');
                }

                // Build a map of chat rooms for this user to get last messages
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

                    // Sort users by last activity (users with conversations first, then by last activity)
                    otherUsers.sort((a, b) {
                      final aId = a.id;
                      final bId = b.id;
                      final aRoom = roomMap[aId];
                      final bRoom = roomMap[bId];
                      
                      // Users with conversations come first
                      if (aRoom != null && bRoom == null) return -1;
                      if (aRoom == null && bRoom != null) return 1;
                      if (aRoom == null && bRoom == null) return 0;
                      
                      // Both have conversations, sort by last activity
                      final aTs = aRoom!['lastActivity'] as Timestamp?;
                      final bTs = bRoom!['lastActivity'] as Timestamp?;
                      if (aTs == null && bTs == null) return 0;
                      if (aTs == null) return 1;
                      if (bTs == null) return -1;
                      return bTs.compareTo(aTs);
                    });

                    return ListView.separated(
                      itemCount: otherUsers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final userDoc = otherUsers[index];
                        final userData = userDoc.data() as Map<String, dynamic>;
                        final userId = userDoc.id;
                        final roomData = roomMap[userId];
                        
                        final displayName = _displayNameFor(userData);
                        final lastMessageText = roomData?['lastMessageText'] as String?;
                        final lastMessageTs = roomData?['lastMessageTimestamp'] as Timestamp?;

                  return ListTile(
                          leading: _AvatarWithPresence(
                            name: displayName,
                            online: userData['online'] == true,
                          ),
                          title: Text(
                            displayName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            (lastMessageText?.isNotEmpty == true)
                                ? lastMessageText!
                                : _presenceText(userData),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: (lastMessageTs != null)
                              ? Text(
                                  _formatTime(lastMessageTs),
                                  style: Theme.of(context).textTheme.bodySmall,
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatRoomScreen (
                            currentUser: currentUser,
                            chatPartnerId: userId,
                                  chatPartnerName: displayName,
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
      ),
          ),
        ],
      ),
    );
  }
}

class _AvatarWithPresence extends StatelessWidget {
  final String name;
  final bool online;

  const _AvatarWithPresence({required this.name, required this.online});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: online ? const Color(0xFF2ECC71) : AppTheme.mutedTextColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}