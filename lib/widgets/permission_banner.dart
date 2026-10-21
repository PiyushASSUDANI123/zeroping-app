import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

class PermissionBanner extends StatefulWidget {
  final VoidCallback? onPermissionsChanged;

  const PermissionBanner({super.key, this.onPermissionsChanged});

  @override
  State<PermissionBanner> createState() => _PermissionBannerState();
}

class _PermissionBannerState extends State<PermissionBanner> {
  PermissionStatusReport? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final report = await PermissionService.checkPermissions();
    if (mounted) {
      setState(() {
        _report = report;
        _isLoading = false;
      });
      widget.onPermissionsChanged?.call();
    }
  }

  Future<void> _request() async {
    setState(() => _isLoading = true);
    final report = await PermissionService.requestAllPermissions();
    if (mounted) {
      setState(() {
        _report = report;
        _isLoading = false;
      });
      widget.onPermissionsChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !Platform.isAndroid || _isLoading || (_report != null && _report!.isAllGranted)) {
      return const SizedBox.shrink();
    }

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      color: AppTheme.accentYellow.withValues(alpha: 0.08),
      border: Border.all(color: AppTheme.accentYellow.withValues(alpha: 0.4), width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.accentYellow, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Android 12+ Permissions Required',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _request,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentYellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Grant All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Without Nearby Wi-Fi Devices, Bluetooth Scan, and Storage, UDP broadcast discovery and TCP chunk transfers will be blocked by Android OS.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _permChip('Nearby Wi-Fi', _report?.nearbyWifi ?? false),
              _permChip('Bluetooth Scan', _report?.bluetooth ?? false),
              _permChip('Storage Access', _report?.storage ?? false),
              _permChip('Location (Wi-Fi P2P)', _report?.location ?? false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _permChip(String title, bool granted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: granted ? AppTheme.accentGreen.withValues(alpha: 0.15) : AppTheme.accentRose.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: granted ? AppTheme.accentGreen.withValues(alpha: 0.4) : AppTheme.accentRose.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            granted ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 11,
            color: granted ? AppTheme.accentGreen : AppTheme.accentRose,
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: granted ? AppTheme.accentGreen : AppTheme.accentRose,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
