import 'package:flutter/material.dart';

import '../../services/hospital_service.dart';
import '../department/department_list_screen.dart';

class HospitalListScreen extends StatefulWidget {
  final bool autofocusSearch;

  const HospitalListScreen({
    super.key,
    this.autofocusSearch = false,
  });

  @override
  State<HospitalListScreen> createState() =>
      _HospitalListScreenState();
}

class _HospitalListScreenState
    extends State<HospitalListScreen> {
  final HospitalService _hospitalService =
  HospitalService();

  final TextEditingController _searchController =
  TextEditingController();

  final FocusNode _searchFocusNode =
  FocusNode();

  List<HospitalSummary> _hospitals = [];

  bool _isLoading = true;
  bool _isRefreshing = false;

  String _searchQuery = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    _loadHospitals();

    if (widget.autofocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback(
            (_) {
          if (!mounted) {
            return;
          }

          _searchFocusNode.requestFocus();
        },
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();

    super.dispose();
  }

  Future<void> _loadHospitals({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final List<HospitalSummary> data =
      await _hospitalService
          .getHospitalsWithDepartmentCounts();

      if (!mounted) {
        return;
      }

      data.sort(
            (
            HospitalSummary first,
            HospitalSummary second,
            ) =>
            first.name.toLowerCase().compareTo(
              second.name.toLowerCase(),
            ),
      );

      setState(() {
        _hospitals = data;
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = '';
      });
    } catch (error) {
      debugPrint(
        'Hospital loading error: $error',
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
          'Failed to load hospitals',
        );
      });
    }
  }

  Future<void> _refreshHospitals() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
      _errorMessage = '';
    });

    await _loadHospitals(
      showLoading: false,
    );
  }

  List<HospitalSummary>
  get _filteredHospitals {
    final String normalizedQuery =
    _searchQuery.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return _hospitals;
    }

    return _hospitals.where(
          (
          HospitalSummary hospital,
          ) {
        final String name =
        hospital.name.toLowerCase();

        final String city =
        hospital.city.toLowerCase();

        return name.contains(
          normalizedQuery,
        ) ||
            city.contains(
              normalizedQuery,
            );
      },
    ).toList();
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
    });

    _searchFocusNode.requestFocus();
  }

  void _openDepartmentList(
      HospitalSummary hospital,
      ) {
    final String hospitalId =
    hospital.id.trim();

    if (hospitalId.isEmpty) {
      _showMessage(
        'Hospital ID is unavailable',
      );

      return;
    }

    FocusScope.of(context).unfocus();

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            DepartmentListScreen(
              hospitalId: hospitalId,
              hospitalName: hospital.name,
            ),
      ),
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
          content: Text(message),
        ),
      );
  }

  String _formatError(
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
      // Use the formatted error below.
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
          'Hospitals',
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
            tooltip:
            'Refresh hospitals',
            onPressed: _isRefreshing
                ? null
                : _refreshHospitals,
            icon: _isRefreshing
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
                12,
              ),
              child: _buildSearchBar(),
            ),
            Expanded(
              child: _buildContent(),
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
        child: CircularProgressIndicator(
          color:
          theme.colorScheme.primary,
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (_hospitals.isEmpty) {
      return _buildEmptyState(
        title:
        'No hospitals available',
        message:
        'Hospitals added by the administrator will appear here.',
      );
    }

    final List<HospitalSummary>
    visibleHospitals =
        _filteredHospitals;

    if (visibleHospitals.isEmpty) {
      return _buildEmptyState(
        title: 'No hospitals found',
        message:
        'Try searching with a different hospital name or city.',
        showClearSearch: true,
      );
    }

    return RefreshIndicator(
      color:
      theme.colorScheme.primary,
      onRefresh:
      _refreshHospitals,
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
        visibleHospitals.length,
        itemBuilder: (
            BuildContext context,
            int index,
            ) {
          final HospitalSummary hospital =
          visibleHospitals[index];

          return _buildHospitalCard(
            hospital,
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    final ThemeData theme =
    Theme.of(context);

    return TextField(
      controller:
      _searchController,
      focusNode:
      _searchFocusNode,
      autofocus:
      widget.autofocusSearch,
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
        'Search hospitals or cities...',
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
          tooltip:
          'Clear search',
          onPressed:
          _clearSearch,
          icon: Icon(
            Icons.close_rounded,
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
            width: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalCard(
      HospitalSummary hospital,
      ) {
    final ThemeData theme =
    Theme.of(context);

    final String hospitalName =
    hospital.name.trim().isEmpty
        ? 'Unnamed Hospital'
        : hospital.name.trim();

    final String hospitalCity =
    hospital.city.trim().isEmpty
        ? 'Location unavailable'
        : hospital.city.trim();

    final int departmentCount =
        hospital.departmentCount;

    final String departmentText =
    departmentCount == 1
        ? '1 Department'
        : '$departmentCount Departments';

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
          onTap: () =>
              _openDepartmentList(
                hospital,
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
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
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
                  child: Icon(
                    Icons
                        .local_hospital_rounded,
                    color: theme
                        .colorScheme
                        .primary,
                    size: 30,
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
                        hospitalName,
                        maxLines: 2,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                          FontWeight
                              .bold,
                          color: theme
                              .colorScheme
                              .onSurface,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(
                        height: 7,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons
                                .location_on_outlined,
                            size: 16,
                            color: theme
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Expanded(
                            child: Text(
                              hospitalCity,
                              maxLines: 1,
                              overflow:
                              TextOverflow
                                  .ellipsis,
                              style:
                              TextStyle(
                                fontSize:
                                14,
                                color: theme
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 7,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons
                                .medical_services_outlined,
                            size: 16,
                            color: theme
                                .colorScheme
                                .primary,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            departmentText,
                            style:
                            TextStyle(
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
                    ],
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Container(
                  width: 34,
                  height: 34,
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
                        .arrow_forward_ios_rounded,
                    size: 15,
                    color: theme
                        .colorScheme
                        .primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
      _refreshHospitals,
      child: ListView(
        keyboardDismissBehavior:
        ScrollViewKeyboardDismissBehavior
            .onDrag,
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
                  'Unable to load hospitals',
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
                    fontSize: 14,
                    color: messageColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                ElevatedButton.icon(
                  onPressed:
                  _isRefreshing
                      ? null
                      : _refreshHospitals,
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                  label: const Text(
                    'Try Again',
                  ),
                  style:
                  ElevatedButton.styleFrom(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
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
      _refreshHospitals,
      child: ListView(
        keyboardDismissBehavior:
        ScrollViewKeyboardDismissBehavior
            .onDrag,
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(
          24,
        ),
        children: [
          const SizedBox(
            height: 100,
          ),
          Container(
            padding:
            const EdgeInsets.all(
              26,
            ),
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
                      .local_hospital_outlined,
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
                    fontSize: 14,
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
                      Icons.close_rounded,
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
}