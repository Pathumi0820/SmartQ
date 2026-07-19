import 'package:flutter/material.dart';

import '../../services/profile_service.dart';
import '../../services/token_service.dart';

class TokenHistoryScreen extends StatefulWidget {
  const TokenHistoryScreen({
    super.key,
  });

  @override
  State<TokenHistoryScreen> createState() =>
      _TokenHistoryScreenState();
}

class _TokenHistoryScreenState
    extends State<TokenHistoryScreen> {
  final TokenService _tokenService =
  TokenService();

  final ProfileService _profileService =
  ProfileService();

  List<Map<String, dynamic>> tokens = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    _loadTokenHistory();
  }

  Future<void> _loadTokenHistory() async {
    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final Map<String, dynamic> profile =
      await _profileService.getProfile();

      final String patientPhone =
          profile['phone']?.toString().trim() ?? '';

      if (patientPhone.isEmpty) {
        throw Exception(
          'Please add your phone number to your profile',
        );
      }

      final List<dynamic> response =
      await _tokenService.getTokensByPhone(
        patientPhone,
      );

      final List<Map<String, dynamic>>
      loadedTokens = response
          .whereType<Map>()
          .map(
            (Map<dynamic, dynamic> item) =>
        Map<String, dynamic>.from(
          item,
        ),
      )
          .toList();

      loadedTokens.sort(
            (
            Map<String, dynamic> first,
            Map<String, dynamic> second,
            ) {
          final DateTime? firstDate =
          _parseCreatedAt(
            first['createdAt'],
          );

          final DateTime? secondDate =
          _parseCreatedAt(
            second['createdAt'],
          );

          if (firstDate == null &&
              secondDate == null) {
            return 0;
          }

          if (firstDate == null) {
            return 1;
          }

          if (secondDate == null) {
            return -1;
          }

          return secondDate.compareTo(
            firstDate,
          );
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        tokens = loadedTokens;
      });
    } catch (error) {
      debugPrint(
        'Token history error: $error',
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

      if (message.contains('404')) {
        message =
        'Your profile was not found. Please log out and log in again.';
      } else if (message.contains('401')) {
        message =
        'Your login session has expired. Please log in again.';
      } else if (message.isEmpty) {
        message =
        'Failed to load token history';
      }

      setState(() {
        errorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  DateTime? _parseCreatedAt(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value.toLocal();
    }

    return DateTime.tryParse(
      value.toString(),
    )?.toLocal();
  }

  String _formatDate(
      DateTime? dateTime,
      ) {
    if (dateTime == null) {
      return '--';
    }

    final String year =
    dateTime.year.toString();

    final String month =
    dateTime.month
        .toString()
        .padLeft(
      2,
      '0',
    );

    final String day =
    dateTime.day
        .toString()
        .padLeft(
      2,
      '0',
    );

    return '$year-$month-$day';
  }

  String _formatTime(
      DateTime? dateTime,
      ) {
    if (dateTime == null) {
      return '--';
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

  String _readName(
      dynamic value,
      ) {
    if (value is Map) {
      final String name =
          value['name']?.toString().trim() ??
              '';

      return name.isEmpty
          ? '--'
          : name;
    }

    final String text =
        value?.toString().trim() ?? '';

    return text.isEmpty
        ? '--'
        : text;
  }

  String _readTokenCode(
      Map<String, dynamic> token,
      ) {
    final String tokenCode =
        token['tokenCode']
            ?.toString()
            .trim() ??
            '';

    if (tokenCode.isNotEmpty) {
      return tokenCode;
    }

    final String prefix =
        token['prefix']
            ?.toString()
            .trim() ??
            '';

    final int tokenNumber =
    _parseInteger(
      token['tokenNumber'],
    );

    if (prefix.isNotEmpty &&
        tokenNumber > 0) {
      return '$prefix${tokenNumber.toString().padLeft(3, '0')}';
    }

    return '--';
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
      value?.toString().trim() ?? '',
    ) ??
        0;
  }

  String _readStatus(
      dynamic value,
      ) {
    final String status =
        value?.toString().trim() ?? '';

    return status.isEmpty
        ? 'Waiting'
        : status;
  }

  Color _getStatusColor(
      String status,
      ) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return Colors.orange;

      case 'called':
        return Theme.of(context)
            .colorScheme
            .primary;

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

  IconData _getStatusIcon(
      String status,
      ) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return Icons.hourglass_top_rounded;

      case 'called':
        return Icons.notifications_active_rounded;

      case 'serving':
        return Icons.medical_services_rounded;

      case 'completed':
        return Icons.check_circle_rounded;

      case 'cancelled':
      case 'canceled':
        return Icons.cancel_rounded;

      default:
        return Icons.info_outline_rounded;
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
          'Token History',
          style: TextStyle(
            color:
            theme.colorScheme.onSurface,
            fontSize: 22,
            fontWeight:
            FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh history',
            onPressed:
            isLoading
                ? null
                : _loadTokenHistory,
            icon: isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child:
              CircularProgressIndicator(
                strokeWidth: 2.2,
                color: theme
                    .colorScheme
                    .primary,
              ),
            )
                : const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(
            width: 6,
          ),
        ],
      ),
      body: RefreshIndicator(
        color:
        theme.colorScheme.primary,
        onRefresh:
        _loadTokenHistory,
        child:
        _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final ThemeData theme =
    Theme.of(context);

    if (isLoading) {
      return ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
            MediaQuery.of(context)
                .size
                .height *
                0.68,
            child: Center(
              child:
              CircularProgressIndicator(
                color: theme
                    .colorScheme
                    .primary,
              ),
            ),
          ),
        ],
      );
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (tokens.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      keyboardDismissBehavior:
      ScrollViewKeyboardDismissBehavior
          .onDrag,
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding:
      const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        28,
      ),
      itemCount:
      tokens.length,
      itemBuilder: (
          BuildContext context,
          int index,
          ) {
        final Map<String, dynamic> token =
        tokens[index];

        final DateTime? createdAt =
        _parseCreatedAt(
          token['createdAt'],
        );

        return _buildHistoryCard(
          tokenNumber:
          _readTokenCode(
            token,
          ),
          hospitalName:
          _readName(
            token['hospital'],
          ),
          departmentName:
          _readName(
            token['department'],
          ),
          date:
          _formatDate(
            createdAt,
          ),
          time:
          _formatTime(
            createdAt,
          ),
          status:
          _readStatus(
            token['status'],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    final ThemeData theme =
    Theme.of(context);

    final bool isDark =
        theme.brightness ==
            Brightness.dark;

    final Color backgroundColor =
    isDark
        ? Colors.red.withOpacity(
      0.12,
    )
        : Colors.red.shade50;

    final Color borderColor =
    isDark
        ? Colors.red.withOpacity(
      0.28,
    )
        : Colors.red.shade100;

    final Color messageColor =
    isDark
        ? Colors.red.shade200
        : Colors.red.shade700;

    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding:
      const EdgeInsets.all(
        20,
      ),
      children: [
        SizedBox(
          height:
          MediaQuery.of(context)
              .size
              .height *
              0.58,
          child: Center(
            child: Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(
                24,
              ),
              decoration:
              BoxDecoration(
                color:
                backgroundColor,
                borderRadius:
                BorderRadius.circular(
                  22,
                ),
                border: Border.all(
                  color:
                  borderColor,
                ),
              ),
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  Icon(
                    Icons
                        .error_outline_rounded,
                    size: 54,
                    color:
                    messageColor,
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  Text(
                    'Unable to load history',
                    textAlign:
                    TextAlign.center,
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
                    errorMessage!,
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                      messageColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  ElevatedButton.icon(
                    onPressed:
                    _loadTokenHistory,
                    icon: const Icon(
                      Icons
                          .refresh_rounded,
                    ),
                    label:
                    const Text(
                      'Retry',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final ThemeData theme =
    Theme.of(context);

    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding:
      const EdgeInsets.all(
        20,
      ),
      children: [
        SizedBox(
          height:
          MediaQuery.of(context)
              .size
              .height *
              0.58,
          child: Center(
            child: Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(
                26,
              ),
              decoration:
              BoxDecoration(
                color:
                theme.cardColor,
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
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
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
                    child: Icon(
                      Icons
                          .history_rounded,
                      size: 38,
                      color: theme
                          .colorScheme
                          .primary,
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    'No token history available',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
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
                    'Your completed and cancelled tokens will appear here.',
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
                    height: 14,
                  ),
                  TextButton.icon(
                    onPressed:
                    _loadTokenHistory,
                    icon: const Icon(
                      Icons
                          .refresh_rounded,
                    ),
                    label:
                    const Text(
                      'Refresh',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard({
    required String tokenNumber,
    required String hospitalName,
    required String departmentName,
    required String date,
    required String time,
    required String status,
  }) {
    final ThemeData theme =
    Theme.of(context);

    final Color statusColor =
    _getStatusColor(
      status,
    );

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 16,
      ),
      padding:
      const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color:
        theme.cardColor,
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
            blurRadius: 10,
            offset:
            const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            padding:
            const EdgeInsets.all(
              6,
            ),
            decoration:
            BoxDecoration(
              color: theme
                  .colorScheme
                  .primary
                  .withOpacity(
                0.12,
              ),
              borderRadius:
              BorderRadius.circular(
                18,
              ),
            ),
            child: Center(
              child: FittedBox(
                fit:
                BoxFit.scaleDown,
                child: Text(
                  tokenNumber,
                  style: TextStyle(
                    color: theme
                        .colorScheme
                        .primary,
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 14,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  hospitalName,
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
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
                  height: 6,
                ),
                Text(
                  departmentName,
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildDateItem(
                      icon: Icons
                          .calendar_today_outlined,
                      value: date,
                    ),
                    _buildDateItem(
                      icon: Icons
                          .access_time_outlined,
                      value: time,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration:
                  BoxDecoration(
                    color: statusColor
                        .withOpacity(
                      0.12,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Row(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(
                          status,
                        ),
                        size: 14,
                        color:
                        statusColor,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                          FontWeight.w700,
                          color:
                          statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateItem({
    required IconData icon,
    required String value,
  }) {
    final ThemeData theme =
    Theme.of(context);

    return Row(
      mainAxisSize:
      MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme
              .colorScheme
              .onSurfaceVariant,
        ),
        const SizedBox(
          width: 5,
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: theme
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}