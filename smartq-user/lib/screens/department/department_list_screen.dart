import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../models/department_model.dart';
import '../../services/api_service.dart';
import '../../services/department_service.dart';
import '../token/token_screen.dart';

class DepartmentListScreen extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;

  const DepartmentListScreen({
    super.key,
    required this.hospitalId,
    required this.hospitalName,
  });

  @override
  State<DepartmentListScreen> createState() =>
      _DepartmentListScreenState();
}

class _DepartmentListScreenState
    extends State<DepartmentListScreen> {
  final DepartmentService _departmentService =
  DepartmentService();

  final ApiService _apiService =
  ApiService();

  final TextEditingController _searchController =
  TextEditingController();

  List<DepartmentModel> _departments = [];

  final Map<String, QueueAvailability>
  _queueAvailability = {};

  final Set<String> _loadingQueueDepartmentIds = {};

  bool _isLoading = true;
  bool _isRefreshing = false;

  String _searchQuery = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    _loadDepartments();
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  Future<void> _loadDepartments({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final String hospitalId =
      widget.hospitalId.trim();

      if (hospitalId.isEmpty) {
        throw Exception(
          'Hospital ID is unavailable',
        );
      }

      final List<DepartmentModel> data =
      await _departmentService.getDepartments(
        hospitalId,
      );

      data.sort(
            (
            DepartmentModel first,
            DepartmentModel second,
            ) =>
            first.name.toLowerCase().compareTo(
              second.name.toLowerCase(),
            ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _departments = data;

        _queueAvailability.clear();

        _loadingQueueDepartmentIds.clear();

        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = '';
      });

      await _loadAllQueueAvailability(
        data,
      );
    } catch (error) {
      debugPrint(
        'Department loading error: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isRefreshing = false;

        _errorMessage = _formatError(
          error,
          fallback:
          'Failed to load departments',
        );
      });
    }
  }

  Future<void> _loadAllQueueAvailability(
      List<DepartmentModel> departments,
      ) async {
    await Future.wait(
      departments.map(
            (DepartmentModel department) =>
            _loadQueueAvailability(
              department.id,
            ),
      ),
    );
  }

  Future<void> _loadQueueAvailability(
      String departmentId,
      ) async {
    final String normalizedDepartmentId =
    departmentId.trim();

    if (normalizedDepartmentId.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        _loadingQueueDepartmentIds.add(
          normalizedDepartmentId,
        );
      });
    }

    try {
      final Response<dynamic> response =
      await _apiService.dio.get(
        '/departments/'
            '$normalizedDepartmentId/queue',
      );

      final QueueAvailability availability =
      QueueAvailability.fromJson(
        _toMap(
          response.data,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _queueAvailability[
        normalizedDepartmentId] =
            availability;

        _loadingQueueDepartmentIds.remove(
          normalizedDepartmentId,
        );
      });
    } on DioException catch (error) {
      debugPrint(
        'Queue availability error for '
            '$normalizedDepartmentId: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _queueAvailability[
        normalizedDepartmentId] =
            QueueAvailability(
              canIssueToken: false,
              isOpen: false,
              status: 'Unavailable',
              message: _getDioErrorMessage(
                error,
                fallback:
                'Queue information is unavailable',
              ),
            );

        _loadingQueueDepartmentIds.remove(
          normalizedDepartmentId,
        );
      });
    } catch (error) {
      debugPrint(
        'Queue availability error for '
            '$normalizedDepartmentId: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _queueAvailability[
        normalizedDepartmentId] =
        const QueueAvailability(
          canIssueToken: false,
          isOpen: false,
          status: 'Unavailable',
          message:
          'Queue information is unavailable',
        );

        _loadingQueueDepartmentIds.remove(
          normalizedDepartmentId,
        );
      });
    }
  }

  Future<void> _refreshDepartments() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
      _errorMessage = '';
    });

    await _loadDepartments(
      showLoading: false,
    );
  }

  List<DepartmentModel> get _filteredDepartments {
    final String query =
    _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return _departments;
    }

    return _departments.where(
          (
          DepartmentModel department,
          ) {
        return department.name
            .toLowerCase()
            .contains(
          query,
        );
      },
    ).toList();
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
    });
  }

  void _openTokenScreen(
      DepartmentModel department,
      ) {
    final QueueAvailability? availability =
    _queueAvailability[
    department.id];

    if (availability == null) {
      _showMessage(
        'Queue information is still loading',
      );

      return;
    }

    if (!availability.canIssueToken) {
      _showQueueUnavailableDialog(
        departmentName:
        department.name,
        availability:
        availability,
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TokenScreen(
          hospitalId:
          widget.hospitalId,
          hospitalName:
          widget.hospitalName,
          departmentId:
          department.id,
          departmentName:
          department.name,
          currentQueue:
          availability.currentQueue,
          estimatedTime:
          availability.estimatedTime,
        ),
      ),
    );
  }

  Future<void> _showQueueUnavailableDialog({
    required String departmentName,
    required QueueAvailability availability,
  }) async {
    final ThemeData theme =
    Theme.of(context);

    final String normalizedStatus =
    availability.status
        .trim()
        .toLowerCase();

    final bool isFull =
        normalizedStatus == 'full';

    final bool isScheduled =
        normalizedStatus == 'scheduled';

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
              20,
            ),
          ),
          title: Row(
            children: [
              Icon(
                isFull
                    ? Icons
                    .group_off_outlined
                    : Icons
                    .schedule_outlined,
                color: isFull
                    ? Colors.orange
                    : Colors.red,
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  isScheduled
                      ? 'Queue Not Started'
                      : isFull
                      ? 'Queue Full'
                      : 'Queue Closed',
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
                departmentName,
                style: TextStyle(
                  color: theme
                      .colorScheme
                      .onSurface,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                availability.message,
                style: TextStyle(
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (availability.startAt != null ||
                  availability.endAt != null) ...[
                const SizedBox(
                  height: 16,
                ),
                _buildDialogTimeRow(
                  label: 'Opening',
                  value:
                  _formatDateTime(
                    availability.startAt,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                _buildDialogTimeRow(
                  label: 'Closing',
                  value:
                  _formatDateTime(
                    availability.endAt,
                  ),
                ),
              ],
              if (availability.remainingTokens !=
                  null) ...[
                const SizedBox(
                  height: 8,
                ),
                _buildDialogTimeRow(
                  label:
                  'Remaining tokens',
                  value: availability
                      .remainingTokens
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
              child: const Text(
                'Close',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogTimeRow({
    required String label,
    required String value,
  }) {
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
            fontWeight:
            FontWeight.w600,
            color: theme
                .colorScheme
                .onSurface,
          ),
        ),
      ],
    );
  }

  void _showMessage(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
          Text(message),
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
          'Departments',
          style: TextStyle(
            color: theme
                .colorScheme
                .onSurface,
            fontSize: 22,
            fontWeight:
            FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip:
            'Refresh departments',
            onPressed: _isRefreshing
                ? null
                : _refreshDepartments,
            icon: _isRefreshing
                ? SizedBox(
              width: 20,
              height: 20,
              child:
              CircularProgressIndicator(
                strokeWidth:
                2.2,
                color: theme
                    .colorScheme
                    .primary,
              ),
            )
                : const Icon(
              Icons
                  .refresh_rounded,
            ),
          ),
          const SizedBox(
            width: 6,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                0,
              ),
              child:
              _buildHospitalHeader(),
            ),
            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                12,
              ),
              child:
              _buildSearchBar(),
            ),
            Expanded(
              child:
              _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final ThemeData theme =
    Theme.of(context);

    if (_isLoading) {
      return Center(
        child:
        CircularProgressIndicator(
          color:
          theme.colorScheme.primary,
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (_departments.isEmpty) {
      return _buildEmptyState(
        title:
        'No departments available',
        message:
        'No departments are currently available for this hospital.',
      );
    }

    final List<DepartmentModel>
    visibleDepartments =
        _filteredDepartments;

    if (visibleDepartments.isEmpty) {
      return _buildEmptyState(
        title:
        'No departments found',
        message:
        'Try another department name.',
        showClearSearch: true,
      );
    }

    return RefreshIndicator(
      color:
      theme.colorScheme.primary,
      onRefresh:
      _refreshDepartments,
      child: ListView.builder(
        keyboardDismissBehavior:
        ScrollViewKeyboardDismissBehavior
            .onDrag,
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          24,
        ),
        itemCount:
        visibleDepartments.length,
        itemBuilder: (
            BuildContext context,
            int index,
            ) {
          final DepartmentModel department =
          visibleDepartments[index];

          return _buildDepartmentCard(
            department,
          );
        },
      ),
    );
  }

  Widget _buildHospitalHeader() {
    final ThemeData theme =
    Theme.of(context);

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(
        18,
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
          Container(
            width: 48,
            height: 48,
            decoration:
            BoxDecoration(
              color: Colors.white
                  .withOpacity(
                0.18,
              ),
              borderRadius:
              BorderRadius.circular(
                15,
              ),
            ),
            child: const Icon(
              Icons
                  .local_hospital_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(
            width: 13,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Hospital',
                  style: TextStyle(
                    color:
                    Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  widget.hospitalName,
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    color:
                    Colors.white,
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final ThemeData theme =
    Theme.of(context);

    return TextField(
      controller:
      _searchController,
      textInputAction:
      TextInputAction.search,
      style: TextStyle(
        color:
        theme.colorScheme.onSurface,
      ),
      cursorColor:
      theme.colorScheme.primary,
      onChanged: (
          String value,
          ) {
        setState(() {
          _searchQuery =
              value.trim();
        });
      },
      onSubmitted: (_) {
        FocusScope.of(context)
            .unfocus();
      },
      decoration: InputDecoration(
        hintText:
        'Search departments...',
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
        suffixIcon:
        _searchQuery.isNotEmpty
            ? IconButton(
          onPressed:
          _clearSearch,
          icon: Icon(
            Icons
                .close_rounded,
            color: theme
                .colorScheme
                .onSurfaceVariant,
          ),
        )
            : null,
        filled: true,
        fillColor:
        theme.cardColor,
        contentPadding:
        const EdgeInsets.symmetric(
          vertical: 16,
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
                .colorScheme
                .primary,
            width: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentCard(
      DepartmentModel department,
      ) {
    final ThemeData theme =
    Theme.of(context);

    final String departmentId =
    department.id.trim();

    final bool isQueueLoading =
    _loadingQueueDepartmentIds.contains(
      departmentId,
    );

    final QueueAvailability? availability =
    _queueAvailability[
    departmentId];

    final bool canIssueToken =
        availability?.canIssueToken ??
            false;

    final Color statusColor =
    isQueueLoading
        ? theme.colorScheme
        .onSurfaceVariant
        : _getQueueStatusColor(
      availability?.status ??
          'Unavailable',
    );

    final String statusText =
    isQueueLoading
        ? 'Checking queue...'
        : _getQueueStatusText(
      availability,
    );

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 16,
      ),
      decoration: BoxDecoration(
        borderRadius:
        BorderRadius.circular(
          22,
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
      child: Material(
        color: theme.cardColor,
        borderRadius:
        BorderRadius.circular(
          22,
        ),
        child: InkWell(
          borderRadius:
          BorderRadius.circular(
            22,
          ),
          onTap: isQueueLoading
              ? null
              : () =>
              _openTokenScreen(
                department,
              ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius:
              BorderRadius.circular(
                22,
              ),
              border: Border.all(
                color:
                theme.dividerColor,
              ),
            ),
            padding:
            const EdgeInsets.all(
              18,
            ),
            child: Column(
              children: [
                Row(
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
                        Icons
                            .medical_services_outlined,
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
                            department.name,
                            maxLines: 2,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            TextStyle(
                              fontSize: 17,
                              fontWeight:
                              FontWeight
                                  .bold,
                              color: theme
                                  .colorScheme
                                  .onSurface,
                            ),
                          ),
                          const SizedBox(
                            height: 7,
                          ),
                          Row(
                            children: [
                              if (isQueueLoading)
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                  CircularProgressIndicator(
                                    strokeWidth:
                                    2,
                                    color: theme
                                        .colorScheme
                                        .primary,
                                  ),
                                )
                              else
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration:
                                  BoxDecoration(
                                    color:
                                    statusColor,
                                    shape:
                                    BoxShape
                                        .circle,
                                  ),
                                ),
                              const SizedBox(
                                width: 7,
                              ),
                              Expanded(
                                child: Text(
                                  statusText,
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow
                                      .ellipsis,
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
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Icon(
                      canIssueToken
                          ? Icons
                          .arrow_forward_ios_rounded
                          : Icons
                          .lock_outline_rounded,
                      size: 17,
                      color: canIssueToken
                          ? theme
                          .colorScheme
                          .primary
                          : theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ],
                ),
                if (!isQueueLoading &&
                    availability != null) ...[
                  const SizedBox(
                    height: 14,
                  ),
                  Divider(
                    height: 1,
                    color:
                    theme.dividerColor,
                  ),
                  const SizedBox(
                    height: 13,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child:
                        _buildQueueDetail(
                          icon: Icons
                              .schedule_outlined,
                          label:
                          'Queue time',
                          value:
                          _formatQueuePeriod(
                            availability,
                          ),
                        ),
                      ),
                      if (availability
                          .remainingTokens !=
                          null)
                        Expanded(
                          child:
                          _buildQueueDetail(
                            icon: Icons
                                .confirmation_number_outlined,
                            label:
                            'Remaining',
                            value: availability
                                .remainingTokens
                                .toString(),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQueueDetail({
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
          size: 17,
          color:
          theme.colorScheme.primary,
        ),
        const SizedBox(
          width: 7,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                value,
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: theme
                      .colorScheme
                      .onSurface,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
      0.30,
    )
        : Colors.red.shade100;

    final Color messageColor =
    isDark
        ? Colors.red.shade200
        : Colors.red.shade700;

    return RefreshIndicator(
      color:
      theme.colorScheme.primary,
      onRefresh:
      _refreshDepartments,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(
          24,
        ),
        children: [
          const SizedBox(
            height: 80,
          ),
          Container(
            padding:
            const EdgeInsets.all(
              24,
            ),
            decoration:
            BoxDecoration(
              color: backgroundColor,
              borderRadius:
              BorderRadius.circular(
                22,
              ),
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons
                      .error_outline_rounded,
                  size: 44,
                  color: messageColor,
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  'Unable to load departments',
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
                  height: 8,
                ),
                Text(
                  _errorMessage,
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    color: messageColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                ElevatedButton.icon(
                  onPressed:
                  _refreshDepartments,
                  icon: const Icon(
                    Icons
                        .refresh_rounded,
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

  Widget _buildEmptyState({
    required String title,
    required String message,
    bool showClearSearch = false,
  }) {
    final ThemeData theme =
    Theme.of(context);

    return RefreshIndicator(
      color:
      theme.colorScheme.primary,
      onRefresh:
      _refreshDepartments,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(
          24,
        ),
        children: [
          const SizedBox(
            height: 90,
          ),
          Container(
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
              children: [
                Icon(
                  Icons
                      .medical_services_outlined,
                  size: 48,
                  color: theme
                      .colorScheme
                      .onSurfaceVariant,
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  title,
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
                  message,
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (showClearSearch) ...[
                  const SizedBox(
                    height: 14,
                  ),
                  TextButton.icon(
                    onPressed:
                    _clearSearch,
                    icon: const Icon(
                      Icons
                          .close_rounded,
                    ),
                    label: const Text(
                      'Clear Search',
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

  String _getQueueStatusText(
      QueueAvailability? availability,
      ) {
    if (availability == null) {
      return 'Queue unavailable';
    }

    final String status =
    availability.status
        .trim()
        .toLowerCase();

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
        return availability.status
            .trim()
            .isEmpty
            ? 'Queue unavailable'
            : availability.status;
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

  String _formatQueuePeriod(
      QueueAvailability availability,
      ) {
    final String start =
    _formatTime(
      availability.startAt,
    );

    final String end =
    _formatTime(
      availability.endAt,
    );

    if (start == '--' &&
        end == '--') {
      return 'Unavailable';
    }

    return '$start - $end';
  }

  String _formatTime(
      DateTime? value,
      ) {
    if (value == null) {
      return '--';
    }

    final DateTime local =
    value.toLocal();

    int hour = local.hour;

    final String minute =
    local.minute
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

  String _formatDateTime(
      DateTime? value,
      ) {
    if (value == null) {
      return '--';
    }

    final DateTime local =
    value.toLocal();

    final String day =
    local.day
        .toString()
        .padLeft(
      2,
      '0',
    );

    final String month =
    local.month
        .toString()
        .padLeft(
      2,
      '0',
    );

    return '$day/$month/${local.year} '
        '${_formatTime(local)}';
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
    final dynamic data =
        error.response?.data;

    if (data is Map &&
        data['message'] != null) {
      final String message =
      data['message']
          .toString()
          .trim();

      if (message.isNotEmpty) {
        return message;
      }
    }

    return fallback;
  }

  String _formatError(
      dynamic error, {
        required String fallback,
      }) {
    try {
      final dynamic data =
          error.response?.data;

      if (data is Map &&
          data['message'] != null) {
        final String responseMessage =
        data['message']
            .toString()
            .trim();

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

    return message.isEmpty
        ? fallback
        : message;
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
      canIssueToken:
      _readBoolean(
        json['canIssueToken'],
      ),
      isOpen:
      _readBoolean(
        json['isOpen'],
      ),
      status: json['status']
          ?.toString()
          .trim() ??
          'Unavailable',
      message: json['message']
          ?.toString()
          .trim() ??
          'Queue information is unavailable',
      queueSessionId:
      json['queueSessionId']
          ?.toString()
          .trim() ??
          '',
      startAt:
      _readDateTime(
        json['startAt'],
      ),
      endAt:
      _readDateTime(
        json['endAt'],
      ),
      maximumTokens:
      _readNullableInteger(
        json['maximumTokens'],
      ),
      issuedTokenCount:
      _readInteger(
        json['issuedTokenCount'],
      ),
      remainingTokens:
      _readNullableInteger(
        json['remainingTokens'],
      ),
      currentQueue:
      _readInteger(
        json['currentQueue'],
      ),
      estimatedTime:
      json['estimatedTime']
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
      value?.toString() ??
          '',
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