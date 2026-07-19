import 'package:flutter/material.dart';

class TokenProvider extends ChangeNotifier {
  /// MongoDB token document ID.
  String? tokenId;

  /// Token details.
  String? tokenNumber;
  String? hospitalId;
  String? hospitalName;
  String? departmentId;
  String? departmentName;

  /// Live queue information.
  int? currentQueue;
  int? peopleAhead;
  int? estimatedMinutes;
  String? estimatedTime;
  String? issuedTime;

  /// Current token status.
  String status = 'Not Generated';

  bool get hasActiveToken =>
      tokenId?.trim().isNotEmpty == true &&
          tokenNumber?.trim().isNotEmpty == true;

  void setToken({
    required String tokenId,
    required String tokenNumber,
    required String hospitalId,
    required String hospitalName,
    required String departmentId,
    required String departmentName,
    required int currentQueue,
    required int peopleAhead,
    required int estimatedMinutes,
    required String estimatedTime,
    required String issuedTime,
    String status = 'Waiting',
  }) {
    this.tokenId = tokenId.trim();
    this.tokenNumber = tokenNumber.trim();
    this.hospitalId = hospitalId.trim();
    this.hospitalName = hospitalName.trim();
    this.departmentId = departmentId.trim();
    this.departmentName = departmentName.trim();

    this.currentQueue = currentQueue;
    this.peopleAhead = peopleAhead;
    this.estimatedMinutes = estimatedMinutes;
    this.estimatedTime = estimatedTime.trim();
    this.issuedTime = issuedTime.trim();
    this.status = status.trim().isEmpty
        ? 'Waiting'
        : status.trim();

    notifyListeners();
  }

  void updateStatus(String newStatus) {
    final String normalizedStatus =
    newStatus.trim();

    if (normalizedStatus.isEmpty ||
        normalizedStatus == status) {
      return;
    }

    status = normalizedStatus;
    notifyListeners();
  }

  void updateQueue({
    int? currentQueue,
    int? peopleAhead,
    int? estimatedMinutes,
    String? estimatedTime,
  }) {
    bool changed = false;

    if (currentQueue != null &&
        this.currentQueue != currentQueue) {
      this.currentQueue = currentQueue;
      changed = true;
    }

    if (peopleAhead != null &&
        this.peopleAhead != peopleAhead) {
      this.peopleAhead = peopleAhead;
      changed = true;
    }

    if (estimatedMinutes != null &&
        this.estimatedMinutes != estimatedMinutes) {
      this.estimatedMinutes = estimatedMinutes;
      changed = true;
    }

    final String normalizedEstimatedTime =
        estimatedTime?.trim() ?? '';

    if (normalizedEstimatedTime.isNotEmpty &&
        this.estimatedTime !=
            normalizedEstimatedTime) {
      this.estimatedTime =
          normalizedEstimatedTime;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  void updateToken({
    String? status,
    int? currentQueue,
    int? peopleAhead,
    int? estimatedMinutes,
    String? estimatedTime,
  }) {
    bool changed = false;

    final String normalizedStatus =
        status?.trim() ?? '';

    if (normalizedStatus.isNotEmpty &&
        this.status != normalizedStatus) {
      this.status = normalizedStatus;
      changed = true;
    }

    if (currentQueue != null &&
        this.currentQueue != currentQueue) {
      this.currentQueue = currentQueue;
      changed = true;
    }

    if (peopleAhead != null &&
        this.peopleAhead != peopleAhead) {
      this.peopleAhead = peopleAhead;
      changed = true;
    }

    if (estimatedMinutes != null &&
        this.estimatedMinutes != estimatedMinutes) {
      this.estimatedMinutes = estimatedMinutes;
      changed = true;
    }

    final String normalizedEstimatedTime =
        estimatedTime?.trim() ?? '';

    if (normalizedEstimatedTime.isNotEmpty &&
        this.estimatedTime !=
            normalizedEstimatedTime) {
      this.estimatedTime =
          normalizedEstimatedTime;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  void clearToken() {
    tokenId = null;
    tokenNumber = null;
    hospitalId = null;
    hospitalName = null;
    departmentId = null;
    departmentName = null;

    currentQueue = null;
    peopleAhead = null;
    estimatedMinutes = null;
    estimatedTime = null;
    issuedTime = null;

    status = 'Not Generated';

    notifyListeners();
  }
}