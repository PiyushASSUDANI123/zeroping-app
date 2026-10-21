import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
import '../widgets/glass_container.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Piyush');
  final TextEditingController _usernameController = TextEditingController(text: '@piyush');
  final TextEditingController _taglineController = TextEditingController(text: 'Zero Latency • Ready to Share');

  String _selectedAvatar = AppAvatar.defaultAvatars[0].id;
  final List<AvatarItem> _avatars = AppAvatar.defaultAvatars;

  bool _isSaving = false;

  void _submit() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final tagline = _taglineController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.accentRose,
          content: Text('Please enter your name'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final profile = UserProfile(
      name: name,
      username: username.isEmpty ? '@$name' : username,
      avatar: _selectedAvatar,
      tagline: tagline.isEmpty ? 'Ready to share' : tagline,
    );

    await StorageService.saveUserProfile(profile);
    setState(() => _isSaving = false);

    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo with soft shadow
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x122563EB),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: AppTheme.glassBorder, width: 1.2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                        ),
                        child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 48),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'ZeroPing',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Zero Server • Zero Latency • Pure Sockets',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Login / Profile Setup Card
                  GlassContainer(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Setup Node Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Stored 100% locally on this device. No cloud accounts needed.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textMuted,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Avatar Picker
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Choose Node Persona',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              _avatars.firstWhere((a) => a.id == _selectedAvatar, orElse: () => _avatars[0]).label,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryCyan,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 64,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _avatars.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final item = _avatars[index];
                              final isSelected = item.id == _selectedAvatar;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedAvatar = item.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? AppTheme.primaryCyan : Colors.transparent,
                                      width: 2.2,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primaryCyan.withValues(alpha: 0.35),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: AppAvatar(
                                    avatar: item.assetPath,
                                    size: 54,
                                    showBorder: !isSelected,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Full Name
                        const Text(
                          'Your Display Name',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'e.g. Piyush',
                            hintStyle: const TextStyle(color: AppTheme.textMuted),
                            filled: true,
                            fillColor: AppTheme.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.glassBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.glassBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primaryCyan, width: 1.5),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Username Handle
                        const Text(
                          'Node Handle',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _usernameController,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontFamily: 'monospace'),
                          decoration: InputDecoration(
                            hintText: 'e.g. @piyush',
                            hintStyle: const TextStyle(color: AppTheme.textMuted),
                            filled: true,
                            fillColor: AppTheme.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.glassBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.glassBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primaryCyan, width: 1.5),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Status Tagline
                        const Text(
                          'Node Status',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _taglineController,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'e.g. Ready to share',
                            hintStyle: const TextStyle(color: AppTheme.textMuted),
                            filled: true,
                            fillColor: AppTheme.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.glassBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.glassBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.primaryCyan, width: 1.5),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Get Started Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryCyan,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Save & Launch ZeroPing',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded, size: 18),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Privacy Notice
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 13, color: AppTheme.accentGreen),
                      SizedBox(width: 6),
                      Text(
                        '100% Offline • No data leaves your local network',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
