class FileMetadata {
  final String id;
  final String fileName;
  final int fileSize;
  final String fileType;
  final String sha256;
  final int chunkSize;
  final int startByte;

  FileMetadata({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    this.sha256 = '',
    this.chunkSize = 1024 * 512, // 512 KB standard chunk size
    this.startByte = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'fileSize': fileSize,
        'fileType': fileType,
        'sha256': sha256,
        'chunkSize': chunkSize,
        'startByte': startByte,
      };

  factory FileMetadata.fromJson(Map<String, dynamic> json) {
    return FileMetadata(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? 'unknown_file',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      fileType: json['fileType'] as String? ?? 'application/octet-stream',
      sha256: json['sha256'] as String? ?? '',
      chunkSize: (json['chunkSize'] as num?)?.toInt() ?? 1024 * 512,
      startByte: (json['startByte'] as num?)?.toInt() ?? 0,
    );
  }
}
