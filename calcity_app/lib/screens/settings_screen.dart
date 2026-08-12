import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'contact_request_screen.dart';

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

          // Theme color picker
          ListTile(
            leading: Icon(Icons.palette_outlined, color: cs.primary),
            title: const Text('Theme Color'),
            subtitle: Text('Current: ${settings.accentColor.toUpperCase()}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showColorPicker(context, settings),
          ),

          // Font size slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_size, size: 20),
                    const SizedBox(width: 8),
                    Text('Font Size',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: cs.onSurface)),
                    const Spacer(),
                    Text(
                      settings.fontScale <= 0.95
                          ? 'Small'
                          : settings.fontScale >= 1.25
                              ? 'Large'
                              : 'Medium',
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.primary,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Slider(
                  value: settings.fontScale,
                  min: 0.85,
                  max: 1.5,
                  divisions: 6,
                  label: '${settings.fontScale.toStringAsFixed(2)}x',
                  onChanged: (v) => settings.setFontScale(v),
                ),
              ],
            ),
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
          _sectionToggle(cs, Icons.article_outlined, 'News', settings.showNews,
              (v) => settings.setShowNews(v)),
          _sectionToggle(cs, Icons.event_outlined, 'Events',
              settings.showEvents, (v) => settings.setShowEvents(v)),
          _sectionToggle(cs, Icons.store_outlined, 'Businesses',
              settings.showBusinesses, (v) => settings.setShowBusinesses(v)),
          _sectionToggle(cs, Icons.school_outlined, 'Schools',
              settings.showSchools, (v) => settings.setShowSchools(v)),
          _sectionToggle(cs, Icons.person_outlined, 'Freelancers',
              settings.showFreelancers, (v) => settings.setShowFreelancers(v)),
          _sectionToggle(cs, Icons.campaign_outlined, 'Alerts',
              settings.showAlerts, (v) => settings.setShowAlerts(v)),
          _sectionToggle(cs, Icons.account_balance_outlined, 'City Council',
              settings.showCouncil, (v) => settings.setShowCouncil(v)),

          const Divider(),

          // ---- Help & Requests ----
          _sectionHeader(cs, 'Help & Requests'),
          ListTile(
            leading: Icon(Icons.bug_report_outlined, color: cs.primary),
            title: const Text('Report a Bug'),
            subtitle: const Text('Something broken? Let us know'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openRequest(context, 'Report a Bug', 'bug',
                'Describe the problem: what you were doing, what happened, and what you expected.'),
          ),
          ListTile(
            leading: Icon(Icons.edit_note_outlined, color: cs.primary),
            title: const Text('Request Info Removal / Update'),
            subtitle: const Text('Correct or remove outdated information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openRequest(
                context,
                'Info Removal / Update',
                'info_update',
                'Tell us what information should be removed or updated and why.'),
          ),
          ListTile(
            leading: Icon(Icons.storefront_outlined, color: cs.primary),
            title: const Text('Business Promotion'),
            subtitle: const Text('Feature your business in the app'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openRequest(
                context,
                'Business Promotion',
                'business_promo',
                "Tell us about your business and what you'd like to promote. Include a name and phone or email."),
          ),
          ListTile(
            leading: Icon(Icons.person_add_alt_outlined, color: cs.primary),
            title: const Text('Freelancer Promotion'),
            subtitle: const Text('Get listed as a freelancer'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openRequest(
                context,
                'Freelancer Promotion',
                'freelancer_promo',
                'Tell us about your services and how customers can reach you.'),
          ),

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

  void _showColorPicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose Theme Color',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(ctx).colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text('The app updates instantly',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final entry in SettingsProvider.accentColors.entries)
                  GestureDetector(
                    onTap: () {
                      settings.setAccentColor(entry.key);
                      Navigator.pop(ctx);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: entry.value,
                            shape: BoxShape.circle,
                            border: settings.accentColor == entry.key
                                ? Border.all(
                                    color: Theme.of(ctx).colorScheme.onSurface,
                                    width: 3)
                                : null,
                          ),
                          child: settings.accentColor == entry.key
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                            entry.key[0].toUpperCase() + entry.key.substring(1),
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _openRequest(
      BuildContext context, String title, String category, String hint) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContactRequestScreen(
              title: title, category: category, hint: hint),
        ));
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

  Widget _sectionToggle(ColorScheme cs, IconData icon, String label, bool value,
      ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      secondary: Icon(icon,
          size: 22,
          color:
              value ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.5)),
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
