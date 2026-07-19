import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({
    super.key,
    required this.userData,
  });

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController addressController;
  late final TextEditingController dobController;

  String? selectedGender;

  bool isLoading = false;
  bool hasChanges = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: _readValue([
        'fullName',
        'name',
      ]),
    );

    emailController = TextEditingController(
      text: _readValue([
        'email',
      ]),
    );

    phoneController = TextEditingController(
      text: _readValue([
        'phone',
      ]),
    );

    addressController = TextEditingController(
      text: _readValue([
        'address',
      ]),
    );

    dobController = TextEditingController(
      text: _readValue([
        'dob',
        'dateOfBirth',
      ]),
    );

    final String gender = _readValue([
      'gender',
    ]);

    if (gender == 'Male' ||
        gender == 'Female' ||
        gender == 'Other') {
      selectedGender = gender;
    }

    nameController.addListener(_markAsChanged);
    phoneController.addListener(_markAsChanged);
    addressController.addListener(_markAsChanged);
    dobController.addListener(_markAsChanged);
  }

  @override
  void dispose() {
    nameController.removeListener(_markAsChanged);
    phoneController.removeListener(_markAsChanged);
    addressController.removeListener(_markAsChanged);
    dobController.removeListener(_markAsChanged);

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    dobController.dispose();

    super.dispose();
  }

  String _readValue(
      List<String> keys,
      ) {
    for (final String key in keys) {
      final String value =
          widget.userData[key]?.toString().trim() ?? '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  void _markAsChanged() {
    if (!hasChanges && mounted) {
      setState(() {
        hasChanges = true;
      });
    }
  }

  Future<void> _pickDate() async {
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    final DateTime initialDate =
        _parseDate(dobController.text) ??
            DateTime(2000);

    final DateTime? pickedDate =
    await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    dobController.text = _formatDate(
      pickedDate,
    );

    setState(() {
      hasChanges = true;
    });
  }

  DateTime? _parseDate(
      String value,
      ) {
    final String normalized = value.trim();

    if (normalized.isEmpty) {
      return null;
    }

    final DateTime? isoDate =
    DateTime.tryParse(normalized);

    if (isoDate != null) {
      return isoDate;
    }

    final List<String> parts =
    normalized.split('/');

    if (parts.length != 3) {
      return null;
    }

    final int? day =
    int.tryParse(parts[0]);

    final int? month =
    int.tryParse(parts[1]);

    final int? year =
    int.tryParse(parts[2]);

    if (day == null ||
        month == null ||
        year == null) {
      return null;
    }

    try {
      final DateTime date = DateTime(
        year,
        month,
        day,
      );

      if (date.day != day ||
          date.month != month ||
          date.year != year) {
        return null;
      }

      return date;
    } catch (_) {
      return null;
    }
  }

  String _formatDate(
      DateTime date,
      ) {
    final String day =
    date.day.toString().padLeft(
      2,
      '0',
    );

    final String month =
    date.month.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/${date.year}';
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

    final String fullName =
    nameController.text.trim();

    final String phone = _normalizePhone(
      phoneController.text,
    );

    final String address =
    addressController.text.trim();

    final String dob =
    dobController.text.trim();

    setState(() {
      isLoading = true;
    });

    try {
      await _authService.updateUserProfile(
        fullName: fullName,
        phone: phone,
      );

      await _authService.updateExtraUserData({
        'fullName': fullName,
        'phone': phone,
        'address': address,
        'dob': dob,
        'gender': selectedGender ?? '',
        'updatedAt':
        DateTime.now().toIso8601String(),
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Profile updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

      setState(() {
        hasChanges = false;
        isLoading = false;
      });

      Navigator.pop(
        context,
        true,
      );
    } catch (error) {
      debugPrint(
        'Profile update error: $error',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _formatError(
          error,
          fallback:
          'Failed to update profile',
        ),
      );

      setState(() {
        isLoading = false;
      });
    }
  }

  String _normalizePhone(
      String value,
      ) {
    return value.trim().replaceAll(
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
      return 'Full name is required';
    }

    if (name.length < 2) {
      return 'Enter a valid full name';
    }

    return null;
  }

  String? _validatePhone(
      String? value,
      ) {
    final String phone = _normalizePhone(
      value ?? '',
    );

    if (phone.isEmpty) {
      return 'Phone number is required';
    }

    if (!RegExp(
      r'^\+?[0-9]{9,15}$',
    ).hasMatch(phone)) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  String? _validateDob(
      String? value,
      ) {
    final String dob =
        value?.trim() ?? '';

    if (dob.isEmpty) {
      return null;
    }

    final DateTime? date =
    _parseDate(dob);

    if (date == null) {
      return 'Enter a valid date';
    }

    if (date.isAfter(DateTime.now())) {
      return 'Date of birth cannot be in the future';
    }

    return null;
  }

  Future<bool> _confirmLeave() async {
    if (isLoading) {
      return false;
    }

    if (!hasChanges) {
      return true;
    }

    final ThemeData theme =
    Theme.of(context);

    final bool? shouldLeave =
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
          title: Text(
            'Discard changes?',
            style: TextStyle(
              color:
              theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Your unsaved profile changes will be lost.',
            style: TextStyle(
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
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
                'Keep Editing',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text(
                'Discard',
              ),
            ),
          ],
        );
      },
    );

    return shouldLeave == true;
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
        final String message =
        data['message']
            .toString()
            .trim();

        if (message.isNotEmpty) {
          return message;
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
          backgroundColor: Colors.red,
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
      canPop:
      !hasChanges && !isLoading,
      onPopInvokedWithResult: (
          bool didPop,
          dynamic result,
          ) async {
        if (didPop) {
          return;
        }

        final bool shouldLeave =
        await _confirmLeave();

        if (shouldLeave && mounted) {
          setState(() {
            hasChanges = false;
          });

          Navigator.pop(context);
        }
      },
      child: Scaffold(
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
            'Personal Information',
            style: TextStyle(
              color:
              theme.colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
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
                    height: 22,
                  ),
                  _buildSectionTitle(
                    'Account Information',
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  _buildTextField(
                    label: 'Full Name',
                    controller:
                    nameController,
                    icon:
                    Icons.person_outline,
                    textInputAction:
                    TextInputAction.next,
                    validator:
                    _validateName,
                  ),
                  _buildTextField(
                    label: 'Email Address',
                    controller:
                    emailController,
                    icon:
                    Icons.email_outlined,
                    enabled: false,
                    keyboardType:
                    TextInputType
                        .emailAddress,
                  ),
                  _buildTextField(
                    label: 'Phone Number',
                    controller:
                    phoneController,
                    icon:
                    Icons.phone_outlined,
                    keyboardType:
                    TextInputType.phone,
                    textInputAction:
                    TextInputAction.next,
                    validator:
                    _validatePhone,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  _buildSectionTitle(
                    'Personal Details',
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  _buildTextField(
                    label: 'Address',
                    controller:
                    addressController,
                    icon: Icons
                        .location_on_outlined,
                    textInputAction:
                    TextInputAction.next,
                    maxLines: 2,
                  ),
                  _buildTextField(
                    label: 'Date of Birth',
                    controller:
                    dobController,
                    icon: Icons
                        .calendar_month_outlined,
                    readOnly: true,
                    onTap: _pickDate,
                    validator:
                    _validateDob,
                    suffixIcon: Icons
                        .calendar_today_rounded,
                  ),
                  _buildGenderDropdown(),
                  const SizedBox(
                    height: 28,
                  ),
                  _buildSaveButton(),
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
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
        theme.colorScheme.primary,
        borderRadius:
        BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary
                .withOpacity(0.18),
            blurRadius: 16,
            offset:
            const Offset(0, 7),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
            Colors.white24,
            child: Icon(
              Icons
                  .manage_accounts_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Update Your Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Keep your personal information accurate and up to date.',
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
        fontWeight: FontWeight.bold,
        color:
        theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController
    controller,
    required IconData icon,
    bool readOnly = false,
    bool enabled = true,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    int maxLines = 1,
    IconData? suffixIcon,
  }) {
    final ThemeData theme =
    Theme.of(context);

    final bool fieldEnabled =
        enabled && !isLoading;

    final Color fillColor = fieldEnabled
        ? theme.cardColor
        : theme.colorScheme.surfaceContainerHighest;

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 16,
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        enabled: fieldEnabled,
        onTap: onTap,
        keyboardType: keyboardType,
        textInputAction:
        textInputAction,
        validator: validator,
        maxLines: maxLines,
        style: TextStyle(
          color:
          theme.colorScheme.onSurface,
        ),
        cursorColor:
        theme.colorScheme.primary,
        autovalidateMode:
        AutovalidateMode
            .onUserInteraction,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: theme
                .colorScheme
                .onSurfaceVariant,
          ),
          prefixIcon: Icon(
            icon,
            color:
            theme.colorScheme.primary,
          ),
          suffixIcon: suffixIcon == null
              ? null
              : Icon(
            suffixIcon,
            color: theme
                .colorScheme
                .onSurfaceVariant,
          ),
          filled: true,
          fillColor: fillColor,
          contentPadding:
          const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(14),
            borderSide: BorderSide(
              color: theme.dividerColor,
            ),
          ),
          disabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(14),
            borderSide: BorderSide(
              color: theme.dividerColor,
            ),
          ),
          focusedBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(14),
            borderSide: BorderSide(
              color:
              theme.colorScheme.primary,
              width: 1.3,
            ),
          ),
          errorBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(14),
            borderSide:
            const BorderSide(
              color: Colors.red,
            ),
          ),
          focusedErrorBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(14),
            borderSide:
            const BorderSide(
              color: Colors.red,
              width: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    final ThemeData theme =
    Theme.of(context);

    return DropdownButtonFormField<String>(
      value: selectedGender,
      isExpanded: true,
      dropdownColor: theme.cardColor,
      style: TextStyle(
        color:
        theme.colorScheme.onSurface,
        fontSize: 16,
      ),
      iconEnabledColor:
      theme.colorScheme.onSurfaceVariant,
      validator: (
          String? value,
          ) {
        if (value == null ||
            value.isEmpty) {
          return 'Please select your gender';
        }

        return null;
      },
      autovalidateMode:
      AutovalidateMode
          .onUserInteraction,
      items: const [
        DropdownMenuItem(
          value: 'Male',
          child: Text('Male'),
        ),
        DropdownMenuItem(
          value: 'Female',
          child: Text('Female'),
        ),
        DropdownMenuItem(
          value: 'Other',
          child: Text(
            'Prefer not to say',
          ),
        ),
      ],
      onChanged: isLoading
          ? null
          : (
          String? value,
          ) {
        setState(() {
          selectedGender = value;
          hasChanges = true;
        });
      },
      decoration: InputDecoration(
        labelText: 'Gender',
        labelStyle: TextStyle(
          color: theme
              .colorScheme
              .onSurfaceVariant,
        ),
        prefixIcon: Icon(
          Icons.wc_outlined,
          color:
          theme.colorScheme.primary,
        ),
        filled: true,
        fillColor: theme.cardColor,
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.dividerColor,
          ),
        ),
        disabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
          borderSide: BorderSide(
            color: theme.dividerColor,
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
          borderSide: BorderSide(
            color:
            theme.colorScheme.primary,
            width: 1.3,
          ),
        ),
        errorBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
          borderSide:
          const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
          borderSide:
          const BorderSide(
            color: Colors.red,
            width: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final ThemeData theme =
    Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed:
        isLoading ? null : _saveProfile,
        icon: isLoading
            ? const SizedBox(
          width: 22,
          height: 22,
          child:
          CircularProgressIndicator(
            strokeWidth: 2.4,
            color: Colors.white,
          ),
        )
            : const Icon(
          Icons.save_outlined,
        ),
        label: Text(
          isLoading
              ? 'Saving...'
              : 'Save Changes',
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
          theme.colorScheme.primary,
          foregroundColor:
          theme.colorScheme.onPrimary,
          disabledBackgroundColor:
          theme.dividerColor,
          disabledForegroundColor:
          theme.colorScheme
              .onSurfaceVariant,
          elevation: 0,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}