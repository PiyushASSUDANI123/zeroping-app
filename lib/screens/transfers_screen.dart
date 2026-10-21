import 'package:flutter/material.dart';
import '../models/transfer_task.dart';
import '../services/p2p_socket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/transfer_progress_card.dart';

class TransfersScreen extends StatefulWidget {
  final P2PSocketService socketService;

  const TransfersScreen({super.key, required this.socketService});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.socketService,
      builder: (context, _) {
        final allTransfers = widget.socketService.activeTransfers.reversed.toList();
        final activeTransfers = allTransfers
            .where((t) =>
                t.status == TransferStatus.transferring ||
                t.status == TransferStatus.paused ||
                t.status == TransferStatus.offered ||
                t.status == TransferStatus.queued)
            .toList();
        final completedTransfers = allTransfers
            .where((t) =>
                t.status == TransferStatus.completed ||
                t.status == TransferStatus.failed ||
                t.status == TransferStatus.cancelled)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Transfer Hub'),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
                tooltip: 'Chunk & Resume Engine Info',
                onPressed: () => _showResumeInfoDialog(context),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryCyan,
              labelColor: AppTheme.primaryCyan,
              unselectedLabelColor: AppTheme.textMuted,
              tabs: [
                Tab(text: 'All (${allTransfers.length})'),
                Tab(text: 'Active (${activeTransfers.length})'),
                Tab(text: 'Completed (${completedTransfers.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildList(allTransfers, 'No transfer history yet'),
              _buildList(activeTransfers, 'No active transfers right now'),
              _buildList(completedTransfers, 'No completed transfers yet'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(List<TransferTask> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_horizontal_circle_outlined,
              size: 56,
              color: AppTheme.textMuted.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final task = list[index];
        return TransferProgressCard(
          task: task,
          onPause: () => widget.socketService.pauseTransfer(task.id),
          onResume: () => widget.socketService.resumeTransfer(task.id),
          onCancel: () => widget.socketService.cancelTransfer(task.id),
        );
      },
    );
  }

  void _showResumeInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.glassBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: AppTheme.primaryCyan),
            SizedBox(width: 8),
            Text('ZeroPing Technical Moat', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Chunking & Zero RAM Bloat',
                style: TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'Files are split into 512 KB chunks and pushed over raw TCP binary streams. Receiver writes chunks directly to disk via RandomAccessFile, preserving RAM even on 10 GB+ files.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              SizedBox(height: 12),
              Text(
                '2. Checksum & SHA-256 Verification',
                style: TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'Before and after transfer, SHA-256 hash is computed in background streams to guarantee zero packet corruption.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              SizedBox(height: 12),
              Text(
                '3. Byte-Level Resume Logic',
                style: TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'If connection drops, the receiver stores exact downloaded byte length. Upon reconnection, receiver specifies "startByte: N", and sender seeks directly to that offset. No re-downloading from 0%!',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryCyan,
              foregroundColor: Colors.black,
            ),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}
