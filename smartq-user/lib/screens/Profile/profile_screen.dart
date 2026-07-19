import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../token/token_history_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  Map<String, dynamic>? userData;

  bool isLoading = true;
  bool isRefreshing = false;
  bool isLoggingOut = false;

  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }

    try {
      final dynamic document =
      await _authService.getCurrentUserData();

      if (!mounted) return;

      if (document.exists == true) {
        final dynamic data = document.data();

        setState(() {
          userData = data is Map
              ? Map<String, dynamic>.from(data)
              : null;

          isLoading = false;
          isRefreshing = false;
          errorMessage = '';
        });
      } else {
        setState(() {
          userData = null;
          isLoading = false;
          isRefreshing = false;
          errorMessage =
          'Profile information was not found.';
        });
      }
    } catch (error) {
      debugPrint(
        'Profile loading error: $error',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshing = false;
        errorMessage =
        'Failed to load your profile.';
      });
    }
  }

  Future<void> _refreshProfile() async {
    if (isRefreshing) return;

    setState(() {
      isRefreshing = true;
      errorMessage = '';
    });

    await _loadUserData(
      showLoading: false,
    );
  }

  Future<void> _logout() async {
    if (isLoggingOut) return;

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
              const Icon(
                Icons.logout_rounded,
                color: Colors.red,
              ),
              const SizedBox(width: 10),
              Text(
                'Logout',
                style: TextStyle(
                  color: theme
                      .colorScheme
                      .onSurface,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to log out of your SmartQ account?',
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
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.red,
                foregroundColor:
                Colors.white,
                elevation: 0,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              child: const Text(
                'Logout',
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
      isLoggingOut = true;
    });

    try {
      await _authService.signOut();

      if (!mounted) return;

      Navigator.of(context)
          .pushAndRemoveUntil(
        MaterialPageRoute<void>(
          settings:
          const RouteSettings(
            name: '/login',
          ),
          builder: (_) =>
          const LoginScreen(),
        ),
            (
            Route<dynamic> route,
            ) =>
        false,
      );
    } catch (error) {
      debugPrint(
        'Logout error: $error',
      );

      if (!mounted) return;

      _showMessage(
        'Logout failed. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoggingOut = false;
        });
      }
    }
  }

  Future<void> _openEditProfile() async {
    final Map<String, dynamic>?
    currentUser = userData;

    if (currentUser == null) {
      _showMessage(
        'Profile data is unavailable.',
        isError: true,
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute<bool>(
        builder: (_) =>
            EditProfileScreen(
              userData: currentUser,
            ),
      ),
    );

    if (!mounted) return;

    await _loadUserData(
      showLoading: false,
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
        const SettingsScreen(),
      ),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
        const TokenHistoryScreen(),
      ),
    );
  }

  Future<void> _showHelpDialog() async {
    final ThemeData theme =
    Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
      Colors.transparent,
      builder: (
          BuildContext sheetContext,
          ) {
        return SafeArea(
          child: Container(
            padding:
            const EdgeInsets.fromLTRB(
              22,
              14,
              22,
              28,
            ),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius:
              const BorderRadius
                  .vertical(
                top:
                Radius.circular(28),
              ),
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration:
                    BoxDecoration(
                      color:
                      theme.dividerColor,
                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 22,
                ),
                Row(
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
                            .support_agent_rounded,
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
                        'Help and Support',
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
                const SizedBox(
                  height: 20,
                ),
                _buildSupportItem(
                  icon: Icons
                      .confirmation_number_outlined,
                  title:
                  'Token support',
                  description:
                  'For problems creating, viewing, or cancelling a token.',
                ),
                _buildSupportItem(
                  icon: Icons
                      .account_circle_outlined,
                  title:
                  'Profile support',
                  description:
                  'For problems updating your personal information.',
                ),
                _buildSupportItem(
                  icon: Icons
                      .wifi_off_outlined,
                  title:
                  'Connection problems',
                  description:
                  'Check your internet connection and refresh the page.',
                ),
                const SizedBox(
                  height: 8,
                ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child:
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        sheetContext,
                      );
                    },
                    child:
                    const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAboutDialog() async {
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
            BorderRadius.circular(22),
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
                  'About SmartQ',
                  style: TextStyle(
                    color: theme
                        .colorScheme
                        .onSurface,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize:
            MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'SmartQ helps patients find hospitals, join department queues, receive tokens, and monitor queue progress.',
                style: TextStyle(
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: theme
                      .colorScheme
                      .primary,
                  fontWeight:
                  FontWeight.w600,
                ),
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

  Widget _buildSupportItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final ThemeData theme =
    Theme.of(context);

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 18,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
            BoxDecoration(
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
              color:
              theme.colorScheme.primary,
              size: 21,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w600,
                    color: theme
                        .colorScheme
                        .onSurface,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          isError
              ? Colors.red
              : null,
        ),
      );
  }

  String _readString(
      List<String> keys, {
        String fallback = '',
      }) {
    for (final String key in keys) {
      final String value =
          userData?[key]
              ?.toString()
              .trim() ??
              '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    return fallback;
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
      appBar: AppBar(
        backgroundColor:
        theme.scaffoldBackgroundColor,
        surfaceTintColor:
        theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: theme
              .colorScheme
              .onSurface,
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: theme
                .colorScheme
                .onSurface,
            fontWeight:
            FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed:
            _openSettings,
            icon: const Icon(
              Icons.settings_outlined,
            ),
          ),
          const SizedBox(
            width: 6,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final ThemeData theme =
    Theme.of(context);

    if (isLoading) {
      return Center(
        child:
        CircularProgressIndicator(
          color:
          theme.colorScheme.primary,
        ),
      );
    }

    if (errorMessage.isNotEmpty &&
        userData == null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      color:
      theme.colorScheme.primary,
      onRefresh:
      _refreshProfile,
      child: LayoutBuilder(
        builder: (
            BuildContext context,
            BoxConstraints constraints,
            ) {
          return SingleChildScrollView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            padding:
            const EdgeInsets.fromLTRB(
              22,
              12,
              22,
              28,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                constraints.maxHeight -
                    40,
              ),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(
                    height: 28,
                  ),
                  _buildInformationCard(),
                  const SizedBox(
                    height: 24,
                  ),
                  _buildLogoutButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    final ThemeData theme =
    Theme.of(context);

    final String profileImage =
    _readString(
      [
        'profileImage',
        'photoUrl',
        'photoURL',
      ],
    );

    final String name =
    _readString(
      [
        'fullName',
        'name',
      ],
      fallback: 'SmartQ User',
    );

    final String email =
    _readString(
      ['email'],
      fallback: 'Email unavailable',
    );

    final String phone =
    _readString(
      ['phone'],
    );

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding:
              const EdgeInsets.all(
                4,
              ),
              decoration:
              BoxDecoration(
                shape: BoxShape.circle,
                color: theme.cardColor,
                border: Border.all(
                  color: theme
                      .colorScheme
                      .primary
                      .withOpacity(
                    0.35,
                  ),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(
                      theme.brightness ==
                          Brightness.dark
                          ? 0.24
                          : 0.08,
                    ),
                    blurRadius: 16,
                    offset:
                    const Offset(
                      0,
                      6,
                    ),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 58,
                backgroundColor:
                theme
                    .colorScheme
                    .primary
                    .withOpacity(
                  0.12,
                ),
                backgroundImage:
                profileImage.isNotEmpty
                    ? NetworkImage(
                  profileImage,
                )
                    : null,
                onBackgroundImageError:
                profileImage.isNotEmpty
                    ? (
                    Object error,
                    StackTrace?
                    stackTrace,
                    ) {
                  debugPrint(
                    'Profile image error: $error',
                  );
                }
                    : null,
                child:
                profileImage.isEmpty
                    ? Icon(
                  Icons
                      .person_rounded,
                  size: 58,
                  color: theme
                      .colorScheme
                      .primary,
                )
                    : null,
              ),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Material(
                color: theme
                    .colorScheme.primary,
                shape:
                const CircleBorder(),
                child: InkWell(
                  customBorder:
                  const CircleBorder(),
                  onTap:
                  _openEditProfile,
                  child: const Padding(
                    padding:
                    EdgeInsets.all(
                      8,
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 18,
        ),
        Text(
          name,
          textAlign:
          TextAlign.center,
          style: TextStyle(
            fontSize: 22,
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
          email,
          textAlign:
          TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: theme
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
        if (phone.isNotEmpty) ...[
          const SizedBox(
            height: 5,
          ),
          Row(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                Icons.phone_outlined,
                size: 15,
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
              const SizedBox(
                width: 5,
              ),
              Text(
                phone,
                style: TextStyle(
                  fontSize: 13,
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInformationCard() {
    final ThemeData theme =
    Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius:
        BorderRadius.circular(22),
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
        children: [
          _buildMenuItem(
            icon:
            Icons.person_outline,
            title:
            'Personal Information',
            subtitle:
            'View and update your profile',
            onTap:
            _openEditProfile,
          ),
          _divider(),
          _buildMenuItem(
            icon: Icons
                .support_agent_outlined,
            title:
            'Help and Support',
            subtitle:
            'Get help using SmartQ',
            onTap:
            _showHelpDialog,
          ),
          _divider(),
          _buildMenuItem(
            icon:
            Icons.info_outline,
            title:
            'About SmartQ',
            subtitle:
            'Application information',
            onTap:
            _showAboutDialog,
          ),
          _divider(),
          _buildMenuItem(
            icon:
            Icons.history_rounded,
            title:
            'History',
            subtitle:
            'View previous tokens',
            onTap:
            _openHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed:
        isLoggingOut
            ? null
            : _logout,
        icon: isLoggingOut
            ? const SizedBox(
          width: 20,
          height: 20,
          child:
          CircularProgressIndicator(
            strokeWidth: 2.2,
            color: Colors.red,
          ),
        )
            : const Icon(
          Icons.logout_rounded,
          size: 20,
        ),
        label: Text(
          isLoggingOut
              ? 'Logging out...'
              : 'Logout',
          style:
          const TextStyle(
            fontWeight:
            FontWeight.w600,
            fontSize: 15,
          ),
        ),
        style:
        OutlinedButton.styleFrom(
          foregroundColor:
          Colors.red,
          disabledForegroundColor:
          Colors.red.shade300,
          side: BorderSide(
            color: isLoggingOut
                ? Colors.red.shade200
                : Colors.red,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final ThemeData theme =
    Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 6,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration:
        BoxDecoration(
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
          color: theme
              .colorScheme
              .primary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          color: theme
              .colorScheme
              .onSurface,
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
      trailing: Icon(
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

  Widget _buildErrorState() {
    final ThemeData theme =
    Theme.of(context);

    return RefreshIndicator(
      color:
      theme.colorScheme.primary,
      onRefresh:
      _refreshProfile,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(24),
        children: [
          const SizedBox(
            height: 120,
          ),
          Container(
            padding:
            const EdgeInsets.all(24),
            decoration:
            BoxDecoration(
              color: theme.cardColor,
              borderRadius:
              BorderRadius.circular(
                22,
              ),
              border: Border.all(
                color:
                theme.dividerColor,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons
                      .person_off_outlined,
                  size: 48,
                  color:
                  Colors.red.shade400,
                ),
                const SizedBox(
                  height: 14,
                ),
                Text(
                  'Unable to load profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                    color: theme
                        .colorScheme
                        .onSurface,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  errorMessage,
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                ElevatedButton.icon(
                  onPressed:
                  _refreshProfile,
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                  label: const Text(
                    'Try Again',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}