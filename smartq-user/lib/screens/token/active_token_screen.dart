import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/token_provider.dart';
import '../../services/token_service.dart';
import 'qr_screen.dart';

class ActiveTokenScreen extends StatefulWidget {
  final String tokenId;
  final String tokenNumber;
  final String hospitalName;
  final String departmentName;
  final int currentQueue;
  final String estimatedTime;
  final String issuedTime;
  final String status;

  const ActiveTokenScreen({
    super.key,
    required this.tokenId,
    required this.tokenNumber,
    required this.hospitalName,
    required this.departmentName,
    required this.currentQueue,
    required this.estimatedTime,
    required this.issuedTime,
    this.status = 'Waiting',
  });

  @override
  State<ActiveTokenScreen> createState() =>
      _ActiveTokenScreenState();
}

class _ActiveTokenScreenState
    extends State<ActiveTokenScreen> {
  final TokenService _tokenService =
  TokenService();

  bool _isCancelling = false;

  bool _isCurrentProviderToken(
      TokenProvider provider,
      ) {
    final String providerTokenId =
        provider.tokenId?.trim() ?? '';

    final String screenTokenId =
    widget.tokenId.trim();

    if (providerTokenId.isEmpty ||
        screenTokenId.isEmpty) {
      return false;
    }

    return providerTokenId ==
        screenTokenId;
  }

  String _displayedTokenId(
      TokenProvider provider,
      ) {
    if (_isCurrentProviderToken(
      provider,
    )) {
      final String value =
          provider.tokenId?.trim() ?? '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    return widget.tokenId.trim();
  }

  String _displayedTokenNumber(
      TokenProvider provider,
      ) {
    if (_isCurrentProviderToken(
      provider,
    )) {
      final String value =
          provider.tokenNumber?.trim() ??
              '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    final String fallback =
    widget.tokenNumber.trim();

    return fallback.isEmpty
        ? '--'
        : fallback;
  }

  String _displayedStatus(
      TokenProvider provider,
      ) {
    if (_isCurrentProviderToken(
      provider,
    )) {
      final String value =
      provider.status.trim();

      if (value.isNotEmpty) {
        return value;
      }
    }

    final String fallback =
    widget.status.trim();

    return fallback.isEmpty
        ? 'Waiting'
        : fallback;
  }

  int _displayedCurrentQueue(
      TokenProvider provider,
      ) {
    if (_isCurrentProviderToken(
      provider,
    )) {
      return provider.currentQueue ??
          widget.currentQueue;
    }

    return widget.currentQueue;
  }

  int _displayedPeopleAhead(
      TokenProvider provider,
      ) {
    if (_isCurrentProviderToken(
      provider,
    )) {
      return provider.peopleAhead ?? 0;
    }

    return _calculateFallbackPeopleAhead();
  }

  String _displayedEstimatedTime(
      TokenProvider provider,
      ) {
    if (_isCurrentProviderToken(
      provider,
    )) {
      final String value =
          provider.estimatedTime?.trim() ??
              '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    final String fallback =
    widget.estimatedTime.trim();

    return fallback.isEmpty
        ? '--'
        : fallback;
  }

  String _displayedIssuedTime(
      TokenProvider provider,
      ) {
    if (_isCurrentProviderToken(
      provider,
    )) {
      final String value =
          provider.issuedTime?.trim() ??
              '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    final String fallback =
    widget.issuedTime.trim();

    return fallback.isEmpty
        ? '--'
        : fallback;
  }

  String _displayedHospitalName(
      TokenProvider provider,
      ) {
    if (_isCurrentProviderToken(
      provider,
    )) {
      final String value =
          provider.hospitalName?.trim() ??
              '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    final String fallback =
    widget.hospitalName.trim();

    return fallback.isEmpty
        ? 'Unknown hospital'
        : fallback;
  }

  String _displayedDepartmentName(
      TokenProvider provider,
      ) {
    if (_isCurrentProviderToken(
      provider,
    )) {
      final String value =
          provider.departmentName
              ?.trim() ??
              '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    final String fallback =
    widget.departmentName.trim();

    return fallback.isEmpty
        ? 'Unknown department'
        : fallback;
  }

  int _calculateFallbackPeopleAhead() {
    final int tokenNumber =
        int.tryParse(
          widget.tokenNumber.replaceAll(
            RegExp(r'[^0-9]'),
            '',
          ),
        ) ??
            0;

    final int difference =
        tokenNumber - widget.currentQueue;

    return difference > 0
        ? difference
        : 0;
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
        return Icons
            .hourglass_top_rounded;

      case 'called':
        return Icons
            .notifications_active_rounded;

      case 'serving':
        return Icons
            .medical_services_rounded;

      case 'completed':
        return Icons
            .check_circle_rounded;

      case 'cancelled':
      case 'canceled':
        return Icons.cancel_rounded;

      default:
        return Icons
            .info_outline_rounded;
    }
  }

  String _getStatusMessage(
      String status,
      ) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return 'Please stay ready while you wait for your turn.';

      case 'called':
        return 'Your token has been called. Please proceed to the department.';

      case 'serving':
        return 'Your token is currently being served.';

      case 'completed':
        return 'Your queue service has been completed.';

      case 'cancelled':
      case 'canceled':
        return 'This queue token has been cancelled.';

      default:
        return 'Your token information will update automatically.';
    }
  }

  bool _canCancel(
      String status,
      ) {
    return status.toLowerCase() ==
        'waiting';
  }

  Future<void> _cancelToken() async {
    if (_isCancelling) {
      return;
    }

    final TokenProvider provider =
    context.read<TokenProvider>();

    final String tokenId =
    _displayedTokenId(
      provider,
    );

    if (tokenId.isEmpty) {
      _showMessage(
        'Token ID is missing',
        isError: true,
      );

      return;
    }

    final bool confirmed =
    await _showCancelConfirmation();

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isCancelling = true;
    });

    try {
      await _tokenService.cancelToken(
        tokenId,
      );

      if (!mounted) {
        return;
      }

      provider.clearToken();

      _showMessage(
        'Token cancelled successfully',
      );

      Navigator.of(context).pop();
    } catch (error) {
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

      if (message.isEmpty) {
        message =
        'Failed to cancel token';
      }

      _showMessage(
        message,
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  Future<bool>
  _showCancelConfirmation() async {
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
            BorderRadius.circular(
              20,
            ),
          ),
          title: Text(
            'Cancel Token',
            style: TextStyle(
              color:
              theme.colorScheme.onSurface,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to cancel this queue token?',
            style: TextStyle(
              color: theme.colorScheme
                  .onSurfaceVariant,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'Keep Token',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              style: TextButton.styleFrom(
                foregroundColor:
                Colors.red,
              ),
              child: const Text(
                'Cancel Token',
              ),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  void _openQrScreen({
    required String tokenNumber,
    required String hospitalName,
    required String departmentName,
    required String issuedTime,
    required String status,
  }) {
    if (tokenNumber.isEmpty ||
        tokenNumber == '--') {
      _showMessage(
        'Token number is unavailable',
        isError: true,
      );

      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QRScreen(
          tokenNumber: tokenNumber,
          hospitalName: hospitalName,
          departmentName:
          departmentName,
          issuedTime: issuedTime,
          status: status,
        ),
      ),
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
          content:
          Text(message),
          backgroundColor:
          isError
              ? Colors.red
              : null,
        ),
      );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final ThemeData theme =
    Theme.of(context);

    return Consumer<TokenProvider>(
      builder: (
          BuildContext context,
          TokenProvider provider,
          Widget? child,
          ) {
        final String tokenNumber =
        _displayedTokenNumber(
          provider,
        );

        final String status =
        _displayedStatus(
          provider,
        );

        final int currentQueue =
        _displayedCurrentQueue(
          provider,
        );

        final int peopleAhead =
        _displayedPeopleAhead(
          provider,
        );

        final String estimatedTime =
        _displayedEstimatedTime(
          provider,
        );

        final String issuedTime =
        _displayedIssuedTime(
          provider,
        );

        final String hospitalName =
        _displayedHospitalName(
          provider,
        );

        final String departmentName =
        _displayedDepartmentName(
          provider,
        );

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
              'My Active Token',
              style: TextStyle(
                color: theme
                    .colorScheme
                    .onSurface,
                fontSize: 22,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding:
              const EdgeInsets.all(
                20,
              ),
              child: Column(
                children: [
                  _buildTopCard(
                    status,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  _buildTokenMainCard(
                    tokenNumber:
                    tokenNumber,
                    status: status,
                    hospitalName:
                    hospitalName,
                    departmentName:
                    departmentName,
                    issuedTime:
                    issuedTime,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  _buildQueueStatusCard(
                    currentQueue:
                    currentQueue,
                    peopleAhead:
                    peopleAhead,
                    estimatedTime:
                    estimatedTime,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  _buildActionButtons(
                    tokenNumber:
                    tokenNumber,
                    status: status,
                    hospitalName:
                    hospitalName,
                    departmentName:
                    departmentName,
                    issuedTime:
                    issuedTime,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopCard(
      String status,
      ) {
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
          24,
        ),
        boxShadow: [
          BoxShadow(
            color: theme
                .colorScheme
                .primary
                .withOpacity(
              0.18,
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
      child: Row(
        children: [
          Icon(
            _getStatusIcon(
              status,
            ),
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Text(
              _getStatusMessage(
                status,
              ),
              style:
              const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight:
                FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenMainCard({
    required String tokenNumber,
    required String status,
    required String hospitalName,
    required String departmentName,
    required String issuedTime,
  }) {
    final ThemeData theme =
    Theme.of(context);

    final Color statusColor =
    _getStatusColor(
      status,
    );

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        22,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius:
        BorderRadius.circular(
          24,
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
        children: [
          Text(
            'Active Queue Token',
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
            height: 18,
          ),
          Container(
            width: 120,
            height: 120,
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
              child: FittedBox(
                fit:
                BoxFit.scaleDown,
                child: Padding(
                  padding:
                  const EdgeInsets.all(
                    12,
                  ),
                  child: Text(
                    tokenNumber,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight:
                      FontWeight.bold,
                      color: theme
                          .colorScheme
                          .primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          AnimatedContainer(
            duration:
            const Duration(
              milliseconds: 250,
            ),
            padding:
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
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
                  size: 16,
                  color:
                  statusColor,
                ),
                const SizedBox(
                  width: 6,
                ),
                Text(
                  status,
                  style: TextStyle(
                    color:
                    statusColor,
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          Divider(
            color:
            theme.dividerColor,
          ),
          const SizedBox(
            height: 12,
          ),
          _buildInfoRow(
            icon: Icons
                .local_hospital_outlined,
            label: 'Hospital',
            value:
            hospitalName,
          ),
          const SizedBox(
            height: 12,
          ),
          _buildInfoRow(
            icon: Icons
                .medical_services_outlined,
            label: 'Department',
            value:
            departmentName,
          ),
          const SizedBox(
            height: 12,
          ),
          _buildInfoRow(
            icon: Icons
                .schedule_outlined,
            label: 'Issued Time',
            value:
            issuedTime,
          ),
        ],
      ),
    );
  }

  Widget _buildQueueStatusCard({
    required int currentQueue,
    required int peopleAhead,
    required String estimatedTime,
  }) {
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
                  ? 0.14
                  : 0.02,
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            'Queue Status',
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
            height: 14,
          ),
          _buildInfoRow(
            icon: Icons
                .people_alt_outlined,
            label:
            'Current Queue',
            value: currentQueue <= 0
                ? '--'
                : currentQueue
                .toString(),
          ),
          const SizedBox(
            height: 12,
          ),
          _buildInfoRow(
            icon: Icons
                .hourglass_bottom_outlined,
            label:
            'People Ahead',
            value: peopleAhead < 0
                ? '0'
                : peopleAhead
                .toString(),
          ),
          const SizedBox(
            height: 12,
          ),
          _buildInfoRow(
            icon: Icons
                .access_time_outlined,
            label:
            'Estimated Waiting',
            value:
            estimatedTime,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons({
    required String tokenNumber,
    required String status,
    required String hospitalName,
    required String departmentName,
    required String issuedTime,
  }) {
    final ThemeData theme =
    Theme.of(context);

    final bool canCancel =
    _canCancel(
      status,
    );

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child:
          ElevatedButton.icon(
            onPressed: () {
              _openQrScreen(
                tokenNumber:
                tokenNumber,
                hospitalName:
                hospitalName,
                departmentName:
                departmentName,
                issuedTime:
                issuedTime,
                status: status,
              );
            },
            icon: const Icon(
              Icons
                  .qr_code_2_outlined,
            ),
            label: const Text(
              'View QR Code',
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                FontWeight.w600,
              ),
            ),
            style:
            ElevatedButton.styleFrom(
              backgroundColor:
              theme.colorScheme.primary,
              foregroundColor:
              theme.colorScheme.onPrimary,
              elevation: 0,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        SizedBox(
          width: double.infinity,
          height: 52,
          child:
          OutlinedButton.icon(
            onPressed: canCancel &&
                !_isCancelling
                ? _cancelToken
                : null,
            icon: _isCancelling
                ? const SizedBox(
              width: 20,
              height: 20,
              child:
              CircularProgressIndicator(
                strokeWidth:
                2.2,
                color:
                Colors.red,
              ),
            )
                : const Icon(
              Icons
                  .cancel_outlined,
            ),
            label: Text(
              _isCancelling
                  ? 'Cancelling...'
                  : 'Cancel Token',
              style:
              const TextStyle(
                fontSize: 15,
                fontWeight:
                FontWeight.w600,
              ),
            ),
            style:
            OutlinedButton.styleFrom(
              foregroundColor:
              Colors.red,
              disabledForegroundColor:
              theme.colorScheme
                  .onSurfaceVariant,
              side: BorderSide(
                color: canCancel
                    ? Colors.red
                    : theme
                    .dividerColor,
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
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final ThemeData theme =
    Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color:
          theme.colorScheme.primary,
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Flexible(
          child: Text(
            value,
            textAlign:
            TextAlign.right,
            overflow:
            TextOverflow.ellipsis,
            maxLines: 2,
            style: TextStyle(
              fontSize: 14,
              fontWeight:
              FontWeight.w600,
              color: theme
                  .colorScheme
                  .onSurface,
            ),
          ),
        ),
      ],
    );
  }
}