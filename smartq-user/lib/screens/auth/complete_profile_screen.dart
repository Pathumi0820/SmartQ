import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/profile_service.dart';
import '../home/home_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({
    super.key,
  });

  @override
  State<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState
    extends State<CompleteProfileScreen> {
  final ProfileService _profileService =
  ProfileService();

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _phoneController =
  TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    final User? user =
        FirebaseAuth.instance.currentUser;

    _nameController.text =
        user?.displayName?.trim() ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    final bool isValid =
        _formKey.currentState?.validate() ??
            false;

    if (!isValid) {
      return;
    }

    final String name =
    _nameController.text.trim();

    final String phone =
    _normalizePhone(
      _phoneController.text,
    );

    setState(() {
      isLoading = true;
    });

    try {
      await _profileService.updateProfile(
        name: name,
        phone: phone,
      );

      await FirebaseAuth.instance.currentUser
          ?.updateDisplayName(name);

      if (!mounted) {
        return;
      }

      _showMessage(
        'Profile completed successfully',
      );

      Navigator.of(context).pushAndRemoveUntil(
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
    } catch (error) {
      debugPrint(
        'Profile update error: $error',
      );

      if (!mounted) {
        return;
      }

      final String message = error
          .toString()
          .replaceFirst(
        'Exception: ',
        '',
      )
          .trim();

      _showMessage(
        message.isEmpty
            ? 'Failed to update profile'
            : message,
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

  String? _validateName(
      String? value,
      ) {
    final String name =
        value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Please enter your name';
    }

    if (name.length < 2) {
      return 'Please enter a valid name';
    }

    return null;
  }

  String? _validatePhone(
      String? value,
      ) {
    final String phone =
    _normalizePhone(
      value ?? '',
    );

    if (phone.isEmpty) {
      return 'Please enter your phone number';
    }

    if (!RegExp(
      r'^\+?[0-9]{9,15}$',
    ).hasMatch(phone)) {
      return 'Please enter a valid phone number';
    }

    return null;
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

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor:
        theme.scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor:
          theme.scaffoldBackgroundColor,
          surfaceTintColor:
          theme.scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Complete Profile',
            style: TextStyle(
              color:
              theme.colorScheme.onSurface,
              fontSize: 22,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,
              padding:
              const EdgeInsets.fromLTRB(
                24,
                24,
                24,
                36,
              ),
              child: Column(
                children: [
                  _buildHeaderCard(),
                  const SizedBox(
                    height: 28,
                  ),
                  _buildFormCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final ThemeData theme =
    Theme.of(context);

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        24,
      ),
      decoration: BoxDecoration(
        color:
        theme.colorScheme.primary,
        borderRadius:
        BorderRadius.circular(
          24,
        ),
        boxShadow: [
          BoxShadow(
            color: theme
                .colorScheme
                .primary
                .withOpacity(
              0.2,
            ),
            blurRadius: 18,
            offset:
            const Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor:
            Colors.white24,
            child: Icon(
              Icons
                  .manage_accounts_outlined,
              size: 46,
              color: Colors.white,
            ),
          ),
          SizedBox(
            height: 18,
          ),
          Text(
            'Complete Your Profile',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 7,
          ),
          Text(
            'Add your phone number so you can create and manage hospital queue tokens.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    final ThemeData theme =
    Theme.of(context);

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        20,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius:
        BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color:
          theme.dividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(
              theme.brightness ==
                  Brightness.dark
                  ? 0.18
                  : 0.04,
            ),
            blurRadius: 14,
            offset:
            const Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.bold,
              color:
              theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            'Please confirm your name and enter a valid phone number.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme
                  .onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(
            height: 22,
          ),
          TextFormField(
            controller:
            _nameController,
            enabled: !isLoading,
            textInputAction:
            TextInputAction.next,
            textCapitalization:
            TextCapitalization.words,
            validator:
            _validateName,
            autovalidateMode:
            AutovalidateMode
                .onUserInteraction,
            decoration:
            const InputDecoration(
              labelText: 'Name',
              hintText:
              'Enter your full name',
              prefixIcon: Icon(
                Icons.person_outline,
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          TextFormField(
            controller:
            _phoneController,
            enabled: !isLoading,
            keyboardType:
            TextInputType.phone,
            textInputAction:
            TextInputAction.done,
            validator:
            _validatePhone,
            autovalidateMode:
            AutovalidateMode
                .onUserInteraction,
            onFieldSubmitted: (_) {
              if (!isLoading) {
                _saveProfile();
              }
            },
            decoration:
            const InputDecoration(
              labelText:
              'Phone Number',
              hintText:
              '0712345678',
              prefixIcon: Icon(
                Icons.phone_outlined,
              ),
            ),
          ),
          const SizedBox(
            height: 26,
          ),
          SizedBox(
            width: double.infinity,
            height: 54,
            child:
            ElevatedButton.icon(
              onPressed:
              isLoading
                  ? null
                  : _saveProfile,
              icon: isLoading
                  ? SizedBox(
                width: 22,
                height: 22,
                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2.4,
                  color: theme
                      .colorScheme
                      .onPrimary,
                ),
              )
                  : const Icon(
                Icons
                    .check_circle_outline_rounded,
              ),
              label: Text(
                isLoading
                    ? 'Saving...'
                    : 'Save and Continue',
                style:
                const TextStyle(
                  fontSize: 16,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                theme
                    .colorScheme
                    .primary,
                foregroundColor:
                theme
                    .colorScheme
                    .onPrimary,
                disabledBackgroundColor:
                theme.colorScheme
                    .surfaceContainerHighest,
                disabledForegroundColor:
                theme.colorScheme
                    .onSurfaceVariant,
                elevation: 0,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}