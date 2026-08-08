import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ---- Appearance ----
          _sectionHeader(cs, 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle between dark and light theme'),
            secondary: Icon(Icons.dark_mode_outlined, color: cs.primary),
            value: settings.darkMode,
            onChanged: (v) => settings.setDarkMode(v),
          ),

          const Divider(),

          // ---- Notifications ----
          _sectionHeader(cs, 'Notifications'),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive alerts and updates'),
            secondary: Icon(Icons.notifications_outlined, color: cs.primary),
            value: settings.notifications,
            onChanged: (v) => settings.setNotifications(v),
          ),

          const Divider(),

          // ---- Home Sections ----
          _sectionHeader(cs, 'Home Feed Sections'),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Choose which sections appear on your home feed',
              style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
            ),
          ),
          _sectionToggle(cs, Icons.article_outlined, 'News', settings.showNews, (v) => settings.setShowNews(v)),
          _sectionToggle(cs, Icons.event_outlined, 'Events', settings.showEvents, (v) => settings.setShowEvents(v)),
          _sectionToggle(cs, Icons.store_outlined, 'Businesses', settings.showBusinesses, (v) => settings.setShowBusinesses(v)),
          _sectionToggle(cs, Icons.school_outlined, 'Schools', settings.showSchools, (v) => settings.setShowSchools(v)),
          _sectionToggle(cs, Icons.person_outlined, 'Freelancers', settings.showFreelancers, (v) => settings.setShowFreelancers(v)),
          _sectionToggle(cs, Icons.campaign_outlined, 'Alerts', settings.showAlerts, (v) => settings.setShowAlerts(v)),
          _sectionToggle(cs, Icons.account_balance_outlined, 'City Council', settings.showCouncil, (v) => settings.setShowCouncil(v)),

          const Divider(),

          // ---- About ----
          _sectionHeader(cs, 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('CalCity Community App'),
            subtitle: Text('Version 1.0.0'),
          ),
          ListTile(
            leading: Icon(Icons.location_on_outlined, color: cs.primary),
            title: const Text('California City, CA 93505'),
            subtitle: const Text('High Desert community hub'),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(ColorScheme cs, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _sectionToggle(ColorScheme cs, IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      secondary: Icon(icon, size: 22, color: value ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.5)),
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
