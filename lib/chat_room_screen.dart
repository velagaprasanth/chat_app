import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/config/theme.dart';
import 'package:chat_app/widgets/message_bubble.dart';

class ChatRoomScreen extends StatefulWidget {
  final User currentUser;
  final String chatPartnerId;
  final String chatPartnerName;

  const ChatRoomScreen({
    required this.currentUser,
    required this.chatPartnerId,
    required this.chatPartnerName,
    super.key,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  late String _chatRoomId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeChatRoom();
  }

  Future<void> _initializeChatRoom() async {
    try {
      final sortedIds = [widget.currentUser.uid, widget.chatPartnerId]..sort();
      _chatRoomId = sortedIds.join('_');

      // Create or update chat room document
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(_chatRoomId)
          .set({
        'participants': sortedIds,
        'lastActivity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() => _isInitialized = true);
    } catch (e) {
      print('Error initializing chat room: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing chat: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait while chat initializes...')),
      );
      return;
    }

    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    try {
      final roomRef = FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(_chatRoomId);

      await roomRef.collection('messages').add({
        'text': message,
        'senderId': widget.currentUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
      });

      await roomRef.set({
        'lastActivity': FieldValue.serverTimestamp(),
        'lastMessageText': message,
        'lastMessageSenderId': widget.currentUser.uid,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    final roomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(_chatRoomId);
    final messageRef = roomRef.collection('messages').doc(messageId);
    await messageRef.delete();

    // Recompute last message metadata efficiently
    final latest = await roomRef
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (latest.docs.isEmpty) {
      await roomRef.set({
        'lastMessageText': null,
        'lastMessageSenderId': null,
        'lastMessageTimestamp': null,
        'lastActivity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      final data = latest.docs.first.data() as Map<String, dynamic>;
      await roomRef.set({
        'lastMessageText': data['text'],
        'lastMessageSenderId': data['senderId'],
        'lastMessageTimestamp': data['timestamp'],
        'lastActivity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  String _presenceText(Map<String, dynamic>? userData) {
    if (userData == null) return '';
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
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.chatPartnerName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.chatPartnerId).snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();
            return Row(
              children: [
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    widget.chatPartnerName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.chatPartnerName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      _presenceText(data),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(_chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];
                
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start a conversation!'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (ctx, index) {
                    final doc = messages[index];
                    final messageData = doc.data() as Map<String, dynamic>;
                    return MessageBubble(
                      message: messageData['text'] ?? '',
                      isMe: messageData['senderId'] == widget.currentUser.uid,
                      timestamp: messageData['timestamp'],
                      seen: messageData['seen'] ?? false,
                      onDelete: () async {
                        final canDelete = messageData['senderId'] == widget.currentUser.uid;
                        if (!canDelete) return;
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Delete message?'),
                            content: const Text('This action cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await _deleteMessage(doc.id);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF0EFF4),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}