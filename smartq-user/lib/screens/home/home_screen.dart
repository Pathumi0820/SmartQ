import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/token_provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/token_service.dart';
import '../../utils/app_colors.dart';
import '../hospital/hospital_list_screen.dart';
import '../profile/profile_screen.dart';
import '../token/active_token_screen.dart';
import '../token/token_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final TokenService _tokenService = TokenService();
  final ApiService _apiService = ApiService();

  int _currentIndex = 0;

  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> hospitals = [];

  bool isLoadingUser = true;
  bool isLoadingHospitals = true;
  bool isOpeningToken = false;

  String hospitalErrorMessage = '';

  final List<Map<String, dynamic>> quickActions = [
    {
      'title': 'Get Token',
      'icon': Icons.confirmation_number_outlined,
    },
    {
      'title': 'My Token',
      'icon': Icons.qr_code_2_outlined,
    },
    {
      'title': 'Hospitals',
      'icon': Icons.local_hospital_outlined,
    },
    {
      'title': 'History',
      'icon': Icons.history,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadUser(),
      _loadHospitals(),
    ]);
  }

  Future<void> _refreshHome() async {
    await Future.wait([
      _loadUser(
        showLoading: false,
      ),
      _loadHospitals(
        showLoading: false,
      ),
    ]);
  }

  Future<void> _loadUser({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        isLoadingUser = true;
      });
    }

    try {
      final Map<String, dynamic>? data =
      await _authService.getUserData();

      if (!mounted) return;

      setState(() {
        userData = data;
        isLoadingUser = false;
      });
    } catch (error) {
      debugPrint(
        'User loading error: $error',
      );

      if (!mounted) return;

      setState(() {
        isLoadingUser = false;
      });
    }
  }

  Future<void> _loadHospitals({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        isLoadingHospitals = true;
        hospitalErrorMessage = '';
      });
    }

    try {
      final response =
      await _apiService.dio.get(
        '/hospitals',
      );

      final List<dynamic> hospitalData =
      _extractList(
        response.data,
        propertyName: 'hospitals',
      );

      final List<Map<String, dynamic>> loadedHospitals =
      await Future.wait(
        hospitalData.map(
              (dynamic item) async {
            final Map<String, dynamic> hospital =
            Map<String, dynamic>.from(
              item as Map,
            );

            final String hospitalId =
                hospital['_id']
                    ?.toString()
                    .trim() ??
                    hospital['id']
                        ?.toString()
                        .trim() ??
                    '';

            int departmentCount =
            _parseInteger(
              hospital['departmentCount'],
            );

            if (hospitalId.isNotEmpty &&
                !hospital.containsKey(
                  'departmentCount',
                )) {
              departmentCount =
              await _loadDepartmentCount(
                hospitalId,
              );
            }

            return {
              ...hospital,
              'departmentCount':
              departmentCount,
            };
          },
        ),
      );

      loadedHospitals.sort(
            (
            Map<String, dynamic> first,
            Map<String, dynamic> second,
            ) {
          final String firstName =
              first['name']
                  ?.toString()
                  .toLowerCase() ??
                  '';

          final String secondName =
              second['name']
                  ?.toString()
                  .toLowerCase() ??
                  '';

          return firstName.compareTo(
            secondName,
          );
        },
      );

      if (!mounted) return;

      setState(() {
        hospitals = loadedHospitals;
        isLoadingHospitals = false;
        hospitalErrorMessage = '';
      });
    } catch (error) {
      debugPrint(
        'Hospital loading error: $error',
      );

      if (!mounted) return;

      setState(() {
        hospitals = [];
        isLoadingHospitals = false;
        hospitalErrorMessage =
            _extractErrorMessage(
              error,
              fallback:
              'Failed to load hospitals',
            );
      });
    }
  }

  Future<int> _loadDepartmentCount(
      String hospitalId,
      ) async {
    try {
      final response =
      await _apiService.dio.get(
        '/departments/$hospitalId',
      );

      final List<dynamic> departmentData =
      _extractList(
        response.data,
        propertyName: 'departments',
      );

      return departmentData.length;
    } catch (error) {
      debugPrint(
        'Department count loading error '
            'for hospital $hospitalId: $error',
      );

      return 0;
    }
  }

  List<dynamic> _extractList(
      dynamic value, {
        required String propertyName,
      }) {
    if (value is List) {
      return value;
    }

    if (value is Map &&
        value[propertyName] is List) {
      return List<dynamic>.from(
        value[propertyName] as List,
      );
    }

    return [];
  }

  int _parseInteger(
      dynamic value,
      ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  String _extractErrorMessage(
      dynamic error, {
        required String fallback,
      }) {
    try {
      final dynamic responseData =
          error.response?.data;

      if (responseData is Map &&
          responseData['message'] != null) {
        final String message =
        responseData['message']
            .toString()
            .trim();

        if (message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Use fallback.
    }

    return fallback;
  }

  void _openHospitalList(
      BuildContext context,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const HospitalListScreen(),
      ),
    );
  }

  void _openHospitalSearch(
      BuildContext context,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const HospitalListScreen(
          autofocusSearch: true,
        ),
      ),
    );
  }

  void _openTokenHistory(
      BuildContext context,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const TokenHistoryScreen(),
      ),
    );
  }

  Future<void> _openMyToken(
      BuildContext context,
      ) async {
    if (isOpeningToken) return;

    final TokenProvider tokenProvider =
    context.read<TokenProvider>();

    if (!tokenProvider.hasActiveToken) {
      _showMessage(
        'No active token available',
      );

      return;
    }

    setState(() {
      isOpeningToken = true;
    });

    try {
      final Map<String, dynamic>? activeToken =
      await _tokenService.getActiveToken();

      if (!mounted) return;

      if (activeToken == null) {
        tokenProvider.clearToken();

        _showMessage(
          'No active token found',
        );

        return;
      }

      final String tokenId =
          activeToken['id']
              ?.toString()
              .trim() ??
              activeToken['_id']
                  ?.toString()
                  .trim() ??
              '';

      final String tokenNumber =
          activeToken['tokenCode']
              ?.toString()
              .trim() ??
              tokenProvider.tokenNumber ??
              '';

      final String hospitalName =
          activeToken['hospitalName']
              ?.toString()
              .trim() ??
              tokenProvider.hospitalName ??
              '';

      final String departmentName =
          activeToken['departmentName']
              ?.toString()
              .trim() ??
              tokenProvider.departmentName ??
              '';

      final String status =
          activeToken['status']
              ?.toString()
              .trim() ??
              tokenProvider.status;

      final String issuedTime =
      _formatIssuedTime(
        activeToken['createdAt'],
        fallback:
        tokenProvider.issuedTime ??
            '--',
      );

      if (tokenId.isEmpty) {
        throw Exception(
          'MongoDB token ID was not returned by the server',
        );
      }

      if (tokenNumber.isEmpty) {
        throw Exception(
          'Token number was not returned by the server',
        );
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ActiveTokenScreen(
                tokenId: tokenId,
                tokenNumber: tokenNumber,
                hospitalName: hospitalName,
                departmentName:
                departmentName,
                currentQueue:
                tokenProvider.currentQueue ??
                    0,
                estimatedTime:
                tokenProvider.estimatedTime ??
                    '--',
                issuedTime: issuedTime,
                status: status.isEmpty
                    ? 'Waiting'
                    : status,
              ),
        ),
      );
    } catch (error) {
      debugPrint(
        'Open active token error: $error',
      );

      if (!mounted) return;

      final String message = error
          .toString()
          .replaceFirst(
        'Exception: ',
        '',
      )
          .trim();

      _showMessage(
        message.isEmpty
            ? 'Failed to load active token'
            : message,
      );
    } finally {
      if (mounted) {
        setState(() {
          isOpeningToken = false;
        });
      }
    }
  }

  String _formatIssuedTime(
      dynamic value, {
        required String fallback,
      }) {
    if (value == null) {
      return fallback;
    }

    final DateTime? dateTime =
    DateTime.tryParse(
      value.toString(),
    )?.toLocal();

    if (dateTime == null) {
      return fallback;
    }

    int hour = dateTime.hour;

    final String minute =
    dateTime.minute
        .toString()
        .padLeft(
      2,
      '0',
    );

    final String period =
    hour >= 12 ? 'PM' : 'AM';

    hour %= 12;

    if (hour == 0) {
      hour = 12;
    }

    return '$hour:$minute $period';
  }

  void _handleBottomNavTap(
      int index,
      ) {
    if (index == 0) {
      setState(() {
        _currentIndex = 0;
      });

      return;
    }

    if (index == 1) {
      _openMyToken(context);
      return;
    }

    if (index == 2) {
      _openTokenHistory(context);
      return;
    }

    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const ProfileScreen(),
        ),
      );
    }
  }

  void _showMessage(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Color _getStatusColor(
      String status,
      ) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return Colors.orange;

      case 'called':
        return AppColors.primaryBlue;

      case 'serving':
        return Colors.purple;

      case 'completed':
        return Colors.green;

      case 'cancelled':
      case 'canceled':
        return Colors.red;

      default:
        return Theme.of(context)
            .colorScheme
            .onSurfaceVariant;
    }
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
        child: isLoadingUser
            ? Center(
          child:
          CircularProgressIndicator(
            color:
            theme.colorScheme.primary,
          ),
        )
            : RefreshIndicator(
          color:
          theme.colorScheme.primary,
          onRefresh: _refreshHome,
          child:
          SingleChildScrollView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                _buildTopBar(),
                const SizedBox(
                  height: 24,
                ),
                _buildGreetingCard(),
                const SizedBox(
                  height: 20,
                ),
                _buildSearchBar(),
                const SizedBox(
                  height: 24,
                ),
                Text(
                  'Quick Actions',
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
                  height: 14,
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics:
                  const NeverScrollableScrollPhysics(),
                  itemCount:
                  quickActions.length,
                  gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                     crossAxisSpacing: 14,
                     mainAxisSpacing: 14,
                     mainAxisExtent: 145,
                ),
                  itemBuilder: (
                      context,
                      index,
                      ) {
                    final Map<String,
                        dynamic> item =
                    quickActions[index];

                    return _buildQuickActionCard(
                      context: context,
                      title:
                      item['title']
                          .toString(),
                      icon:
                      item['icon']
                      as IconData,
                    );
                  },
                ),
                const SizedBox(
                  height: 24,
                ),
                _buildHospitalHeader(),
                const SizedBox(
                  height: 8,
                ),
                _buildHospitalSection(),
                const SizedBox(
                  height: 24,
                ),
                _buildActiveTokenCard(
                  context,
                ),
                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:
      _buildBottomNavBar(),
    );
  }

  Widget _buildHospitalHeader() {
    final ThemeData theme =
    Theme.of(context);

    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Available Hospitals',
          style: TextStyle(
            fontSize: 18,
            fontWeight:
            FontWeight.bold,
            color: theme
                .colorScheme.onSurface,
          ),
        ),
        TextButton(
          onPressed: () =>
              _openHospitalList(
                context,
              ),
          child: Text(
            'See All',
            style: TextStyle(
              color:
              theme.colorScheme.primary,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHospitalSection() {
    final ThemeData theme =
    Theme.of(context);

    if (isLoadingHospitals) {
      return Padding(
        padding:
        const EdgeInsets.symmetric(
          vertical: 28,
        ),
        child: Center(
          child:
          CircularProgressIndicator(
            color:
            theme.colorScheme.primary,
          ),
        ),
      );
    }

    if (hospitalErrorMessage.isNotEmpty) {
      return _buildHospitalError();
    }

    if (hospitals.isEmpty) {
      return _buildEmptyHospitals();
    }

    final List<Map<String, dynamic>>
    visibleHospitals =
    hospitals.take(3).toList();

    return ListView.builder(
      itemCount:
      visibleHospitals.length,
      shrinkWrap: true,
      physics:
      const NeverScrollableScrollPhysics(),
      itemBuilder: (
          context,
          index,
          ) {
        final Map<String, dynamic> hospital =
        visibleHospitals[index];

        final String name =
            hospital['name']
                ?.toString()
                .trim() ??
                'Unnamed Hospital';

        final String location =
            hospital['city']
                ?.toString()
                .trim() ??
                hospital['location']
                    ?.toString()
                    .trim() ??
                '';

        final int departmentCount =
        _parseInteger(
          hospital['departmentCount'],
        );

        return _buildHospitalCard(
          context: context,
          name: name,
          location:
          location.isEmpty
              ? 'Location unavailable'
              : location,
          departments:
          departmentCount,
        );
      },
    );
  }

  Widget _buildHospitalError() {
    final ThemeData theme =
    Theme.of(context);

    final bool isDark =
        theme.brightness ==
            Brightness.dark;

    final Color background =
    isDark
        ? Colors.red.withOpacity(
      0.12,
    )
        : Colors.red.shade50;

    final Color border =
    isDark
        ? Colors.red.withOpacity(
      0.30,
    )
        : Colors.red.shade100;

    final Color textColor =
    isDark
        ? Colors.red.shade200
        : Colors.red.shade700;

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons
                .error_outline_rounded,
            color: textColor,
            size: 34,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            hospitalErrorMessage,
            textAlign:
            TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          TextButton.icon(
            onPressed:
            _loadHospitals,
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              'Try Again',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHospitals() {
    final ThemeData theme =
    Theme.of(context);

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        24,
      ),
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
      ),
      child: Column(
        children: [
          Icon(
            Icons
                .local_hospital_outlined,
            size: 38,
            color: theme
                .colorScheme
                .onSurfaceVariant,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            'No hospitals available',
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
            height: 5,
          ),
          Text(
            'Hospitals added by the administrator will appear here.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final ThemeData theme =
    Theme.of(context);

    final String name =
        userData?['fullName']
            ?.toString()
            .trim() ??
            userData?['name']
                ?.toString()
                .trim() ??
            'User';

    final String image =
        userData?['profileImage']
            ?.toString()
            .trim() ??
            userData?['photoUrl']
                ?.toString()
                .trim() ??
            '';

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor:
          theme.colorScheme.primary
              .withOpacity(
            0.12,
          ),
          backgroundImage:
          image.isNotEmpty
              ? NetworkImage(image)
              : null,
          child: image.isEmpty
              ? Icon(
            Icons.person,
            color: theme
                .colorScheme
                .primary,
            size: 28,
          )
              : null,
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
                'Hello, $name 👋',
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
                height: 2,
              ),
              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 14,
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius:
            BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color:
              theme.dividerColor,
            ),
          ),
          child: IconButton(
            onPressed: () {},
            color: theme
                .colorScheme
                .onSurface,
            icon: const Icon(
              Icons
                  .notifications_none_rounded,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        20,
      ),
      decoration: BoxDecoration(
        color:
        AppColors.primaryBlue,
        borderRadius:
        BorderRadius.circular(
          24,
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Book your hospital queue easily',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight:
                    FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  'Get your token, check queue status, and save your time.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 12,
          ),
          Icon(
            Icons
                .local_hospital_rounded,
            color: Colors.white,
            size: 42,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final ThemeData theme =
    Theme.of(context);

    return TextField(
      readOnly: true,
      showCursor: false,
      enableInteractiveSelection:
      false,
      onTap: () =>
          _openHospitalSearch(
            context,
          ),
      decoration: InputDecoration(
        hintText:
        'Search hospitals...',
        hintStyle: TextStyle(
          color: theme
              .colorScheme
              .onSurfaceVariant,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: theme
              .colorScheme
              .onSurfaceVariant,
        ),
        suffixIcon: Icon(
          Icons
              .arrow_forward_ios_rounded,
          color: theme
              .colorScheme
              .onSurfaceVariant,
          size: 16,
        ),
        filled: true,
        fillColor: theme.cardColor,
        contentPadding:
        const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 14,
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          borderSide: BorderSide(
            color:
            theme.dividerColor,
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          borderSide: BorderSide(
            color: theme
                .colorScheme.primary,
            width: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
  }) {
    final ThemeData theme =
    Theme.of(context);

    return InkWell(
      onTap: isOpeningToken
          ? null
          : () {
        if (title ==
            'Hospitals' ||
            title ==
                'Get Token') {
          _openHospitalList(
            context,
          );
        } else if (title ==
            'History') {
          _openTokenHistory(
            context,
          );
        } else if (title ==
            'My Token') {
          _openMyToken(
            context,
          );
        }
      },
      borderRadius:
      BorderRadius.circular(
        20,
      ),
      child: Container(
        padding:
        const EdgeInsets.all(
          18,
        ),
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
                    : 0.04,
              ),
              blurRadius: 10,
              offset:
              const Offset(
                0,
                4,
              ),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              padding:
              const EdgeInsets.all(
                12,
              ),
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
              child:
              isOpeningToken &&
                  title ==
                      'My Token'
                  ? SizedBox(
                width: 28,
                height: 28,
                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2.5,
                  color: theme
                      .colorScheme
                      .primary,
                ),
              )
                  : Icon(
                icon,
                color: theme
                    .colorScheme
                    .primary,
                size: 28,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalCard({
    required BuildContext context,
    required String name,
    required String location,
    required int departments,
  }) {
    final ThemeData theme =
    Theme.of(context);

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      child: Material(
        color: theme.cardColor,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        child: InkWell(
          onTap: () =>
              _openHospitalList(
                context,
              ),
          borderRadius:
          BorderRadius.circular(
            20,
          ),
          child: Padding(
            padding:
            const EdgeInsets.all(
              18,
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration:
                  BoxDecoration(
                    color: theme
                        .colorScheme
                        .primary
                        .withOpacity(
                      0.12,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      16,
                    ),
                  ),
                  child: Icon(
                    Icons.local_hospital,
                    color: theme
                        .colorScheme
                        .primary,
                    size: 28,
                  ),
                ),
                const SizedBox(
                  width: 14,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight
                              .bold,
                          color: theme
                              .colorScheme
                              .onSurface,
                        ),
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        location,
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        departments == 1
                            ? '1 Department'
                            : '$departments Departments',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme
                              .colorScheme
                              .primary,
                          fontWeight:
                          FontWeight
                              .w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  size: 16,
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTokenCard(
      BuildContext context,
      ) {
    final ThemeData theme =
    Theme.of(context);

    return Consumer<TokenProvider>(
      builder: (
          context,
          tokenProvider,
          child,
          ) {
        final Color statusColor =
        _getStatusColor(
          tokenProvider.status,
        );

        return Container(
          width: double.infinity,
          padding:
          const EdgeInsets.all(
            18,
          ),
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
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'My Token',
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
                height: 12,
              ),
              if (!tokenProvider
                  .hasActiveToken)
                Row(
                  children: [
                    Icon(
                      Icons
                          .confirmation_number_outlined,
                      color: theme
                          .colorScheme
                          .primary,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      'No active token yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration:
                          BoxDecoration(
                            color: theme
                                .colorScheme
                                .primary
                                .withOpacity(
                              0.12,
                            ),
                            shape:
                            BoxShape.circle,
                          ),
                          child: Center(
                            child:
                            FittedBox(
                              fit: BoxFit
                                  .scaleDown,
                              child:
                              Padding(
                                padding:
                                const EdgeInsets
                                    .all(
                                  6,
                                ),
                                child:
                                Text(
                                  tokenProvider
                                      .tokenNumber ??
                                      '--',
                                  style:
                                  TextStyle(
                                    color: theme
                                        .colorScheme
                                        .primary,
                                    fontSize:
                                    16,
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Text(
                                tokenProvider
                                    .departmentName ??
                                    '--',
                                style:
                                TextStyle(
                                  fontSize:
                                  15,
                                  fontWeight:
                                  FontWeight
                                      .bold,
                                  color: theme
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                tokenProvider
                                    .hospitalName ??
                                    '--',
                                style:
                                TextStyle(
                                  fontSize:
                                  13,
                                  color: theme
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                'Status: ${tokenProvider.status}',
                                style:
                                TextStyle(
                                  fontSize:
                                  13,
                                  color:
                                  statusColor,
                                  fontWeight:
                                  FontWeight
                                      .w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    SizedBox(
                      width:
                      double.infinity,
                      height: 46,
                      child:
                      ElevatedButton(
                        onPressed:
                        isOpeningToken
                            ? null
                            : () =>
                            _openMyToken(
                              context,
                            ),
                        child:
                        isOpeningToken
                            ? const SizedBox(
                          width:
                          22,
                          height:
                          22,
                          child:
                          CircularProgressIndicator(
                            color:
                            Colors.white,
                            strokeWidth:
                            2.4,
                          ),
                        )
                            : const Text(
                          'View My Token',
                          style:
                          TextStyle(
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    final ThemeData theme =
    Theme.of(context);

    return BottomNavigationBar(
      currentIndex:
      _currentIndex,
      onTap: isOpeningToken
          ? null
          : _handleBottomNavTap,
      type:
      BottomNavigationBarType.fixed,
      backgroundColor: theme
          .bottomNavigationBarTheme
          .backgroundColor ??
          theme.cardColor,
      selectedItemColor: theme
          .bottomNavigationBarTheme
          .selectedItemColor ??
          theme.colorScheme.primary,
      unselectedItemColor: theme
          .bottomNavigationBarTheme
          .unselectedItemColor ??
          theme.colorScheme
              .onSurfaceVariant,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.home_outlined,
          ),
          activeIcon:
          Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons
                .confirmation_number_outlined,
          ),
          activeIcon: Icon(
            Icons.confirmation_number,
          ),
          label: 'Token',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.history_outlined,
          ),
          activeIcon:
          Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.person_outline,
          ),
          activeIcon:
          Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}