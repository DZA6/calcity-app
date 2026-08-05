import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/content.dart';
import '../providers/content_provider.dart';
import '../widgets/news_card.dart';
import 'detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String category;
  final String title;
  const CategoryScreen({super.key, required this.category, required this.title});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<NewsItem>> _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _items = context.read<ContentProvider>().fetchNewsByCategory(widget.category);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<dynamic>>(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No ${widget.title} items yet',
                      style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Check back soon!',
                      style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 13)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final n = items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NewsCard(item: n, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(
                      title: n.title, itemType: 'news', content: n.content,
                      metadata: {
                        if (n.imageUrl != null) 'image_url': n.imageUrl!,
                        if (n.videoUrl != null) 'video_url': n.videoUrl!,
                        if (n.sourceUrl != null) 'source_url': n.sourceUrl!,
                      },
                    )));
                  }),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
