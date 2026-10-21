import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AvatarItem {
  final String id;
  final String assetPath;
  final String label;

  const AvatarItem({
    required this.id,
    required this.assetPath,
    required this.label,
  });
}

class AppAvatar extends StatelessWidget {
  final String avatar;
  final double size;
  final bool showBorder;
  final Border? customBorder;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    required this.avatar,
    this.size = 40,
    this.showBorder = true,
    this.customBorder,
    this.onTap,
  });

  static const List<AvatarItem> defaultAvatars = [
    AvatarItem(
      id: 'assets/avatars/avatar_1.png',
      assetPath: 'assets/avatars/avatar_1.png',
      label: 'Developer',
    ),
    AvatarItem(
      id: 'assets/avatars/avatar_2.png',
      assetPath: 'assets/avatars/avatar_2.png',
      label: 'Creator',
    ),
    AvatarItem(
      id: 'assets/avatars/avatar_3.png',
      assetPath: 'assets/avatars/avatar_3.png',
      label: 'Cosmonaut',
    ),
    AvatarItem(
      id: 'assets/avatars/avatar_4.png',
      assetPath: 'assets/avatars/avatar_4.png',
      label: 'Cyber Stealth',
    ),
    AvatarItem(
      id: 'assets/avatars/avatar_5.png',
      assetPath: 'assets/avatars/avatar_5.png',
      label: 'Quantum Bot',
    ),
    AvatarItem(
      id: 'assets/avatars/avatar_6.png',
      assetPath: 'assets/avatars/avatar_6.png',
      label: 'Cyber Fox',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    Widget content;

    final isAsset = avatar.startsWith('assets/');

    if (isAsset) {
      content = ClipOval(
        child: Image.asset(
          avatar,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackEmoji(context),
        ),
      );
    } else {
      content = _fallbackEmoji(context);
    }

    Widget container = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: customBorder ??
            (showBorder
                ? Border.all(color: AppTheme.glassBorder, width: 1.2)
                : null),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: content,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }

    return container;
  }

  Widget _fallbackEmoji(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryCyan.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Text(
          avatar.isNotEmpty ? avatar : '⚡',
          style: TextStyle(fontSize: size * 0.45),
        ),
      ),
    );
  }
}
