import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/token_provider.dart';
import '../../services/api_service.dart';
import '../../services/profile_service.dart';
import '../../services/socket_service.dart';
import '../../services/token_service.dart';
import 'active_token_screen.dart';

class TokenScreen extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;
  final String departmentId;
  final String departmentName;
  final int currentQueue;
  final String estimatedTime;

  const TokenScreen({
    super.key,
    required this.hospitalId,
    required this.hospitalName,
    required this.departmentId,
    required this.departmentName,
    required this.currentQueue,
    required this.estimatedTime,
  });

  @override
  State<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen> {
  final TokenService _tokenService = TokenService();
  final ProfileService _profileService = ProfileService();
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService.instance;

  String? tokenId;
  String? tokenNumber;
  String issuedTime = '';

  bool isTokenGenerated = false;
  bool isLoading = false;
  bool isCheckingQueue = true;

  QueueAvailability? queueAvailability;

  @override
  void initState() {
    super.initState();
    _loadQueueAvailability();
  }

  Future<void> _loadQueueAvailability({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        isCheckingQueue = true;
      });
    }

    try {
      final String departmentId = widget.departmentId.trim();

      if (departmentId.isEmpty) {
        throw Exception('Department ID is unavailable');
      }

      final Response<dynamic> response = await _apiService.dio.get(
        '/departments/$departmentId/queue',
      );

      final QueueAvailability availability =
      QueueAvailability.fromJson(
        _toMap(response.data),
      );

      if (!mounted) return;

      setState(() {
        queueAvailability = availability;
        isCheckingQueue = false;
      });
    } on DioException catch (error) {
      debugPrint('Queue availability error: $error');

      if (!mounted) return;

      setState(() {
        queueAvailability = QueueAvailability(
          canIssueToken: false,
          isOpen: false,
          status: 'Unavailable',
          message: _getDioErrorMessage(
            error,
            fallback: 'Queue information is unavailable',
          ),
        );

        isCheckingQueue = false;
      });
    } catch (error) {
      debugPrint('Queue availability error: $error');

      if (!mounted) return;

      setState(() {
        queueAvailability = QueueAvailability(
          canIssueToken: false,
          isOpen: false,
          status: 'Unavailable',
          message: _formatError(
            error,
            fallback: 'Queue information is unavailable',
          ),
        );

        isCheckingQueue = false;
      });
    }
  }

  Future<void> _generateToken() async {
    if (isLoading || isTokenGenerated || isCheckingQueue) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      final QueueAvailability latestQueue =
      await _fetchLatestQueueAvailability();

      if (!mounted) return;

      setState(() {
        queueAvailability = latestQueue;
      });

      if (!latestQueue.canIssueToken) {
        await _showQueueUnavailableDialog(
          latestQueue,
        );

        return;
      }

      final Map<String, dynamic> profile =
      await _profileService.getProfile();

      final String patientName =
          profile['name']?.toString().trim() ??
              profile['fullName']?.toString().trim() ??
              '';

      final String patientPhone =
          profile['phone']?.toString().trim() ?? '';

      if (patientName.isEmpty) {
        throw Exception(
          'Patient name is missing from your profile',
        );
      }

      if (patientPhone.isEmpty) {
        throw Exception(
          'Please add your phone number to your profile',
        );
      }

      final Map<String, dynamic> response =
      await _tokenService.createToken(
        patientName: patientName,
        patientPhone: patientPhone,
        hospital: widget.hospitalId,
        department: widget.departmentId,
      );

      final String generatedToken =
          response['tokenCode']?.toString().trim() ?? '';

      final dynamic tokenData = response['token'];

      final Map<String, dynamic> tokenMap = tokenData is Map
          ? Map<String, dynamic>.from(tokenData)
          : <String, dynamic>{};

      final String generatedTokenId =
          tokenMap['_id']?.toString().trim() ??
              tokenMap['id']?.toString().trim() ??
              '';

      final String generatedStatus =
          tokenMap['status']?.toString().trim() ?? 'Waiting';

      final int generatedCurrentQueue =
      _parseInteger(response['currentQueue']);

      final int generatedPeopleAhead =
      _parseInteger(response['peopleAhead']);

      final int generatedEstimatedMinutes =
      _parseInteger(response['estimatedMinutes']);

      final String generatedEstimatedTime =
          response['estimatedTime']?.toString().trim() ?? '--';

      final String generatedTime = _formatIssuedTime(
        tokenMap['createdAt'],
      );

      if (generatedToken.isEmpty) {
        throw Exception(
          'Token code was not returned by the server',
        );
      }

      if (generatedTokenId.isEmpty) {
        throw Exception(
          'Token ID was not returned by the server',
        );
      }

      if (!mounted) return;

      context.read<TokenProvider>().setToken(
        tokenId: generatedTokenId,
        tokenNumber: generatedToken,
        hospitalId: widget.hospitalId,
        hospitalName: widget.hospitalName,
        departmentId: widget.departmentId,
        departmentName: widget.departmentName,
        currentQueue: generatedCurrentQueue,
        peopleAhead: generatedPeopleAhead,
        estimatedMinutes: generatedEstimatedMinutes,
        estimatedTime: generatedEstimatedTime,
        issuedTime: generatedTime,
        status: generatedStatus,
      );

      _socketService.joinTokenRoom(
        generatedTokenId,
      );

      setState(() {
        tokenId = generatedTokenId;
        tokenNumber = generatedToken;
        issuedTime = generatedTime;
        isTokenGenerated = true;
      });

      await _loadQueueAvailability(
        showLoading: false,
      );

      _showMessage(
        'Token generated successfully',
      );
    } on DioException catch (error) {
      debugPrint(
        'Token generation Dio error: $error',
      );

      if (!mounted) return;

      await _handleTokenCreationDioError(
        error,
      );
    } catch (error) {
      debugPrint(
        'Token generation error: $error',
      );

      if (!mounted) return;

      _showMessage(
        _formatError(
          error,
          fallback:
          'Failed to generate token. Please try again.',
        ),
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

  Future<QueueAvailability>
  _fetchLatestQueueAvailability() async {
    final String departmentId = widget.departmentId.trim();

    if (departmentId.isEmpty) {
      throw Exception(
        'Department ID is unavailable',
      );
    }

    final Response<dynamic> response =
    await _apiService.dio.get(
      '/departments/$departmentId/queue',
    );

    return QueueAvailability.fromJson(
      _toMap(response.data),
    );
  }

  Future<void> _handleTokenCreationDioError(
      DioException error,
      ) async {
    final Map<String, dynamic> data =
    _toMap(error.response?.data);

    final String code =
        data['code']?.toString().trim().toUpperCase() ?? '';

    final String message =
        data['message']?.toString().trim() ??
            _getDioErrorMessage(
              error,
              fallback: 'Failed to generate token',
            );

    final QueueAvailability availability =
    QueueAvailability(
      canIssueToken: false,
      isOpen: false,
      status: _statusFromErrorCode(code),
      message: message,
      startAt: _readDateTime(
        data['startAt'],
      ),
      endAt: _readDateTime(
        data['endAt'],
      ),
      maximumTokens: _readNullableInteger(
        data['maximumTokens'],
      ),
      issuedTokenCount: _parseInteger(
        data['issuedTokenCount'],
      ),
      remainingTokens: _readNullableInteger(
        data['remainingTokens'],
      ),
    );

    if (mounted) {
      setState(() {
        queueAvailability = availability;
      });
    }

    switch (code) {
      case 'QUEUE_NOT_STARTED':
      case 'QUEUE_CLOSED':
      case 'QUEUE_FULL':
      case 'QUEUE_FULL_OR_CLOSED':
        await _showQueueUnavailableDialog(
          availability,
        );
        return;

      default:
        _showMessage(
          message,
          isError: true,
        );
    }
  }

  String _statusFromErrorCode(
      String code,
      ) {
    switch (code) {
      case 'QUEUE_NOT_STARTED':
        return 'Scheduled';

      case 'QUEUE_FULL':
      case 'QUEUE_FULL_OR_CLOSED':
        return 'Full';

      case 'QUEUE_CLOSED':
        return 'Closed';

      default:
        return 'Unavailable';
    }
  }

  Future<void> _showQueueUnavailableDialog(
      QueueAvailability availability,
      ) async {
    final ThemeData theme = Theme.of(context);

    final String status =
    availability.status.trim().toLowerCase();

    final bool isFull = status == 'full';
    final bool isScheduled = status == 'scheduled';

    final String title = isFull
        ? 'Queue Full'
        : isScheduled
        ? 'Queue Not Started'
        : 'Queue Closed';

    final IconData icon = isFull
        ? Icons.group_off_outlined
        : isScheduled
        ? Icons.schedule_outlined
        : Icons.lock_clock_outlined;

    final Color statusColor =
    isFull || isScheduled ? Colors.orange : Colors.red;

    await showDialog<void>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          surfaceTintColor: theme.dialogBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                icon,
                color: statusColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.departmentName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                availability.message,
                style: TextStyle(
                  color:
                  theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (availability.startAt != null ||
                  availability.endAt != null) ...[
                const SizedBox(height: 16),
                _buildDialogInfoRow(
                  label: 'Opening',
                  value: _formatDateTime(
                    availability.startAt,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDialogInfoRow(
                  label: 'Closing',
                  value: _formatDateTime(
                    availability.endAt,
                  ),
                ),
              ],
              if (availability.remainingTokens !=
                  null) ...[
                const SizedBox(height: 8),
                _buildDialogInfoRow(
                  label: 'Remaining tokens',
                  value: availability.remainingTokens
                      .toString(),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(
                  dialogContext,
                );

                await _loadQueueAvailability();
              },
              child: const Text('Refresh'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogInfoRow({
    required String label,
    required String value,
  }) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color:
              theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _openActiveTokenScreen() {
    final TokenProvider provider =
    context.read<TokenProvider>();

    final String currentTokenId =
    provider.tokenId?.trim().isNotEmpty == true
        ? provider.tokenId!.trim()
        : tokenId?.trim() ?? '';

    final String currentToken =
    provider.tokenNumber?.trim().isNotEmpty == true
        ? provider.tokenNumber!.trim()
        : tokenNumber?.trim() ?? '';

    if (currentToken.isEmpty) {
      _showMessage(
        'No active token available',
        isError: true,
      );
      return;
    }

    if (currentTokenId.isEmpty) {
      _showMessage(
        'Token ID is missing. Please generate the token again.',
        isError: true,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ActiveTokenScreen(
          tokenId: currentTokenId,
          tokenNumber: currentToken,
          hospitalName:
          provider.hospitalName ?? widget.hospitalName,
          departmentName:
          provider.departmentName ??
              widget.departmentName,
          currentQueue:
          provider.currentQueue ?? widget.currentQueue,
          estimatedTime:
          provider.estimatedTime ?? widget.estimatedTime,
          issuedTime:
          provider.issuedTime ?? issuedTime,
          status: provider.status,
        ),
      ),
    );
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

  int? _readNullableInteger(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  DateTime? _readDateTime(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  Map<String, dynamic> _toMap(
      dynamic value,
      ) {
    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return {};
  }

  String _getDioErrorMessage(
      DioException error, {
        required String fallback,
      }) {
    final Map<String, dynamic> data =
    _toMap(error.response?.data);

    final String message =
        data['message']?.toString().trim() ?? '';

    if (message.isNotEmpty) {
      return message;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond';

      case DioExceptionType.connectionError:
        return 'Unable to connect to the server';

      default:
        return fallback;
    }
  }

  String _formatError(
      dynamic error, {
        required String fallback,
      }) {
    try {
      final dynamic data = error.response?.data;

      if (data is Map && data['message'] != null) {
        final String responseMessage =
        data['message'].toString().trim();

        if (responseMessage.isNotEmpty) {
          return responseMessage;
        }
      }
    } catch (_) {
      // Use the error string below.
    }

    final String message = error
        .toString()
        .replaceFirst(
      'Exception: ',
      '',
    )
        .trim();

    return message.isEmpty ? fallback : message;
  }

  String _formatIssuedTime(
      dynamic value,
      ) {
    final DateTime? parsed = value == null
        ? null
        : DateTime.tryParse(
      value.toString(),
    )?.toLocal();

    if (parsed == null) {
      return TimeOfDay.now().format(context);
    }

    return TimeOfDay.fromDateTime(
      parsed,
    ).format(context);
  }

  String _formatDateTime(
      DateTime? value,
      ) {
    if (value == null) {
      return '--';
    }

    final DateTime local = value.toLocal();

    final String day =
    local.day.toString().padLeft(2, '0');

    final String month =
    local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year} '
        '${_formatTime(local)}';
  }

  String _formatTime(
      DateTime value,
      ) {
    int hour = value.hour;

    final String minute =
    value.minute.toString().padLeft(2, '0');

    final String period =
    hour >= 12 ? 'PM' : 'AM';

    hour %= 12;

    if (hour == 0) {
      hour = 12;
    }

    return '$hour:$minute $period';
  }

  String _formatTimeOrPlaceholder(
      DateTime? value,
      ) {
    if (value == null) {
      return '--';
    }

    return _formatTime(
      value.toLocal(),
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
          isError ? Colors.red : null,
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
        return Theme.of(context).colorScheme.primary;

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

  Color _getQueueStatusColor(
      String status,
      ) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;

      case 'scheduled':
        return Colors.orange;

      case 'full':
        return Colors.deepOrange;

      case 'closed':
      case 'cancelled':
      case 'canceled':
        return Colors.red;

      default:
        return Theme.of(context)
            .colorScheme
            .onSurfaceVariant;
    }
  }

  String _getQueueStatusText(
      QueueAvailability? availability,
      ) {
    if (isCheckingQueue) {
      return 'Checking queue...';
    }

    if (availability == null) {
      return 'Queue unavailable';
    }

    final String status =
    availability.status.trim().toLowerCase();

    switch (status) {
      case 'active':
        return availability.canIssueToken
            ? 'Queue Open'
            : 'Queue Full';

      case 'scheduled':
        return 'Queue Scheduled';

      case 'full':
        return 'Queue Full';

      case 'closed':
        return 'Queue Closed';

      case 'cancelled':
      case 'canceled':
        return 'Queue Cancelled';

      default:
        return availability.status.trim().isEmpty
            ? 'Queue unavailable'
            : availability.status;
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final ThemeData theme = Theme.of(context);

    final bool canGenerate =
        !isCheckingQueue &&
            queueAvailability?.canIssueToken == true &&
            !isLoading &&
            !isTokenGenerated;

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
          color: theme.colorScheme.onSurface,
        ),
        title: Text(
          'Queue Token',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh queue',
            onPressed: isCheckingQueue
                ? null
                : _loadQueueAvailability,
            icon: isCheckingQueue
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color:
                theme.colorScheme.primary,
              ),
            )
                : const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: _loadQueueAvailability,
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 20),
              _buildQueueStatusCard(),
              const SizedBox(height: 20),
              _buildQueueInfoCard(),
              const SizedBox(height: 20),
              _buildTokenCard(),
              const SizedBox(height: 28),
              _buildGenerateButton(
                canGenerate,
              ),
              if (isTokenGenerated) ...[
                const SizedBox(height: 14),
                _buildViewTokenButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueueStatusCard() {
    final ThemeData theme = Theme.of(context);

    final QueueAvailability? availability =
        queueAvailability;

    final String statusText =
    _getQueueStatusText(availability);

    final Color statusColor = isCheckingQueue
        ? theme.colorScheme.onSurfaceVariant
        : _getQueueStatusColor(
      availability?.status ?? 'Unavailable',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: statusColor.withOpacity(0.30),
        ),
      ),
      child: Row(
        children: [
          if (isCheckingQueue)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.3,
                color: theme.colorScheme.primary,
              ),
            )
          else
            Icon(
              availability?.canIssueToken == true
                  ? Icons.check_circle_outline
                  : Icons.schedule_outlined,
              color: statusColor,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                if (!isCheckingQueue &&
                    availability != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    availability.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(
      bool canGenerate,
      ) {
    final ThemeData theme = Theme.of(context);

    String buttonText = 'Generate Token';

    if (isLoading) {
      buttonText = 'Generating...';
    } else if (isTokenGenerated) {
      buttonText = 'Token Generated';
    } else if (isCheckingQueue) {
      buttonText = 'Checking Queue...';
    } else if (queueAvailability?.canIssueToken != true) {
      buttonText = _getQueueStatusText(
        queueAvailability,
      );
    }

    final bool showUnavailableDialog =
        !isCheckingQueue &&
            !isLoading &&
            !isTokenGenerated &&
            queueAvailability?.canIssueToken == false;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: canGenerate
            ? _generateToken
            : showUnavailableDialog
            ? () => _showQueueUnavailableDialog(
          queueAvailability!,
        )
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
          theme.colorScheme.primary,
          foregroundColor:
          theme.colorScheme.onPrimary,
          disabledBackgroundColor:
          theme.dividerColor,
          disabledForegroundColor:
          theme.colorScheme.onSurfaceVariant,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? CircularProgressIndicator(
          color: theme.colorScheme.onPrimary,
          strokeWidth: 2.5,
        )
            : Text(
          buttonText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildViewTokenButton() {
    final ThemeData theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _openActiveTokenScreen,
        icon: const Icon(
          Icons.confirmation_number_outlined,
        ),
        label: const Text(
          'View Active Token',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor:
          theme.colorScheme.primary,
          side: BorderSide(
            color: theme.colorScheme.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary
                .withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.confirmation_number_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hospitalName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.departmentName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueInfoCard() {
    final ThemeData theme = Theme.of(context);

    return Consumer<TokenProvider>(
      builder: (
          context,
          provider,
          child,
          ) {
        final int displayedQueue =
        provider.hasActiveToken
            ? provider.currentQueue ?? 0
            : queueAvailability?.currentQueue ??
            widget.currentQueue;

        final int displayedPeopleAhead =
        provider.hasActiveToken
            ? provider.peopleAhead ?? 0
            : 0;

        final String displayedEstimatedTime =
        provider.hasActiveToken
            ? provider.estimatedTime ?? '--'
            : queueAvailability?.estimatedTime ??
            widget.estimatedTime;

        return _buildCard(
          children: [
            Text(
              'Queue Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            _buildInfoRow(
              icon: Icons.people_alt_outlined,
              label: 'Current Queue',
              value: displayedQueue == 0
                  ? '--'
                  : displayedQueue.toString(),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.hourglass_bottom_outlined,
              label: 'People Ahead',
              value: displayedPeopleAhead.toString(),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.access_time_outlined,
              label: 'Estimated Waiting',
              value: displayedEstimatedTime,
            ),
            if (queueAvailability?.startAt != null ||
                queueAvailability?.endAt != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.schedule_outlined,
                label: 'Queue Period',
                value:
                '${_formatTimeOrPlaceholder(queueAvailability?.startAt)}'
                    ' - '
                    '${_formatTimeOrPlaceholder(queueAvailability?.endAt)}',
              ),
            ],
            if (queueAvailability?.remainingTokens !=
                null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                icon:
                Icons.confirmation_number_outlined,
                label: 'Remaining Tokens',
                value: queueAvailability!.remainingTokens
                    .toString(),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTokenCard() {
    final ThemeData theme = Theme.of(context);

    return Consumer<TokenProvider>(
      builder: (
          context,
          provider,
          child,
          ) {
        final String displayedToken =
        provider.hasActiveToken
            ? provider.tokenNumber ?? '--'
            : tokenNumber ?? '--';

        final String displayedStatus =
        provider.hasActiveToken
            ? provider.status
            : 'Not Generated';

        final String displayedIssuedTime =
        provider.hasActiveToken
            ? provider.issuedTime ?? '--'
            : issuedTime.isEmpty
            ? '--'
            : issuedTime;

        final String displayedHospital =
        provider.hasActiveToken &&
            provider.hospitalName
                ?.trim()
                .isNotEmpty ==
                true
            ? provider.hospitalName!
            : widget.hospitalName;

        final String displayedDepartment =
        provider.hasActiveToken &&
            provider.departmentName
                ?.trim()
                .isNotEmpty ==
                true
            ? provider.departmentName!
            : widget.departmentName;

        final bool hasToken =
            provider.hasActiveToken ||
                isTokenGenerated;

        final Color statusColor =
        _getStatusColor(
          displayedStatus,
        );

        return _buildCard(
          children: [
            Center(
              child: Text(
                'Your Token',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary
                      .withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        displayedToken,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color:
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: AnimatedContainer(
                duration:
                const Duration(milliseconds: 250),
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: hasToken
                      ? statusColor.withOpacity(0.12)
                      : theme.dividerColor,
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: Text(
                  displayedStatus,
                  style: TextStyle(
                    color: hasToken
                        ? statusColor
                        : theme.colorScheme
                        .onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Divider(
              height: 32,
              color: theme.dividerColor,
            ),
            _buildInfoRow(
              icon: Icons.local_hospital_outlined,
              label: 'Hospital',
              value: displayedHospital,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon:
              Icons.medical_services_outlined,
              label: 'Department',
              value: displayedDepartment,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.schedule_outlined,
              label: 'Issued Time',
              value: displayedIssuedTime,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard({
    required List<Widget> children,
  }) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.dividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark
                  ? 0.18
                  : 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color:
              theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class QueueAvailability {
  final bool canIssueToken;
  final bool isOpen;
  final String status;
  final String message;

  final String queueSessionId;

  final DateTime? startAt;
  final DateTime? endAt;

  final int? maximumTokens;
  final int issuedTokenCount;
  final int? remainingTokens;

  final int currentQueue;
  final String estimatedTime;

  const QueueAvailability({
    required this.canIssueToken,
    required this.isOpen,
    required this.status,
    required this.message,
    this.queueSessionId = '',
    this.startAt,
    this.endAt,
    this.maximumTokens,
    this.issuedTokenCount = 0,
    this.remainingTokens,
    this.currentQueue = 0,
    this.estimatedTime = 'N/A',
  });

  factory QueueAvailability.fromJson(
      Map<String, dynamic> json,
      ) {
    return QueueAvailability(
      canIssueToken: _readBoolean(
        json['canIssueToken'],
      ),
      isOpen: _readBoolean(
        json['isOpen'],
      ),
      status:
      json['status']?.toString().trim() ??
          'Unavailable',
      message:
      json['message']?.toString().trim() ??
          'Queue information is unavailable',
      queueSessionId: json['queueSessionId']
          ?.toString()
          .trim() ??
          '',
      startAt: _readDateTime(
        json['startAt'],
      ),
      endAt: _readDateTime(
        json['endAt'],
      ),
      maximumTokens: _readNullableInteger(
        json['maximumTokens'],
      ),
      issuedTokenCount: _readInteger(
        json['issuedTokenCount'],
      ),
      remainingTokens: _readNullableInteger(
        json['remainingTokens'],
      ),
      currentQueue: _readInteger(
        json['currentQueue'],
      ),
      estimatedTime: json['estimatedTime']
          ?.toString()
          .trim() ??
          'N/A',
    );
  }

  static bool _readBoolean(
      dynamic value,
      ) {
    if (value is bool) {
      return value;
    }

    return value
        ?.toString()
        .toLowerCase() ==
        'true';
  }

  static int _readInteger(
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

  static int? _readNullableInteger(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static DateTime? _readDateTime(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}