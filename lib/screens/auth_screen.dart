import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/config/theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  var _isLogin = true;
  var _isLoading = false;
  String _userEmail = '';
  String _userName = '';
  String _userPassword = '';

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _trySubmit() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (!isValid) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _userEmail.trim(),
          password: _userPassword.trim(),
        );
      } else {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _userEmail.trim(),
          password: _userPassword.trim(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': _userName.trim(),
          'email': _userEmail.trim(),
          'online': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (err) {
      var message = 'An error occurred, please check your credentials!';
      if (err.message != null) {
        message = err.message!;
      }
      _showError(message);
    } catch (err) {
      _showError('An error occurred. Please try again later.');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: const Icon(Icons.chat_bubble_rounded, size: 40, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isLogin ? 'Welcome back' : 'Create your account',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLogin ? 'Login to continue chatting' : 'Join to start chatting',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin)
                            TextFormField(
                              key: const ValueKey('username'),
                              validator: (value) =>
                                  value!.isEmpty ? 'Please enter a username' : null,
                              decoration: const InputDecoration(labelText: 'Username'),
                              onSaved: (value) => _userName = value!,
                            ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('email'),
                            validator: (value) =>
                                !value!.contains('@') ? 'Invalid email' : null,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'Email address'),
                            onSaved: (value) => _userEmail = value!,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('password'),
                            validator: (value) => value!.length < 7
                                ? 'Password must be at least 7 characters'
                                : null,
                            decoration: const InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            onSaved: (value) => _userPassword = value!,
                          ),
                          const SizedBox(height: 16),
                          if (_isLoading)
                            const CircularProgressIndicator()
                          else
                            Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _trySubmit,
                                    icon: const Icon(Icons.login_rounded),
                                    label: Text(_isLogin ? 'Login' : 'Sign up'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    setState(() => _isLogin = !_isLogin);
                                  },
                                  child: Text(
                                    _isLogin
                                        ? 'Create new account'
                                        : 'I already have an account',
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
