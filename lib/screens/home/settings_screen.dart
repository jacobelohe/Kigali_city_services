import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppConstants.accentColor,
                        child: Text(
                          (userProfile.name.isNotEmpty
                              ? userProfile.name[0].toUpperCase()
                              : '?'),
                          style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _editName(context, ref, userProfile.name),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppConstants.accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppConstants.scaffoldBg, width: 2),
                            ),
                            child: const Icon(Icons.edit,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userProfile.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  userProfile.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppConstants.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Member since ${AppUtils.formatDate(userProfile.createdAt)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppConstants.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 32),

                // Stats row
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(
                          icon: Icons.bookmark,
                          value: '${userProfile.bookmarks.length}',
                          label: 'Bookmarks'),
                      const VerticalDivider(
                          color: AppConstants.surfaceColor, width: 1),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Settings tiles
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Edit Name',
                  onTap: () => _editName(context, ref, userProfile.name),
                ),
                _SettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () async {
                    await ref
                        .read(authServiceProvider)
                        .sendPasswordReset(userProfile.email);
                    if (context.mounted) {
                      AppUtils.showSnackBar(
                          context, 'Password reset email sent');
                    }
                  },
                ),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: AppConstants.appName,
                    applicationVersion: AppConstants.appVersion,
                    applicationLegalese: '© 2025 Kigali City Services',
                  ),
                ),
                const Divider(color: AppConstants.surfaceColor, height: 32),
                _SettingsTile(
                  icon: Icons.logout,
                  title: 'Sign Out',
                  color: AppConstants.errorColor,
                  onTap: () async {
                    final confirm = await AppUtils.showConfirmDialog(
                      context,
                      title: 'Sign Out',
                      message: 'Are you sure you want to sign out?',
                      confirmText: 'Sign Out',
                    );
                    if (confirm == true && context.mounted) {
                      await ref
                          .read(authNotifierProvider.notifier)
                          .signOut();
                    }
                  },
                ),
              ],
            ),
    );
  }

  void _editName(BuildContext context, WidgetRef ref, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Full Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(authNotifierProvider.notifier)
                  .updateName(ctrl.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx);
                AppUtils.showSnackBar(context, 'Name updated!');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppConstants.textPrimary;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: c, size: 22),
      ),
      title: Text(title, style: TextStyle(color: c, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 14, color: AppConstants.textSecondary),
      onTap: onTap,
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppConstants.accentColor, size: 24),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: AppConstants.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(
                color: AppConstants.textSecondary, fontSize: 12)),
      ],
    );
  }
}
