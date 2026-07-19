import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool locationAccessEnabled = true;

  bool isSavingNotifications = false;
  bool isSavingLocation = false;
  bool isChangingPassword = false;

  Future<void> _updateNotifications(
      bool value,
      ) async {
    if (isSavingNotifications) {
      return;
    }

    final bool previousValue =
        notificationsEnabled;

    setState(() {
      notificationsEnabled = value;
      isSavingNotifications = true;
    });

    try {
      await Future<void>.delayed(
        const Duration(
          milliseconds: 250,
        ),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        value
            ? 'Notifications enabled'
            : 'Notifications disabled',
      );
    } catch (error) {
      debugPrint(
        'Notification setting error: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        notificationsEnabled =
            previousValue;
      });

      _showMessage(
        'Failed to update notifications',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSavingNotifications = false;
        });
      }
    }
  }

  Future<void> _updateLocationAccess(
      bool value,
      ) async {
    if (isSavingLocation) {
      return;
    }

    final bool previousValue =
        locationAccessEnabled;

    setState(() {
      locationAccessEnabled = value;
      isSavingLocation = true;
    });

    try {
      await Future<void>.delayed(
        const Duration(
          milliseconds: 250,
        ),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        value
            ? 'Location access enabled'
            : 'Location access disabled',
      );
    } catch (error) {
      debugPrint(
        'Location setting error: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        locationAccessEnabled =
            previousValue;
      });

      _showMessage(
        'Failed to update location access',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSavingLocation = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    if (isChangingPassword) {
      return;
    }

    final ThemeData theme =
    Theme.of(context);

    final User? user =
        FirebaseAuth.instance.currentUser;

    final String email =
        user?.email?.trim() ?? '';

    if (email.isEmpty) {
      _showMessage(
        'No email address is linked to this account',
        isError: true,
      );

      return;
    }

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
            BorderRadius.circular(
              20,
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.lock_reset_rounded,
                color:
                theme.colorScheme.primary,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  'Change Password',
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

    if (confirmed != true ||
        !mounted) {
      return;
    }

    setState(() {
      isChangingPassword = true;
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
        'Password reset link sent to $email',
      );
    } on FirebaseAuthException catch (error) {
      debugPrint(
        'Password reset error: $error',
      );

      if (!mounted) {
        return;
      }

      String message;

      switch (error.code) {
        case 'invalid-email':
          message =
          'The account email is invalid';
          break;

        case 'user-not-found':
          message =
          'No account was found for this email';
          break;

        case 'too-many-requests':
          message =
          'Too many requests. Try again later';
          break;

        case 'network-request-failed':
          message =
          'Check your internet connection';
          break;

        default:
          message =
              error.message ??
                  'Failed to send reset link';
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
        'Failed to send password reset link',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isChangingPassword = false;
        });
      }
    }
  }

  Future<void> _showPrivacyPolicy() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
      Colors.transparent,
      builder: (
          BuildContext sheetContext,
          ) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (
              BuildContext context,
              ScrollController
              scrollController,
              ) {
            final ThemeData theme =
            Theme.of(context);

            return Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius:
                const BorderRadius.vertical(
                  top: Radius.circular(
                    28,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(
                    height: 12,
                  ),
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color:
                      theme.dividerColor,
                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                    const EdgeInsets.fromLTRB(
                      22,
                      20,
                      22,
                      14,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                          theme
                              .colorScheme
                              .primary
                              .withOpacity(
                            0.12,
                          ),
                          child: Icon(
                            Icons
                                .privacy_tip_outlined,
                            color: theme
                                .colorScheme
                                .primary,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                              FontWeight.bold,
                              color: theme
                                  .colorScheme
                                  .onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color:
                    theme.dividerColor,
                  ),
                  Expanded(
                    child: ListView(
                      controller:
                      scrollController,
                      padding:
                      const EdgeInsets.all(
                        22,
                      ),
                      children: const [
                        _PolicySection(
                          title:
                          'Information We Collect',
                          description:
                          'SmartQ may store profile information such as your name, email address, phone number, profile photo, and token history.',
                        ),
                        _PolicySection(
                          title:
                          'How Information Is Used',
                          description:
                          'Your information is used to create hospital tokens, identify your active queue, provide notifications, and improve the application experience.',
                        ),
                        _PolicySection(
                          title:
                          'Location Information',
                          description:
                          'Location access is optional and should only be used to help identify nearby hospitals when that feature is enabled.',
                        ),
                        _PolicySection(
                          title:
                          'Notifications',
                          description:
                          'Notifications may be used to inform you when your token is called, served, completed, or cancelled.',
                        ),
                        _PolicySection(
                          title:
                          'Data Security',
                          description:
                          'Authentication and reasonable security controls are used to protect your account and personal information.',
                        ),
                        _PolicySection(
                          title:
                          'Your Choices',
                          description:
                          'You may update your profile, disable optional permissions, and log out of your account at any time.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAppInformation() async {
    final ThemeData theme =
    Theme.of(context);

    await showDialog<void>(
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
            BorderRadius.circular(
              22,
            ),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                theme
                    .colorScheme
                    .primary
                    .withOpacity(
                  0.12,
                ),
                child: Icon(
                  Icons
                      .local_hospital_rounded,
                  color:
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Text(
                'SmartQ',
                style: TextStyle(
                  color: theme
                      .colorScheme
                      .onSurface,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize:
            MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'SmartQ Hospital Queue Management System',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
              SizedBox(
                height: 12,
              ),
              _VersionRow(
                label: 'Version',
                value: '1.0.0',
              ),
              SizedBox(
                height: 8,
              ),
              _VersionRow(
                label: 'Platform',
                value: 'Mobile',
              ),
              SizedBox(
                height: 8,
              ),
              _VersionRow(
                label: 'Status',
                value: 'Stable',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Close',
              ),
            ),
          ],
        );
      },
    );
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

    final ThemeProvider themeProvider =
    context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor:
      theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
        theme.scaffoldBackgroundColor,
        surfaceTintColor:
        theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color:
          theme.colorScheme.onSurface,
        ),
        title: Text(
          'Settings',
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
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            32,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(
                height: 24,
              ),
              _buildSectionTitle(
                'Preferences',
              ),
              const SizedBox(
                height: 12,
              ),
              _buildSettingsCard(
                children: [
                  _buildSwitchTile(
                    icon: Icons
                        .notifications_none_rounded,
                    title:
                    'Notifications',
                    subtitle:
                    'Receive token and queue updates',
                    value:
                    notificationsEnabled,
                    isLoading:
                    isSavingNotifications,
                    onChanged:
                    _updateNotifications,
                  ),
                  _divider(),
                  _buildSwitchTile(
                    icon:
                    Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle:
                    'Use a darker application theme',
                    value:
                    themeProvider.isDarkMode,
                    onChanged: (
                        bool value,
                        ) async {
                      try {
                        await context
                            .read<ThemeProvider>()
                            .setDarkMode(
                          value,
                        );

                        if (!mounted) {
                          return;
                        }

                        _showMessage(
                          value
                              ? 'Dark mode enabled'
                              : 'Light mode enabled',
                        );
                      } catch (error) {
                        debugPrint(
                          'Theme update error: $error',
                        );

                        if (!mounted) {
                          return;
                        }

                        _showMessage(
                          'Failed to update theme',
                          isError: true,
                        );
                      }
                    },
                  ),
                  _divider(),
                  _buildSwitchTile(
                    icon: Icons
                        .location_on_outlined,
                    title:
                    'Location Access',
                    subtitle:
                    'Allow nearby hospital features',
                    value:
                    locationAccessEnabled,
                    isLoading:
                    isSavingLocation,
                    onChanged:
                    _updateLocationAccess,
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              _buildSectionTitle(
                'Security',
              ),
              const SizedBox(
                height: 12,
              ),
              _buildSettingsCard(
                children: [
                  _buildMenuTile(
                    icon:
                    Icons.lock_outline,
                    title:
                    'Change Password',
                    subtitle:
                    'Reset your account password',
                    isLoading:
                    isChangingPassword,
                    onTap:
                    _changePassword,
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              _buildSectionTitle(
                'About',
              ),
              const SizedBox(
                height: 12,
              ),
              _buildSettingsCard(
                children: [
                  _buildMenuTile(
                    icon: Icons
                        .privacy_tip_outlined,
                    title:
                    'Privacy Policy',
                    subtitle:
                    'Learn how your information is used',
                    onTap:
                    _showPrivacyPolicy,
                  ),
                  _divider(),
                  _buildMenuTile(
                    icon:
                    Icons.info_outline,
                    title:
                    'App Information',
                    subtitle:
                    'Version 1.0.0',
                    onTap:
                    _showAppInformation,
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              Center(
                child: Text(
                  'SmartQ © 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ),
            ],
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
        20,
      ),
      decoration: BoxDecoration(
        color:
        theme.colorScheme.primary,
        borderRadius:
        BorderRadius.circular(
          22,
        ),
        boxShadow: [
          BoxShadow(
            color: theme
                .colorScheme
                .primary
                .withOpacity(
              0.2,
            ),
            blurRadius: 16,
            offset:
            const Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor:
            Colors.white24,
            child: Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(
            width: 14,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Application Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  'Manage your preferences, security, and privacy.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      String title,
      ) {
    final ThemeData theme =
    Theme.of(context);

    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight:
        FontWeight.bold,
        color:
        theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSettingsCard({
    required List<Widget> children,
  }) {
    final ThemeData theme =
    Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius:
        BorderRadius.circular(
          20,
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
                  : 0.035,
            ),
            blurRadius: 12,
            offset:
            const Offset(
              0,
              5,
            ),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>
    onChanged,
    bool isLoading = false,
  }) {
    final ThemeData theme =
    Theme.of(context);

    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 7,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: theme
              .colorScheme
              .primary
              .withOpacity(
            0.12,
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 21,
          color:
          theme.colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color:
          theme.colorScheme.onSurface,
          fontWeight:
          FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding:
        const EdgeInsets.only(
          top: 3,
        ),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: theme
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
      ),
      trailing: isLoading
          ? SizedBox(
        width: 22,
        height: 22,
        child:
        CircularProgressIndicator(
          strokeWidth: 2.2,
          color: theme
              .colorScheme
              .primary,
        ),
      )
          : Switch.adaptive(
        value: value,
        activeColor:
        theme.colorScheme.primary,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    final ThemeData theme =
    Theme.of(context);

    return ListTile(
      onTap:
      isLoading ? null : onTap,
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 7,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: theme
              .colorScheme
              .primary
              .withOpacity(
            0.12,
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 21,
          color:
          theme.colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color:
          theme.colorScheme.onSurface,
          fontWeight:
          FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding:
        const EdgeInsets.only(
          top: 3,
        ),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: theme
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
      ),
      trailing: isLoading
          ? SizedBox(
        width: 20,
        height: 20,
        child:
        CircularProgressIndicator(
          strokeWidth: 2.1,
          color: theme
              .colorScheme
              .primary,
        ),
      )
          : Icon(
        Icons
            .arrow_forward_ios_rounded,
        size: 15,
        color: theme
            .colorScheme
            .onSurfaceVariant,
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 0.7,
      color:
      Theme.of(context).dividerColor,
      indent: 78,
      endIndent: 18,
    );
  }
}

class _PolicySection
    extends StatelessWidget {
  final String title;
  final String description;

  const _PolicySection({
    required this.title,
    required this.description,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final ThemeData theme =
    Theme.of(context);

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 22,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.bold,
              color: theme
                  .colorScheme
                  .onSurface,
            ),
          ),
          const SizedBox(
            height: 7,
          ),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _VersionRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final ThemeData theme =
    Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: theme
                .colorScheme
                .onSurface,
            fontWeight:
            FontWeight.w600,
          ),
        ),
      ],
    );
  }
}