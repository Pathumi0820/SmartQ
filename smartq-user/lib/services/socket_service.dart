import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart'
as io;

class SocketService {
  SocketService._internal();

  static final SocketService instance =
  SocketService._internal();

  static const String _socketUrl =
      'http://192.168.8.124:5000';

  io.Socket? _socket;

  String? _currentTokenId;
  String? _currentDepartmentId;

  bool get isConnected =>
      _socket?.connected ?? false;

  String? get socketId => _socket?.id;

  void connect({
    required void Function(
        Map<String, dynamic> data,
        ) onTokenUpdated,
    void Function(
        Map<String, dynamic> data,
        )? onQueueUpdated,
    void Function(
        Map<String, dynamic> data,
        )? onTokenDeleted,
    void Function(
        Map<String, dynamic> data,
        )? onNotificationReceived,
  }) {
    if (_socket != null) {
      _registerDataListeners(
        onTokenUpdated: onTokenUpdated,
        onQueueUpdated: onQueueUpdated,
        onTokenDeleted: onTokenDeleted,
        onNotificationReceived:
        onNotificationReceived,
      );

      if (!_socket!.connected) {
        _socket!.connect();
      }

      return;
    }

    _socket = io.io(
      _socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .setTimeout(10000)
          .build(),
    );

    _registerConnectionListeners();

    _registerDataListeners(
      onTokenUpdated: onTokenUpdated,
      onQueueUpdated: onQueueUpdated,
      onTokenDeleted: onTokenDeleted,
      onNotificationReceived:
      onNotificationReceived,
    );

    _socket!.connect();
  }

  void _registerConnectionListeners() {
    final io.Socket? socket = _socket;

    if (socket == null) return;

    socket.onConnect((_) {
      debugPrint(
        'Socket connected: ${socket.id}',
      );

      final String? tokenId =
          _currentTokenId;

      final String? departmentId =
          _currentDepartmentId;

      if (tokenId != null &&
          tokenId.isNotEmpty) {
        socket.emit(
          'joinTokenRoom',
          tokenId,
        );

        debugPrint(
          'Rejoining token room: '
              'token:$tokenId',
        );
      }

      if (departmentId != null &&
          departmentId.isNotEmpty) {
        socket.emit(
          'joinDepartmentRoom',
          departmentId,
        );

        debugPrint(
          'Rejoining department room: '
              'department:$departmentId',
        );
      }
    });

    socket.onConnectError((error) {
      debugPrint(
        'Socket connection error: $error',
      );
    });

    socket.onError((error) {
      debugPrint(
        'Socket error: $error',
      );
    });

    socket.onDisconnect((reason) {
      debugPrint(
        'Socket disconnected: $reason',
      );
    });

    socket.onReconnect((attempt) {
      debugPrint(
        'Socket reconnected after attempt: '
            '$attempt',
      );
    });

    socket.onReconnectAttempt((attempt) {
      debugPrint(
        'Socket reconnect attempt: $attempt',
      );
    });

    socket.on(
      'tokenRoomJoined',
          (data) {
        debugPrint(
          'Token room joined: $data',
        );
      },
    );

    socket.on(
      'departmentRoomJoined',
          (data) {
        debugPrint(
          'Department room joined: $data',
        );
      },
    );

    socket.on(
      'socketError',
          (data) {
        debugPrint(
          'Backend socket error: $data',
        );
      },
    );
  }

  void _registerDataListeners({
    required void Function(
        Map<String, dynamic> data,
        ) onTokenUpdated,
    void Function(
        Map<String, dynamic> data,
        )? onQueueUpdated,
    void Function(
        Map<String, dynamic> data,
        )? onTokenDeleted,
    void Function(
        Map<String, dynamic> data,
        )? onNotificationReceived,
  }) {
    final io.Socket? socket = _socket;

    if (socket == null) return;

    socket.off('tokenUpdated');
    socket.off('queueUpdated');
    socket.off('tokenDeleted');
    socket.off('notification');

    socket.on(
      'tokenUpdated',
          (data) {
        debugPrint(
          'tokenUpdated received: $data',
        );

        final Map<String, dynamic>? update =
        _convertToMap(data);

        if (update == null) {
          debugPrint(
            'Invalid tokenUpdated payload',
          );
          return;
        }

        debugPrint(
          'Updated token ID: '
              '${update['tokenId']}',
        );

        debugPrint(
          'Updated token status: '
              '${update['status']}',
        );

        onTokenUpdated(update);
      },
    );

    socket.on(
      'queueUpdated',
          (data) {
        debugPrint(
          'queueUpdated received: $data',
        );

        final Map<String, dynamic>? update =
        _convertToMap(data);

        if (update == null) return;

        onQueueUpdated?.call(update);
      },
    );

    socket.on(
      'tokenDeleted',
          (data) {
        debugPrint(
          'tokenDeleted received: $data',
        );

        final Map<String, dynamic>? update =
        _convertToMap(data);

        if (update == null) return;

        onTokenDeleted?.call(update);
      },
    );

    socket.on(
      'notification',
          (data) {
        debugPrint(
          'Notification received: $data',
        );

        final Map<String, dynamic>?
        notification =
        _convertToMap(data);

        if (notification == null) {
          debugPrint(
            'Invalid notification payload',
          );
          return;
        }

        onNotificationReceived?.call(
          notification,
        );
      },
    );
  }

  void joinTokenRoom(String tokenId) {
    final String normalizedId =
    tokenId.trim();

    if (normalizedId.isEmpty) {
      debugPrint(
        'Cannot join token room: '
            'token ID is empty',
      );
      return;
    }

    if (_currentTokenId != null &&
        _currentTokenId != normalizedId) {
      leaveTokenRoom(
        _currentTokenId!,
      );
    }

    _currentTokenId = normalizedId;

    if (!isConnected) {
      debugPrint(
        'Token room saved; it will be '
            'joined after socket connection',
      );
      return;
    }

    _socket!.emit(
      'joinTokenRoom',
      normalizedId,
    );

    debugPrint(
      'Joining token room: '
          'token:$normalizedId',
    );
  }

  void leaveTokenRoom([
    String? tokenId,
  ]) {
    final String? normalizedId =
    (tokenId ?? _currentTokenId)
        ?.trim();

    if (normalizedId == null ||
        normalizedId.isEmpty) {
      return;
    }

    if (isConnected) {
      _socket!.emit(
        'leaveTokenRoom',
        normalizedId,
      );
    }

    if (_currentTokenId ==
        normalizedId) {
      _currentTokenId = null;
    }

    debugPrint(
      'Leaving token room: '
          'token:$normalizedId',
    );
  }

  void joinDepartmentRoom(
      String departmentId,
      ) {
    final String normalizedId =
    departmentId.trim();

    if (normalizedId.isEmpty) {
      debugPrint(
        'Cannot join department room: '
            'department ID is empty',
      );
      return;
    }

    if (_currentDepartmentId != null &&
        _currentDepartmentId !=
            normalizedId) {
      leaveDepartmentRoom(
        _currentDepartmentId!,
      );
    }

    _currentDepartmentId =
        normalizedId;

    if (!isConnected) {
      debugPrint(
        'Department room saved; it will '
            'be joined after connection',
      );
      return;
    }

    _socket!.emit(
      'joinDepartmentRoom',
      normalizedId,
    );

    debugPrint(
      'Joining department room: '
          'department:$normalizedId',
    );
  }

  void leaveDepartmentRoom([
    String? departmentId,
  ]) {
    final String? normalizedId =
    (departmentId ??
        _currentDepartmentId)
        ?.trim();

    if (normalizedId == null ||
        normalizedId.isEmpty) {
      return;
    }

    if (isConnected) {
      _socket!.emit(
        'leaveDepartmentRoom',
        normalizedId,
      );
    }

    if (_currentDepartmentId ==
        normalizedId) {
      _currentDepartmentId = null;
    }

    debugPrint(
      'Leaving department room: '
          'department:$normalizedId',
    );
  }

  Map<String, dynamic>? _convertToMap(
      dynamic data,
      ) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(
        data,
      );
    }

    return null;
  }

  void disconnect() {
    final io.Socket? socket = _socket;

    if (socket == null) return;

    socket.off('tokenUpdated');
    socket.off('queueUpdated');
    socket.off('tokenDeleted');
    socket.off('notification');
    socket.off('tokenRoomJoined');
    socket.off('departmentRoomJoined');
    socket.off('socketError');

    socket.disconnect();
    socket.dispose();

    _socket = null;
    _currentTokenId = null;
    _currentDepartmentId = null;

    debugPrint(
      'Socket service disposed',
    );
  }
}