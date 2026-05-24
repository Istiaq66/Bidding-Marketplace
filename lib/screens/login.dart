import 'package:app/components/my_button.dart';
import 'package:app/components/my_textfield.dart';
import 'package:app/repositories/auth_repository.dart';
import 'package:flutter/material.dart';

class LoginRegister extends StatefulWidget {
  const LoginRegister({super.key});

  @override
  State<LoginRegister> createState() => _LoginRegisterState();
}

class _LoginRegisterState extends State<LoginRegister> {
  // Text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool isLoginMode = true;

  // Sign user in method
  void _signInUser() async {
    setState(() {
      isLoading = true;
    });

    try {
      await AuthRepository.signInWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Login Failed'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Register user method
  void _registerUser() async {
    // Validate passwords match
    if (passwordController.text != confirmPasswordController.text) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Password Mismatch'),
          content: const Text('Passwords do not match. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Validate password length
    if (passwordController.text.length < 6) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Weak Password'),
          content: const Text('Password must be at least 6 characters long.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await AuthRepository.signUpWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Registration Failed'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Forgot password
  void _forgotPassword() async {
    if (emailController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Email Required'),
          content: const Text('Please enter your email address.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      await AuthRepository.resetPassword(emailController.text.trim());
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Password Reset'),
            content: const Text('Password reset email sent. Check your inbox.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  // Toggle between login and register
  void _toggleMode() {
    setState(() {
      isLoginMode = !isLoginMode;
      // Clear confirm password when switching to login
      if (isLoginMode) {
        confirmPasswordController.clear();
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Logo
                const Image(
                  image: AssetImage('images/logo.png'),
                  height: 150,
                  width: 150,
                ),

                // App name
                const Text(
                  'Auction App',
                  style: TextStyle(fontFamily: 'Pacifico', fontSize: 25),
                ),

                const SizedBox(height: 20),

                // Welcome message
                Text(
                  isLoginMode
                      ? 'Welcome back, you\'ve been missed'
                      : 'Create an account to get started',
                  style: const TextStyle(fontFamily: 'SourceSans3', fontSize: 15),
                ),

                const SizedBox(height: 20),

                // Email textfield
                MyTextField(
                  controller: emailController,
                  hinText: 'Email',
                  obsecureText: false,
                ),

                const SizedBox(height: 20),

                // Password textfield
                MyTextField(
                  controller: passwordController,
                  hinText: 'Password',
                  obsecureText: true,
                ),

                const SizedBox(height: 20),

                // Confirm password textfield (only show in register mode)
                if (!isLoginMode)
                  Column(
                    children: [
                      MyTextField(
                        controller: confirmPasswordController,
                        hinText: 'Confirm Password',
                        obsecureText: true,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                // Forgot password (only show in login mode)
                if (isLoginMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _forgotPassword,
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Sign in/Register button
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : MyButton(
                  onTap: isLoginMode ? _signInUser : _registerUser,
                  text: isLoginMode ? 'Sign In' : 'Register',
                ),

                const SizedBox(height: 25),

                // Or continue with
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Google sign in button
                GestureDetector(
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await AuthRepository.signInWithGoogle();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Google sign in successful!')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sign In Failed'),
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[200],
                    ),
                    child: Image.asset(
                      'images/google.png',
                      height: 30,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Toggle between login and register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLoginMode ? 'Not a member?' : 'Already have an account?',
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: _toggleMode,
                      child: Text(
                        isLoginMode ? 'Register Now' : 'Login Now',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}