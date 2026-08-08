import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/content_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentProvider>().fetchAlerts();
    });
  }

  Color _color(String sev) {
    switch (sev.toLowerCase()) {
      case 'emergency': return Colors.red;
      case 'warning': return Colors.amber.shade700;
      case 'info': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _emoji(String sev) {
    switch (sev.toLowerCase()) {
      case 'emergency': return '🚨';
      case 'warning': return '⚠️';
      default: return 'ℹ️';
    }
  }

  @override
  Widget build(BuildContext c) {
    final theme = Theme.of(c);
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 Alerts & Notices'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ContentProvider>(builder: (ctx, prov, _) {
        if (prov.isLoadingAlerts && prov.alerts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (prov.alerts.isEmpty) {
          return RefreshIndicator(
            onRefresh: prov.fetchAlerts,
            child: ListView(children: [
              SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.4,
                child: const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('✅', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text('No current alerts', style: TextStyle(fontSize: 16, color: Colors.black54)),
                    SizedBox(height: 6),
                    Text('Everything looks good! 🎉', style: TextStyle(fontSize: 13, color: Colors.black38)),
                  ]),
                ),
              ),
            ]),
          );
        }
        return RefreshIndicator(
          onRefresh: prov.fetchAlerts,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: prov.alerts.length,
            itemBuilder: (_, i) {
              final a = prov.alerts[i];
              final col = _color(a.severity);
              final dateStr = DateFormat('MMM d, yyyy').format(a.createdAt);
              final isEmerg = a.severity.toLowerCase() == 'emergency';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Card(
                  elevation: isEmerg ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: col.withValues(alpha: 0.3), width: isEmerg ? 2 : 1),
                  ),
                  child: ExpansionTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: col.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text(_emoji(a.severity), style: const TextStyle(fontSize: 20))),
                    ),
                    title: Text(a.title, style: TextStyle(fontWeight: isEmerg ? FontWeight.w700 : FontWeight.w600, fontSize: 15)),
                    subtitle: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: col.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text(a.severity.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: col, letterSpacing: 0.5)),
                      ),
                      const SizedBox(width: 8),
                      Text(dateStr, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                    ]),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(a.message, style: TextStyle(fontSize: 14, height: 1.5, color: theme.colorScheme.onSurface)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
