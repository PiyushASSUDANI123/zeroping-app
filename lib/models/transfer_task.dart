enum TransferDirection { sending, receiving }

enum TransferStatus {
  offered,
  queued,
  transferring,
  paused,
  completed,
  failed,
  cancelled,
}

class TransferTask {
  final String id;
  final String fileName;
  final int fileSize;
  final String filePath;
  final TransferDirection direction;
  final String peerName;
  final String peerIp;
  int transferredBytes;
  TransferStatus status;
  double speedBytesPerSec;
  String? sha256;
  bool? isChecksumVerified;
  String? errorMessage;
  final DateTime createdAt;
  DateTime? completedAt;

  TransferTask({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.filePath,
    required this.direction,
    required this.peerName,
    required this.peerIp,
    this.transferredBytes = 0,
    this.status = TransferStatus.queued,
    this.speedBytesPerSec = 0.0,
    this.sha256,
    this.isChecksumVerified,
    this.errorMessage,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress =>
      fileSize > 0 ? (transferredBytes / fileSize).clamp(0.0, 1.0) : 0.0;

  String get speedFormatted {
    if (speedBytesPerSec <= 0) return '0 KB/s';
    if (speedBytesPerSec >= 1024 * 1024) {
      return '${(speedBytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    return '${(speedBytesPerSec / 1024).toStringAsFixed(0)} KB/s';
  }

  String get etaFormatted {
    if (speedBytesPerSec <= 0 || status != TransferStatus.transferring) {
      return '--';
    }
    final remainingBytes = fileSize - transferredBytes;
    if (remainingBytes <= 0) return 'Done';
    final seconds = remainingBytes / speedBytesPerSec;
    if (seconds < 60) return '${seconds.ceil()}s';
    final minutes = (seconds / 60).floor();
    final remSecs = (seconds % 60).floor();
    return '${minutes}m ${remSecs}s';
  }

  String get sizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get transferredFormatted {
    if (transferredBytes < 1024) return '$transferredBytes B';
    if (transferredBytes < 1024 * 1024) {
      return '${(transferredBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (transferredBytes < 1024 * 1024 * 1024) {
      return '${(transferredBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(transferredBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'fileSize': fileSize,
        'filePath': filePath,
        'direction': direction.name,
        'peerName': peerName,
        'peerIp': peerIp,
        'transferredBytes': transferredBytes,
        'status': status.name,
        'sha256': sha256,
        'isChecksumVerified': isChecksumVerified,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory TransferTask.fromJson(Map<String, dynamic> json) {
    return TransferTask(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      filePath: json['filePath'] as String,
      direction: TransferDirection.values.firstWhere(
        (e) => e.name == json['direction'],
        orElse: () => TransferDirection.receiving,
      ),
      peerName: json['peerName'] as String,
      peerIp: json['peerIp'] as String,
      transferredBytes: (json['transferredBytes'] as num?)?.toInt() ?? 0,
      status: TransferStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransferStatus.paused,
      ),
      sha256: json['sha256'] as String?,
      isChecksumVerified: json['isChecksumVerified'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }
}
