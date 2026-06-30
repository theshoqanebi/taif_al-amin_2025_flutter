enum BackupStatus { initial, working, success, error }

/// Which operation produced the current state — lets the UI show a spinner on
/// the right button and tailor the success/error wording.
enum BackupOperation { none, backup, restore }

class BackupState {
  final BackupStatus status;
  final BackupOperation operation;

  /// Last backup destination / restored source path, for the success message.
  final String? path;
  final String? message;
  final String? error;

  const BackupState({
    this.status = BackupStatus.initial,
    this.operation = BackupOperation.none,
    this.path,
    this.message,
    this.error,
  });

  BackupState copyWith({
    BackupStatus? status,
    BackupOperation? operation,
    String? path,
    String? message,
    String? error,
  }) => BackupState(
    status: status ?? this.status,
    operation: operation ?? this.operation,
    path: path ?? this.path,
    message: message ?? this.message,
    error: error ?? this.error,
  );

  bool get isWorking => status == BackupStatus.working;
  bool get isBackingUp =>
      isWorking && operation == BackupOperation.backup;
  bool get isRestoring =>
      isWorking && operation == BackupOperation.restore;
  bool get isSuccess => status == BackupStatus.success;
  bool get hasError => status == BackupStatus.error;
}