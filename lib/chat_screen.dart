import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/chat_room_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    print('DEBUG: Current user ID: ${currentUser.uid}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .snapshots(),
        builder: (ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
          // Debug print the snapshot data
          print('DEBUG: Connection state: ${snapshot.connectionState}');
          print('DEBUG: Has data: ${snapshot.hasData}');
          print('DEBUG: Error: ${snapshot.error}');
          if (snapshot.hasData) {
            print('DEBUG: Number of docs: ${snapshot.data!.docs.length}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final users = snapshot.data!.docs
              .where((doc) => doc.id != currentUser.uid)
              .toList();

          if (users.isEmpty) {
            return const Center(child: Text('No other users found.'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (ctx, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              
              print('DEBUG: User data: $userData');
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    (userData['username'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(userData['username'] ?? 'Unknown User'),
                subtitle: Text('ID: $userId'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatRoomScreen(
                        currentUser: currentUser,
                        chatPartnerId: userId,
                        chatPartnerName: userData['username'] ?? 'Unknown User',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}