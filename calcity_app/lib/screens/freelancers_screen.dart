import 'package:flutter/material.dart';
import '../models/content.dart';
import '../services/api_service.dart';

/// Screen showing freelancer businesses — people selling their skills.
class FreelancersScreen extends StatefulWidget {
  const FreelancersScreen({super.key});

  @override
  State<FreelancersScreen> createState() => _FreelancersScreenState();
}

class _FreelancersScreenState extends State<FreelancersScreen> {
  List<BusinessItem> _freelancers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await ApiService().fetchBusinesses();
    if (mounted) {
      setState(() {
        _freelancers = all.where((b) => b.category == 'freelancer').toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Freelancers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () { setState(() => _loading = true); _load(); },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _freelancers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_search, size: 56, color: cs.onSurface.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text('No freelancers listed yet', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
                      const SizedBox(height: 4),
                      Text('Check back soon!', style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _freelancers.length,
                  itemBuilder: (ctx, i) => _buildFreelancerCard(_freelancers[i], cs),
                ),
    );
  }

  Widget _buildFreelancerCard(BusinessItem biz, ColorScheme cs) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.computer, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(biz.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
                      if (biz.description != null && biz.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(biz.description!, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (biz.contactPhone != null && biz.contactPhone!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.phone, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text(biz.contactPhone!, style: TextStyle(fontSize: 14, color: cs.onSurface)),
              ]),
            ],
            if (biz.contactEmail != null && biz.contactEmail!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.email, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text(biz.contactEmail!, style: TextStyle(fontSize: 14, color: cs.primary)),
              ]),
            ],
            if (biz.website != null && biz.website!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.language, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Flexible(child: Text(biz.website!, style: TextStyle(fontSize: 13, color: cs.primary), overflow: TextOverflow.ellipsis)),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
