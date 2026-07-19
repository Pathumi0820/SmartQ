import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRScreen extends StatelessWidget {
  final String tokenNumber;
  final String hospitalName;
  final String departmentName;
  final String issuedTime;
  final String status;

  const QRScreen({
    super.key,
    required this.tokenNumber,
    required this.hospitalName,
    required this.departmentName,
    required this.issuedTime,
    required this.status,
  });

  String get _normalizedTokenNumber {
    return tokenNumber.trim().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final String qrData =
        _normalizedTokenNumber;

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
          'QR Code',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildTopCard(context),
              const SizedBox(height: 20),
              _buildQRCodeCard(
                context,
                qrData,
              ),
              const SizedBox(height: 20),
              _buildInstructionsCard(
                context,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopCard(
      BuildContext context,
      ) {
    final ThemeData theme =
    Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(
          24,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary
                .withOpacity(0.2),
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
              color: Colors.white.withOpacity(
                0.18,
              ),
              borderRadius: BorderRadius.circular(
                18,
              ),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Show this QR code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Department staff will scan it to verify your queue token.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
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

  Widget _buildQRCodeCard(
      BuildContext context,
      String qrData,
      ) {
    final ThemeData theme =
    Theme.of(context);

    final bool hasValidToken =
        qrData.isNotEmpty;

    final Color cardColor =
        theme.cardColor;

    final Color borderColor =
        theme.dividerColor;

    final Color primaryTextColor =
        theme.colorScheme.onSurface;

    final Color secondaryTextColor =
        theme.colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(
          24,
        ),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness ==
                  Brightness.dark
                  ? 0.2
                  : 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Queue Verification QR',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasValidToken
                ? 'Scan to verify token $qrData'
                : 'Token number is unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: hasValidToken
                  ? secondaryTextColor
                  : theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 20),

          // Keep the QR background white in both themes.
          // This gives scanners reliable contrast.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(
                  0xFFE2E8F0,
                ),
              ),
              borderRadius: BorderRadius.circular(
                20,
              ),
            ),
            child: hasValidToken
                ? QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 220,
              backgroundColor:
              Colors.white,
              eyeStyle:
              const QrEyeStyle(
                eyeShape:
                QrEyeShape.square,
                color:
                Colors.black,
              ),
              dataModuleStyle:
              const QrDataModuleStyle(
                dataModuleShape:
                QrDataModuleShape
                    .square,
                color:
                Colors.black,
              ),
              errorCorrectionLevel:
              QrErrorCorrectLevel.M,
            )
                : SizedBox(
              width: 220,
              height: 220,
              child: Center(
                child: Icon(
                  Icons
                      .error_outline_rounded,
                  size: 52,
                  color: theme
                      .colorScheme
                      .error,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          _buildInfoRow(
            context: context,
            icon:
            Icons.confirmation_number_outlined,
            label: 'Token Number',
            value: qrData.isEmpty
                ? '--'
                : qrData,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context: context,
            icon:
            Icons.local_hospital_outlined,
            label: 'Hospital',
            value: _displayValue(
              hospitalName,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context: context,
            icon:
            Icons.medical_services_outlined,
            label: 'Department',
            value: _displayValue(
              departmentName,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context: context,
            icon: Icons.schedule_outlined,
            label: 'Issued Time',
            value: _displayValue(
              issuedTime,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
      BuildContext context,
      ) {
    final ThemeData theme =
    Theme.of(context);

    final String displayStatus =
    _displayValue(status);

    final Color statusColor =
    _getStatusColor(
      context,
      displayStatus,
    );

    return Row(
      children: [
        Icon(
          Icons.verified_outlined,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Status',
            style: TextStyle(
              fontSize: 14,
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(
              0.12,
            ),
            borderRadius: BorderRadius.circular(
              18,
            ),
          ),
          child: Text(
            displayStatus,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsCard(
      BuildContext context,
      ) {
    final ThemeData theme =
    Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: theme.dividerColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness ==
                  Brightness.dark
                  ? 0.16
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
        children: [
          Text(
            'Instructions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          const _InstructionRow(
            text:
            'Show this QR code when you arrive at the selected department.',
          ),
          const SizedBox(height: 10),
          const _InstructionRow(
            text:
            'The department staff will scan it to verify your token.',
          ),
          const SizedBox(height: 10),
          const _InstructionRow(
            text:
            'Keep this QR code available until your queue process is completed.',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
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
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
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
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
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

  Color _getStatusColor(
      BuildContext context,
      String value,
      ) {
    switch (value.toLowerCase()) {
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

  String _displayValue(
      String value,
      ) {
    final String normalizedValue =
    value.trim();

    return normalizedValue.isEmpty
        ? '--'
        : normalizedValue;
  }
}

class _InstructionRow extends StatelessWidget {
  final String text;

  const _InstructionRow({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme =
    Theme.of(context);

    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}