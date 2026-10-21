import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/peer_device.dart';
import '../theme/app_theme.dart';

class RadarScanner extends StatefulWidget {
  final List<PeerDevice> peers;
  final bool isScanning;
  final Function(PeerDevice) onPeerTap;
  final String localDeviceName;

  const RadarScanner({
    super.key,
    required this.peers,
    required this.isScanning,
    required this.onPeerTap,
    required this.localDeviceName,
  });

  @override
  State<RadarScanner> createState() => _RadarScannerState();
}

class _RadarScannerState extends State<RadarScanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    if (widget.isScanning) {
      _sweepController.repeat();
    }
  }

  @override
  void didUpdateWidget(RadarScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _sweepController.repeat();
      } else {
        _sweepController.stop();
      }
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final radius = size / 2;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Radar Background & Sweep Beam
              AnimatedBuilder(
                animation: _sweepController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(size, size),
                    painter: _RadarPainter(
                      sweepAngle: _sweepController.value * 2 * math.pi,
                      isScanning: widget.isScanning,
                    ),
                  );
                },
              ),

              // Center Local Device Indicator
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryCyan.withValues(alpha: 0.35),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.wifi_tethering_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.glassBorder, width: 1),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      widget.localDeviceName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              // Discovered Peer Nodes placed around the radar
              ..._buildPeerNodes(radius),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildPeerNodes(double radarRadius) {
    final List<Widget> nodes = [];
    final count = widget.peers.length;
    if (count == 0) return nodes;

    for (int i = 0; i < count; i++) {
      final peer = widget.peers[i];
      final angle = (2 * math.pi / count) * i - (math.pi / 2);
      final dist = (radarRadius * 0.52) + ((i % 3) * (radarRadius * 0.14));

      final x = dist * math.cos(angle);
      final y = dist * math.sin(angle);

      nodes.add(
        Transform.translate(
          offset: Offset(x, y),
          child: _PeerNodeWidget(
            peer: peer,
            onTap: () => widget.onPeerTap(peer),
          ),
        ),
      );
    }

    return nodes;
  }
}

class _PeerNodeWidget extends StatelessWidget {
  final PeerDevice peer;
  final VoidCallback onTap;

  const _PeerNodeWidget({
    required this.peer,
    required this.onTap,
  });

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.android:
        return Icons.phone_android_rounded;
      case DeviceType.windows:
        return Icons.desktop_windows_rounded;
      case DeviceType.macos:
        return Icons.laptop_mac_rounded;
      case DeviceType.linux:
        return Icons.computer_rounded;
      case DeviceType.ios:
        return Icons.phone_iphone_rounded;
      case DeviceType.unknown:
        return Icons.devices_other_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: AppTheme.primaryCyan,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              _getDeviceIcon(peer.deviceType),
              color: AppTheme.primaryCyan,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.glassBorder,
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x08000000), blurRadius: 6),
              ],
            ),
            child: Text(
              peer.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double sweepAngle;
  final bool isScanning;

  _RadarPainter({required this.sweepAngle, required this.isScanning});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final ringPaint = Paint()
      ..color = AppTheme.primaryCyan.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, radius * 0.35, ringPaint);
    canvas.drawCircle(center, radius * 0.65, ringPaint);
    canvas.drawCircle(center, radius * 0.95, ringPaint);

    final axisPaint = Paint()
      ..color = AppTheme.glassBorder
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.95),
      Offset(center.dx, center.dy + radius * 0.95),
      axisPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.95, center.dy),
      Offset(center.dx + radius * 0.95, center.dy),
      axisPaint,
    );

    if (isScanning) {
      final sweepPaint = Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: 0.0,
          endAngle: math.pi / 2,
          colors: [
            Colors.transparent,
            AppTheme.primaryCyan.withValues(alpha: 0.15),
          ],
          transform: GradientRotation(sweepAngle - math.pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius * 0.95));

      canvas.drawCircle(center, radius * 0.95, sweepPaint);

      final beamLinePaint = Paint()
        ..color = AppTheme.primaryCyan.withValues(alpha: 0.6)
        ..strokeWidth = 1.5;

      final lineX = center.dx + (radius * 0.95) * math.cos(sweepAngle);
      final lineY = center.dy + (radius * 0.95) * math.sin(sweepAngle);

      canvas.drawLine(center, Offset(lineX, lineY), beamLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle || oldDelegate.isScanning != isScanning;
  }
}
