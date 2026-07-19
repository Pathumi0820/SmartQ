import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../home/home_screen.dart';
import 'complete_profile_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final AuthService _authService =
  AuthService();

  final ProfileService _profileService =
  ProfileService();

  final TextEditingController
  _emailController =
  TextEditingController();

  final TextEditingController
  _passwordController =
  TextEditingController();

  bool isPasswordHidden = true;
  bool isLoading = false;
  bool _isCheckingSession = true;
  bool _navigationCompleted = false;
  bool _isResettingPassword = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _checkExistingSession();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _checkExistingSession() async {
    try {
      final User? firebaseUser =
          FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        if (mounted) {
          setState(() {
            _isCheckingSession = false;
          });
        }

        return;
      }

      debugPrint(
        'Existing Firebase session found: '
            '${firebaseUser.uid}',
      );

      final Map<String, dynamic> profile =
      await _syncMongoProfile(
        firebaseUser,
      );

      if (!mounted) {
        return;
      }

      _openCorrectScreen(profile);
    } catch (error) {
      debugPrint(
        'Existing session check failed: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isCheckingSession = false;
      });
    }
  }

  Future<void> _login() async {
    if (isLoading ||
        _isCheckingSession ||
        _navigationCompleted) {
      return;
    }

    FocusScope.of(context).unfocus();

    final String email =
    _emailController.text.trim();

    final String password =
        _passwordController.text;

    if (email.isEmpty ||
        password.isEmpty) {
      _showMessage(
        'Please enter email and password',
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

    setState(() {
      isLoading = true;
    });

    try {
      await _authService
          .loginWithEmailPassword(
        email: email,
        password: password,
      );

      final User? firebaseUser =
          FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        throw Exception(
          'Firebase login failed',
        );
      }

      final Map<String, dynamic> profile =
      await _syncMongoProfile(
        firebaseUser,
      );

      if (!mounted) {
        return;
      }

      _openCorrectScreen(profile);
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _getLoginErrorMessage(
          error.code,
        ),
        isError: true,
      );
    } catch (error) {
      debugPrint(
        'Login error: $error',
      );

      if (!mounted) {
        return;
      }

      final String message =
      _cleanErrorMessage(error);

      _showMessage(
        message.isEmpty
            ? 'Login failed. Please try again'
            : message,
        isError: true,
      );
    } finally {
      if (mounted &&
          !_navigationCompleted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _googleLogin() async {
    if (isLoading ||
        _isCheckingSession ||
        _navigationCompleted) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      final dynamic result =
      await _authService
          .signInWithGoogle();

      if (result == null) {
        if (mounted) {
          _showMessage(
            'Google sign-in cancelled',
          );
        }

        return;
      }

      final User? firebaseUser =
          FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        throw Exception(
          'Google authentication failed',
        );
      }

      final Map<String, dynamic> profile =
      await _syncMongoProfile(
        firebaseUser,
      );

      if (!mounted) {
        return;
      }

      _openCorrectScreen(profile);
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message ??
            'Google sign-in failed',
        isError: true,
      );
    } catch (error) {
      debugPrint(
        'Google login error: $error',
      );

      if (!mounted) {
        return;
      }

      final String message =
      _cleanErrorMessage(error);

      _showMessage(
        message.isEmpty
            ? 'Google sign-in failed'
            : message,
        isError: true,
      );
    } finally {
      if (mounted &&
          !_navigationCompleted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_isResettingPassword ||
        isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    final String email =
    _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage(
        'Enter your email address first',
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

    final bool confirmed =
    await _showResetPasswordDialog(
      email,
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isResettingPassword = true;
    });

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Password reset email sent to $email',
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      String message;

      switch (error.code) {
        case 'user-not-found':
          message =
          'No account found with this email';
          break;

        case 'invalid-email':
          message =
          'Please enter a valid email address';
          break;

        case 'too-many-requests':
          message =
          'Too many requests. Please try again later';
          break;

        case 'network-request-failed':
          message =
          'Check your internet connection';
          break;

        default:
          message =
              error.message ??
                  'Failed to send reset email';
      }

      _showMessage(
        message,
        isError: true,
      );
    } catch (error) {
      debugPrint(
        'Password reset error: $error',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to send reset email',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResettingPassword = false;
        });
      }
    }
  }

  Future<bool> _showResetPasswordDialog(
      String email,
      ) async {
    final ThemeData theme =
    Theme.of(context);

    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor:
          theme.dialogBackgroundColor,
          surfaceTintColor:
          theme.dialogBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.lock_reset_rounded,
                color:
                theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Reset Password',
                  style: TextStyle(
                    color: theme
                        .colorScheme
                        .onSurface,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Send a password reset link to $email?',
            style: TextStyle(
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Send Link',
              ),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<Map<String, dynamic>>
  _syncMongoProfile(
      User firebaseUser,
      ) async {
    final Map<String, dynamic> profile =
    await _profileService.syncProfile(
      name: _getFirebaseUserName(
        firebaseUser,
      ),
      phone:
      firebaseUser.phoneNumber ?? '',
    );

    debugPrint(
      'MongoDB user synchronized: $profile',
    );

    return profile;
  }

  void _openCorrectScreen(
      Map<String, dynamic> profile,
      ) {
    if (!mounted ||
        _navigationCompleted) {
      return;
    }

    _navigationCompleted = true;

    final String phone =
        profile['phone']
            ?.toString()
            .trim() ??
            '';

    final bool hasCompletedProfile =
        phone.isNotEmpty;

    final Widget targetScreen =
    hasCompletedProfile
        ? const HomeScreen()
        : const CompleteProfileScreen();

    final String routeName =
    hasCompletedProfile
        ? '/home'
        : '/complete-profile';

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute<void>(
        settings: RouteSettings(
          name: routeName,
        ),
        builder: (_) => targetScreen,
      ),
          (
          Route<dynamic> route,
          ) =>
      false,
    );
  }

  String _getFirebaseUserName(
      User user,
      ) {
    final String displayName =
        user.displayName?.trim() ?? '';

    if (displayName.isNotEmpty) {
      return displayName;
    }

    final String email =
        user.email?.trim() ?? '';

    if (email.contains('@')) {
      final String emailName =
      email.split('@').first.trim();

      if (emailName.isNotEmpty) {
        return emailName;
      }
    }

    return 'Patient';
  }

  bool _isValidEmail(
      String value,
      ) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(value.trim());
  }

  String _cleanErrorMessage(
      Object error,
      ) {
    final String message = error
        .toString()
        .replaceFirst(
      'Exception: ',
      '',
    )
        .trim();

    if (message.contains('401')) {
      return 'Authentication failed. Please log in again.';
    }

    if (message.contains(
      'SocketException',
    ) ||
        message
            .toLowerCase()
            .contains('connection')) {
      return 'Unable to connect to the server';
    }

    return message;
  }

  String _getLoginErrorMessage(
      String errorCode,
      ) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email';

      case 'wrong-password':
        return 'Incorrect password';

      case 'invalid-email':
        return 'Invalid email address';

      case 'invalid-credential':
        return 'Invalid email or password';

      case 'user-disabled':
        return 'This account has been disabled';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later';

      case 'network-request-failed':
        return 'Check your internet connection';

      default:
        return 'Login failed. Please try again';
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

    if (_isCheckingSession) {
      return Scaffold(
        backgroundColor:
        theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color:
            theme.colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior
              .onDrag,
          child: Column(
            children: [
              _topHeader(),
              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 22,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight:
                        FontWeight.bold,
                        color: theme
                            .colorScheme
                            .onSurface,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      'Please login to continue',
                      style: TextStyle(
                        fontSize: 15,
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(
                      height: 28,
                    ),
                    CustomTextField(
                      hintText: 'Email',
                      prefixIcon:
                      Icons.email_outlined,
                      keyboardType:
                      TextInputType
                          .emailAddress,
                      controller:
                      _emailController,
                    ),
                    const SizedBox(
                      height: 16,
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
                        onPressed:
                        isLoading
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
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Align(
                      alignment:
                      Alignment.centerRight,
                      child: TextButton(
                        onPressed:
                        isLoading ||
                            _isResettingPassword
                            ? null
                            : _resetPassword,
                        child: _isResettingPassword
                            ? SizedBox(
                          width: 18,
                          height: 18,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme
                                .colorScheme
                                .primary,
                          ),
                        )
                            : const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontWeight:
                            FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    if (isLoading)
                      Center(
                        child:
                        CircularProgressIndicator(
                          color: theme
                              .colorScheme
                              .primary,
                        ),
                      )
                    else
                      Column(
                        children: [
                          CustomButton(
                            text: 'Login',
                            onPressed:
                            _login,
                          ),
                          const SizedBox(
                            height: 14,
                          ),
                          SizedBox(
                            width:
                            double.infinity,
                            height: 52,
                            child:
                            OutlinedButton(
                              onPressed:
                              _googleLogin,
                              style:
                              OutlinedButton
                                  .styleFrom(
                                foregroundColor:
                                theme
                                    .colorScheme
                                    .onSurface,
                                side: BorderSide(
                                  color: theme
                                      .dividerColor,
                                ),
                                backgroundColor:
                                theme
                                    .cardColor,
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(
                                    12,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                                children: [
                                  Image.asset(
                                    'assets/images/google_logo.png',
                                    width: 22,
                                    height: 22,
                                    errorBuilder: (
                                        BuildContext context,
                                        Object error,
                                        StackTrace?
                                        stackTrace,
                                        ) {
                                      return const Icon(
                                        Icons
                                            .account_circle_outlined,
                                        size: 22,
                                      );
                                    },
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  const Text(
                                    'Continue with Google',
                                    style:
                                    TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                      FontWeight
                                          .w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(
                      height: 28,
                    ),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: theme
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () {
                            Navigator.of(
                              context,
                            ).push(
                              MaterialPageRoute<
                                  void>(
                                settings:
                                const RouteSettings(
                                  name:
                                  '/signup',
                                ),
                                builder: (_) =>
                                const SignUpScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Sign Up',
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topHeader() {
    final ThemeData theme =
    Theme.of(context);

    return Container(
      height: 270,
      width: double.infinity,
      decoration: BoxDecoration(
        color:
        theme.colorScheme.primary,
        borderRadius:
        const BorderRadius.only(
          bottomLeft:
          Radius.elliptical(
            250,
            60,
          ),
          bottomRight:
          Radius.elliptical(
            250,
            60,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme
                .colorScheme
                .primary
                .withOpacity(0.24),
            blurRadius: 18,
            offset:
            const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_hospital_rounded,
            color: Colors.white,
            size: 72,
          ),
          SizedBox(height: 12),
          Text(
            'Hospital Queue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Management System',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 22,
              fontWeight:
              FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}