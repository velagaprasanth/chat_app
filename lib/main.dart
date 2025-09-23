// lib/main.dart

import 'package:chat_app/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/screens/auth_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/config/theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FirebaseAuth.instance.authStateChanges().listen(_handleAuthChange);
  }

  Future<void> _ensureUserProfile(User user) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await docRef.get();
    final current = snap.data() ?? <String, dynamic>{};

    final email = user.email ?? current['email'] as String?;
    final displayName = (user.displayName != null && user.displayName!.trim().isNotEmpty)
        ? user.displayName!
        : null;

    // Always ensure we have a username - prioritize existing, then displayName, then email local-part
    String? usernameToSet;
    final existingUsername = (current['username'] as String?)?.trim();
    
    if (existingUsername != null && existingUsername.isNotEmpty) {
      usernameToSet = existingUsername; // Keep existing username
    } else if (displayName != null) {
      usernameToSet = displayName; // Use Firebase displayName
    } else if (email != null && email.contains('@')) {
      usernameToSet = email.split('@').first; // Use email local-part
    }

    // Prepare update data
    final updateData = <String, dynamic>{};
    
    if (usernameToSet != null && (existingUsername == null || existingUsername.isEmpty)) {
      updateData['username'] = usernameToSet;
    }
    
    if (email != null && (current['email'] == null || (current['email'] as String).trim().isEmpty)) {
      updateData['email'] = email;
    }
    
    // Always ensure online status and lastSeen are set
    updateData['online'] = true;
    updateData['lastSeen'] = FieldValue.serverTimestamp();
    
    if (updateData.isNotEmpty) {
      await docRef.set(updateData, SetOptions(merge: true));
    }
  }

  Future<void> _handleAuthChange(User? user) async {
    if (user == null) return;
    await _ensureUserProfile(user);
    await _setOnlineStatus(user.uid, isOnline: true);
  }

  Future<void> _setOnlineStatus(String uid, {required bool isOnline}) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'online': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (state == AppLifecycleState.resumed) {
      _setOnlineStatus(user.uid, isOnline: true);
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _setOnlineStatus(user.uid, isOnline: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat App',
      theme: AppTheme.lightTheme,
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, userSnapshot) {
          if (userSnapshot.hasData) {
            return const ChatScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}