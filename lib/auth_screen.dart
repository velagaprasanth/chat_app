import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/config/theme.dart';
import 'dart:ui';
import 'dart:math' as math;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  var _isLogin = true;
  var _isLoading = false;
  String _userEmail = '';
  String _userName = '';
  String _userPassword = '';
  
  late AnimationController _backgroundController;
  late AnimationController _formController;
  late AnimationController _switchController;
  late AnimationController _floatingController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _formSlideAnimation;
  late Animation<double> _formFadeAnimation;
  late Animation<double> _switchAnimation;
  late Animation<double> _floatingAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();
    
    _formController = AnimationController(
      duration: AppTheme.slowAnimation,
      vsync: this,
    );
    
    _switchController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );
    
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_backgroundController);
    
    _formSlideAnimation = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOutCubic,
    ));
    
    _formFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
    
    _switchAnimation = CurvedAnimation(
      parent: _switchController,
      curve: Curves.easeInOutBack,
    );
    
    _floatingAnimation = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));
    
    _formController.forward();
  }
  
  @override
  void dispose() {
    _backgroundController.dispose();
    _formController.dispose();
    _switchController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        ),
        margin: const EdgeInsets.all(16),
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Stack(
        children: [
          // Modern gradient background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(
                      math.cos(_backgroundAnimation.value) * 0.8,
                      math.sin(_backgroundAnimation.value) * 0.8,
                    ),
                    end: Alignment(
                      -math.cos(_backgroundAnimation.value) * 0.8,
                      -math.sin(_backgroundAnimation.value) * 0.8,
                    ),
                    colors: const [
                      Color(0xFF6C5CE7),
                      Color(0xFFA29BFE),
                      Color(0xFF74B9FF),
                      Color(0xFF0984E3),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              );
            },
          ),
          
          // Floating geometric shapes
          ...List.generate(4, (index) => _buildFloatingShape(index, screenWidth, screenHeight)),
          
          // Main content with enhanced animations
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedBuilder(
                  animation: _formController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _formSlideAnimation.value),
                      child: Opacity(
                        opacity: _formFadeAnimation.value,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Enhanced logo with floating animation
                            AnimatedBuilder(
                              animation: _floatingAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _floatingAnimation.value),
                                  child: Hero(
                                    tag: 'logo',
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [Colors.white60, Colors.white30],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(0.3),
                                            blurRadius: 25,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.3),
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.forum_rounded,
                                              size: 45,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 40),
                            
                            // Enhanced title with staggered animation
                            AnimatedSwitcher(
                              duration: AppTheme.mediumAnimation,
                              transitionBuilder: (child, animation) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.3),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  )),
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                key: ValueKey(_isLogin),
                                children: [
                                  Text(
                                    _isLogin ? 'Welcome Back' : 'Join Us Today',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 20,
                                          color: Colors.black26,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isLogin 
                                        ? 'Sign in to continue your conversations'
                                        : 'Create your account to get started',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.85),
                                      letterSpacing: 0.2,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 50),
                            
                            // Enhanced glassmorphic form container
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppTheme.largeRadius),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                                child: Container(
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.25),
                                        Colors.white.withOpacity(0.15),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(AppTheme.largeRadius),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        // Animated username field
                                        AnimatedSize(
                                          duration: AppTheme.mediumAnimation,
                                          curve: Curves.easeInOutCubic,
                                          child: !_isLogin
                                              ? Column(
                                                  children: [
                                                    _buildModernTextField(
                                                      key: const ValueKey('username'),
                                                      icon: Icons.person_outline_rounded,
                                                      label: 'Username',
                                                      validator: (value) =>
                                                          value!.isEmpty ? 'Please enter a username' : null,
                                                      onSaved: (value) => _userName = value!,
                                                    ),
                                                    const SizedBox(height: 20),
                                                  ],
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                        
                                        // Email field
                                        _buildModernTextField(
                                          key: const ValueKey('email'),
                                          icon: Icons.alternate_email_rounded,
                                          label: 'Email',
                                          validator: (value) =>
                                              !value!.contains('@') ? 'Please enter a valid email' : null,
                                          keyboardType: TextInputType.emailAddress,
                                          onSaved: (value) => _userEmail = value!,
                                        ),
                                        const SizedBox(height: 20),
                                        
                                        // Password field
                                        _buildModernTextField(
                                          key: const ValueKey('password'),
                                          icon: Icons.lock_outline_rounded,
                                          label: 'Password',
                                          obscureText: true,
                                          validator: (value) => value!.length < 7
                                              ? 'Password must be at least 7 characters'
                                              : null,
                                          onSaved: (value) => _userPassword = value!,
                                        ),
                                        const SizedBox(height: 32),
                                        
                                        // Enhanced submit button
                                        _buildSubmitButton(),
                                        const SizedBox(height: 20),
                                        
                                        // Enhanced switch auth mode button
                                        AnimatedBuilder(
                                          animation: _switchAnimation,
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale: 1.0 + (_switchAnimation.value * 0.05),
                                              child: TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _isLogin = !_isLogin;
                                                    _switchController.forward(from: 0);
                                                  });
                                                },
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                                                  ),
                                                ),
                                                child: RichText(
                                                  textAlign: TextAlign.center,
                                                  text: TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text: _isLogin
                                                            ? "Don't have an account? "
                                                            : 'Already have an account? ',
                                                        style: TextStyle(
                                                          color: Colors.white.withOpacity(0.8),
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text: _isLogin ? 'Sign Up' : 'Sign In',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModernTextField({
    required Key key,
    required IconData icon,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
    required void Function(String?) onSaved,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        color: Colors.white.withOpacity(0.15),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        key: key,
        validator: validator,
        onSaved: onSaved,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12),
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.8),
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 50),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }
  
  Widget _buildSubmitButton() {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.largeRadius),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.3),
              Colors.white.withOpacity(0.2),
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.largeRadius),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFF8F9FA),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.largeRadius),
                onTap: _trySubmit,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isLogin ? Icons.login_rounded : Icons.person_add_rounded,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isLogin ? 'Sign In' : 'Create Account',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildFloatingShape(int index, double width, double height) {
    final random = math.Random(index + 42);
    final size = 60.0 + random.nextDouble() * 80;
    final initialX = random.nextDouble() * width;
    final initialY = random.nextDouble() * height;
    
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        final offsetX = math.sin(_backgroundAnimation.value + index) * 30;
        final offsetY = math.cos(_backgroundAnimation.value + index * 0.7) * 20;
        
        return Positioned(
          left: initialX + offsetX,
          top: initialY + offsetY,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: index % 3 == 0 ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: index % 3 != 0 
                  ? BorderRadius.circular(size * 0.3) 
                  : null,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.03),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
        );
      },
    );
  }
}