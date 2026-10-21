import 'package:flutter/material.dart';
import '../models/transfer_task.dart';
import '../services/broadcast_engine.dart';
import '../services/p2p_socket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/transfer_progress_card.dart';

class TransfersScreen extends StatefulWidget {
  final P2PSocketService socketService;
  final BroadcastEngine broadcastEngine;

  const TransfersScreen({
    super.key,
    required this.socketService,
    required this.broadcastEngine,
  });

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
    // StreamBuilder connects directly to the byte stream from TCP socket
    return StreamBuilder<TransferTask>(
      stream: widget.socketService.transferStream,
      builder: (context, snapshot) {
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
            title: const Text('Transfer Queue'),
            actions: [
              IconButton(
                icon: const Icon(Icons.bolt_rounded, color: AppTheme.primaryCyan),
                tooltip: 'Isolate & Stream Architecture',
                onPressed: () => _showTechnicalMoatDialog(context),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryCyan,
              labelColor: AppTheme.primaryCyan,
              unselectedLabelColor: AppTheme.textMuted,
              tabs: [
                Tab(text: 'Active (${activeTransfers.length})'),
                Tab(text: 'Queue (${allTransfers.length})'),
                Tab(text: 'History (${completedTransfers.length})'),
              ],
            ),
          ),
          body: Column(
            children: [
              // 1-to-Many Classroom Broadcast banner if running
              AnimatedBuilder(
                animation: widget.broadcastEngine,
                builder: (context, _) {
                  final session = widget.broadcastEngine.currentSession;
                  if (session == null || !session.isBroadcasting) {
                    return const SizedBox.shrink();
                  }

                  return GlassContainer(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(14),
                    borderRadius: 16,
                    color: AppTheme.primaryViolet.withValues(alpha: 0.15),
                    border: Border.all(color: AppTheme.primaryViolet.withValues(alpha: 0.5)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.groups_rounded, color: AppTheme.primaryViolet, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Classroom Broadcast Active (${session.completedCount}/${session.peerStatuses.length} peers)',
                                  style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            Text(
                              '${session.overallSpeedMBps.toStringAsFixed(1)} MB/s',
                              style: const TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: session.overallProgress,
                            minHeight: 6,
                            backgroundColor: AppTheme.surfaceCard,
                            valueColor: const AlwaysStoppedAnimation(AppTheme.primaryViolet),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Streaming "${session.fileName}" to all peers simultaneously...',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Transfers Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(activeTransfers, 'No active transfers in progress'),
                    _buildList(allTransfers, 'Transfer queue is clean'),
                    _buildList(completedTransfers, 'No transfer history yet'),
                  ],
                ),
              ),
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
            Icon(Icons.swap_horizontal_circle_outlined, size: 56, color: AppTheme.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(emptyMessage, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
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

  void _showTechnicalMoatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.glassBorder)),
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: AppTheme.primaryCyan),
            SizedBox(width: 8),
            Text('StreamBuilder Pipeline', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
          ],
        ),
        content: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Zero UI Stutter with Streams:',
              style: TextStyle(color: AppTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 4),
            Text(
              'Each incoming TCP byte chunk is appended directly to disk. The UI renders via Dart StreamBuilder, listening directly to TCP throughput streams without main thread UI lockups or memory fragmentation.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryCyan, foregroundColor: Colors.black),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}
