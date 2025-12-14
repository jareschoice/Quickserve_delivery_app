// ===============================
// Settings Screen
// Dark Mode, Language, Notifications
// ===============================
import 'package:flutter/material.dart';
import '../../config/app_localization.dart';
import '../../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.settings), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _buildSectionHeader('Appearance'),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.dark_mode,
            title: strings.darkMode,
            subtitle: isDark ? 'Dark theme enabled' : 'Light theme enabled',
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
              },
              activeTrackColor: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.language,
            title: strings.language,
            subtitle:
                AppLocales.localeNames[localeProvider.languageCode] ??
                'English',
            onTap: () => _showLanguageDialog(),
          ),

          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.notifications,
            title: strings.notifications,
            subtitle: _notificationsEnabled ? 'Enabled' : 'Disabled',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
              activeTrackColor: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.notifications_active,
            title: 'Order Updates',
            subtitle: 'Get notified about order status changes',
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeTrackColor: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.local_offer,
            title: 'Promotions',
            subtitle: 'Receive promotional offers and discounts',
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeTrackColor: Theme.of(context).primaryColor,
            ),
          ),

          const SizedBox(height: 24),

          // Support Section
          _buildSectionHeader('Support'),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.help_outline,
            title: strings.help,
            subtitle: 'FAQs, Contact support',
            onTap: () => Navigator.pushNamed(context, '/support'),
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.info_outline,
            title: strings.about,
            subtitle: 'Version 1.0.0',
            onTap: () => _showAboutDialog(),
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Read our terms of service',
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // Cache Section
          _buildSectionHeader('Data'),
          const SizedBox(height: 8),
          _buildSettingCard(
            icon: Icons.cached,
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            onTap: () => _clearCache(),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).primaryColor,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing:
            trailing ??
            (onTap != null ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLocales.supportedLocales.map((locale) {
            final isSelected =
                locale.languageCode == localeProvider.languageCode;
            return ListTile(
              title: Text(
                AppLocales.localeNames[locale.languageCode] ??
                    locale.languageCode,
              ),
              trailing: isSelected
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () {
                localeProvider.setLocale(locale);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'QuickServe',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          color: Color(0xFFFFD700),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text(
          'Q',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6B00),
          ),
        ),
      ),
      children: [
        const Text(
          'QuickServe is your go-to food delivery app. '
          'Order from your favorite restaurants and get food delivered to your doorstep.',
        ),
        const SizedBox(height: 16),
        const Text('© 2024 QuickServe. All rights reserved.'),
      ],
    );
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text(
          'This will remove all cached data. You may need to reload content.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Clear cache logic here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared successfully')),
      );
    }
  }
}
