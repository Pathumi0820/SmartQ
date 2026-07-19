import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../home/home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    super.key,
  });

  @override
  State<SignUpScreen> createState() =>
      _SignUpScreenState();
}

class _SignUpScreenState
    extends State<SignUpScreen> {
  final AuthService _authService =
  AuthService();

  final ProfileService _profileService =
  ProfileService();

  final TextEditingController
  _fullNameController =
  TextEditingController();

  final TextEditingController
  _emailController =
  TextEditingController();

  final TextEditingController
  _phoneController =
  TextEditingController();

  final TextEditingController
  _passwordController =
  TextEditingController();

  final TextEditingController
  _confirmPasswordController =
  TextEditingController();

  bool isPasswordHidden = true;
  bool isConfirmPasswordHidden = true;
  bool isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _signUp() async {
    if (isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    final String fullName =
    _fullNameController.text.trim();

    final String email =
    _emailController.text.trim();

    final String phone =
    _normalizePhone(
      _phoneController.text,
    );

    final String password =
        _passwordController.text;

    final String confirmPassword =
        _confirmPasswordController.text;

    if (fullName.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage(
        'Please fill all required fields',
        isError: true,
      );

      return;
    }

    if (fullName.length < 2) {
      _showMessage(
        'Please enter a valid full name',
        isError: true,
      );

      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage(
        'Please enter a valid email address',
        isError: true,
      );

      return;
    }

    if (!_isValidPhone(phone)) {
      _showMessage(
        'Please enter a valid phone number',
        isError: true,
      );

      return;
    }

    if (password.length < 6) {
      _showMessage(
        'Password must be at least 6 characters',
        isError: true,
      );

      return;
    }

    if (password != confirmPassword) {
      _showMessage(
        'Passwords do not match',
        isError: true,
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final UserCredential userCredential =
      await _authService
          .signUpWithEmailPassword(
        email: email,
        password: password,
      );

      final User? firebaseUser =
          userCredential.user;

      if (firebaseUser == null) {
        throw Exception(
          'Firebase account creation failed',
        );
      }

      await firebaseUser.updateDisplayName(
        fullName,
      );

      await firebaseUser.reload();

      final Map<String, dynamic> profile =
      await _profileService.syncProfile(
        name: fullName,
        phone: phone,
      );

      debugPrint(
        'MongoDB user synchronized: $profile',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Account created successfully',
      );

      Navigator.of(context)
          .pushAndRemoveUntil(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: '/home',
          ),
          builder: (_) =>
          const HomeScreen(),
        ),
            (
            Route<dynamic> route,
            ) =>
        false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _getFirebaseErrorMessage(
          error,
        ),
        isError: true,
      );
    } catch (error) {
      debugPrint(
        'Signup error: $error',
      );

      if (!mounted) {
        return;
      }

      String message = error
          .toString()
          .replaceFirst(
        'Exception: ',
        '',
      )
          .trim();

      if (message.contains('401')) {
        message =
        'Authentication failed while saving your profile';
      } else if (message.contains(
        'SocketException',
      ) ||
          message
              .toLowerCase()
              .contains('connection')) {
        message =
        'Unable to connect to the server';
      } else if (message.isEmpty) {
        message =
        'Signup failed. Please try again';
      }

      _showMessage(
        message,
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _normalizePhone(
      String value,
      ) {
    return value
        .trim()
        .replaceAll(
      RegExp(r'[\s\-()]'),
      '',
    );
  }

  bool _isValidEmail(
      String email,
      ) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(
      email.trim(),
    );
  }

  bool _isValidPhone(
      String phone,
      ) {
    return RegExp(
      r'^\+?[0-9]{9,15}$',
    ).hasMatch(
      phone,
    );
  }

  String _getFirebaseErrorMessage(
      FirebaseAuthException error,
      ) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already in use';

      case 'invalid-email':
        return 'Please enter a valid email address';

      case 'weak-password':
        return 'Password is too weak';

      case 'operation-not-allowed':
        return 'Email signup is currently disabled';

      case 'network-request-failed':
        return 'Check your internet connection';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later';

      default:
        return error.message ??
            'Signup failed. Please try again';
    }
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          isError ? Colors.red : null,
        ),
      );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final ThemeData theme =
    Theme.of(context);

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior
              .onDrag,
          padding:
          const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 18,
          ),
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(
                height: 20,
              ),
              _buildHeaderIcon(),
              const SizedBox(
                height: 18,
              ),
              Text(
                'Join SmartQ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.w600,
                  color: theme.colorScheme
                      .onSurface,
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Text(
                'Create your account to manage hospital queues easily.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme
                      .onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(
                height: 28,
              ),
              CustomTextField(
                hintText: 'Full Name',
                prefixIcon:
                Icons.person_outline,
                controller:
                _fullNameController,
              ),
              const SizedBox(
                height: 14,
              ),
              CustomTextField(
                hintText: 'Email',
                prefixIcon:
                Icons.email_outlined,
                keyboardType:
                TextInputType.emailAddress,
                controller:
                _emailController,
              ),
              const SizedBox(
                height: 14,
              ),
              CustomTextField(
                hintText: 'Phone Number',
                prefixIcon:
                Icons.call_outlined,
                keyboardType:
                TextInputType.phone,
                controller:
                _phoneController,
              ),
              const SizedBox(
                height: 14,
              ),
              CustomTextField(
                hintText: 'Password',
                prefixIcon:
                Icons.lock_outline,
                controller:
                _passwordController,
                obscureText:
                isPasswordHidden,
                suffixIcon: IconButton(
                  onPressed: isLoading
                      ? null
                      : () {
                    setState(() {
                      isPasswordHidden =
                      !isPasswordHidden;
                    });
                  },
                  icon: Icon(
                    isPasswordHidden
                        ? Icons
                        .visibility_off_outlined
                        : Icons
                        .visibility_outlined,
                    color: theme.colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(
                height: 14,
              ),
              CustomTextField(
                hintText: 'Confirm Password',
                prefixIcon:
                Icons.lock_outline,
                controller:
                _confirmPasswordController,
                obscureText:
                isConfirmPasswordHidden,
                suffixIcon: IconButton(
                  onPressed: isLoading
                      ? null
                      : () {
                    setState(() {
                      isConfirmPasswordHidden =
                      !isConfirmPasswordHidden;
                    });
                  },
                  icon: Icon(
                    isConfirmPasswordHidden
                        ? Icons
                        .visibility_off_outlined
                        : Icons
                        .visibility_outlined,
                    color: theme.colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(
                height: 26,
              ),
              if (isLoading)
                CircularProgressIndicator(
                  color:
                  theme.colorScheme.primary,
                )
              else
                CustomButton(
                  text: 'Sign Up',
                  onPressed: _signUp,
                ),
              const SizedBox(
                height: 26,
              ),
              Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      color: theme.colorScheme
                          .onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: isLoading
                        ? null
                        : () {
                      Navigator.pop(
                        context,
                      );
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: theme
                            .colorScheme
                            .primary,
                        fontWeight:
                        FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final ThemeData theme =
    Theme.of(context);

    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: isLoading
              ? null
              : () {
            Navigator.pop(
              context,
            );
          },
          icon: Icon(
            Icons
                .arrow_back_ios_new_rounded,
            color:
            theme.colorScheme.onSurface,
          ),
        ),
        Expanded(
          child: Text(
            'Create Account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight:
              FontWeight.bold,
              color:
              theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(
          width: 48,
        ),
      ],
    );
  }

  Widget _buildHeaderIcon() {
    final ThemeData theme =
    Theme.of(context);

    return Container(
      width: 94,
      height: 94,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary
            .withOpacity(
          0.12,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary
              .withOpacity(
            0.18,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness ==
                  Brightness.dark
                  ? 0.18
                  : 0.05,
            ),
            blurRadius: 14,
            offset:
            const Offset(
              0,
              5,
            ),
          ),
        ],
      ),
      child: Icon(
        Icons.person_add_alt_1_rounded,
        size: 44,
        color:
        theme.colorScheme.primary,
      ),
    );
  }
}