import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../models/transfer_task.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

class TransferProgressCard extends StatelessWidget {
  final TransferTask task;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  const TransferProgressCard({
    super.key,
    required this.task,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['mp4', 'mkv', 'avi', 'mov', 'webm'].contains(ext)) {
      return Icons.video_file_rounded;
    } else if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
      return Icons.image_rounded;
    } else if (['mp3', 'wav', 'aac', 'flac', 'm4a'].contains(ext)) {
      return Icons.audio_file_rounded;
    } else if (['apk', 'exe', 'dmg', 'deb', 'zip', 'tar', 'gz'].contains(ext)) {
      return Icons.archive_rounded;
    } else if (['pdf', 'doc', 'docx', 'txt'].contains(ext)) {
      return Icons.description_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  Color _getStatusColor(TransferStatus status) {
    switch (status) {
      case TransferStatus.transferring:
        return AppTheme.primaryCyan;
      case TransferStatus.completed:
        return AppTheme.accentGreen;
      case TransferStatus.paused:
        return AppTheme.accentYellow;
      case TransferStatus.failed:
      case TransferStatus.cancelled:
        return AppTheme.accentRose;
      case TransferStatus.offered:
      case TransferStatus.queued:
        return AppTheme.primaryViolet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TransferStatus.completed;
    final isPaused = task.status == TransferStatus.paused;
    final isTransferring = task.status == TransferStatus.transferring;

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: File Icon, Name, and Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getStatusColor(task.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(task.status).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getFileIcon(task.fileName),
                  color: _getStatusColor(task.status),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          task.direction == TransferDirection.sending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: AppTheme.textMuted,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${task.peerName} • ${task.peerIp}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(task.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getStatusColor(task.status).withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  task.status.name.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(task.status),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Progress Bar with neon glow
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: task.progress,
              minHeight: 8,
              backgroundColor: AppTheme.surfaceCard,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getStatusColor(task.status),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Metrics: Transferred / Size, Speed, ETA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${task.transferredFormatted} / ${task.sizeFormatted} (${(task.progress * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isTransferring)
                Row(
                  children: [
                    const Icon(
                      Icons.speed_rounded,
                      size: 13,
                      color: AppTheme.primaryCyan,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.speedFormatted,
                      style: const TextStyle(
                        color: AppTheme.primaryCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ETA: ${task.etaFormatted}',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // SHA-256 Checksum Status
          if (task.sha256 != null && task.sha256!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  task.isChecksumVerified == true
                      ? Icons.verified_rounded
                      : Icons.security_rounded,
                  size: 13,
                  color: task.isChecksumVerified == true
                      ? AppTheme.accentGreen
                      : AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.isChecksumVerified == true
                        ? 'SHA-256 Checksum Verified Integrity (Match)'
                        : 'SHA-256: ${task.sha256!.substring(0, math.min(16, task.sha256!.length))}...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: task.isChecksumVerified == true
                          ? AppTheme.accentGreen
                          : AppTheme.textMuted,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Control Actions (Pause, Resume, Open, Cancel)
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isTransferring)
                TextButton.icon(
                  onPressed: onPause,
                  icon: const Icon(Icons.pause_rounded, size: 16),
                  label: const Text('Pause'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accentYellow,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
              if (isPaused || task.status == TransferStatus.failed)
                ElevatedButton.icon(
                  onPressed: onResume,
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Resume (Offset)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryCyan.withOpacity(0.2),
                    foregroundColor: AppTheme.primaryCyan,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppTheme.primaryCyan, width: 1),
                    ),
                  ),
                ),
              if (isDone && task.direction == TransferDirection.receiving)
                ElevatedButton.icon(
                  onPressed: () {
                    OpenFilex.open(task.filePath);
                  },
                  icon: const Icon(Icons.file_open_rounded, size: 16),
                  label: const Text('Open File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen.withOpacity(0.2),
                    foregroundColor: AppTheme.accentGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppTheme.accentGreen, width: 1),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              if (!isDone)
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppTheme.accentRose,
                  tooltip: 'Cancel Transfer',
                ),
            ],
          ),
        ],
      ),
    );
  }
}
