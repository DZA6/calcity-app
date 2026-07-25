import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/content_provider.dart';
import '../widgets/business_card.dart';
import 'detail_screen.dart';

class BusinessesScreen extends StatefulWidget {
  const BusinessesScreen({super.key});

  @override
  State<BusinessesScreen> createState() => _BusinessesScreenState();
}

class _BusinessesScreenState extends State<BusinessesScreen> {
  String? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<String> get _categories {
    final provider = context.read<ContentProvider>();
    final cats = provider.businesses
        .map((b) => b.category)
        .where((c) => c != null && c.isNotEmpty)
        .map((c) => c!)
        .toSet()
        .toList();
    cats.sort();
    return ['All', ...cats];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Local Businesses')),
      body: Consumer<ContentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.businesses.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.businesses.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No businesses listed yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to refresh',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          var businesses = List<dynamic>.from(provider.businesses);

          // Filter by category
          if (_selectedCategory != null && _selectedCategory != 'All') {
            businesses = businesses
                .where((b) =>
                    b.category?.toLowerCase() ==
                    _selectedCategory!.toLowerCase())
                .toList();
          }

          // Filter by search
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            businesses = businesses
                .where((b) =>
                    b.name.toLowerCase().contains(query) ||
                    (b.description?.toLowerCase().contains(query) ?? false) ||
                    (b.category?.toLowerCase().contains(query) ?? false))
                .toList();
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshBusinesses(),
            child: CustomScrollView(
              slivers: [
                // Search bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search businesses...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ),
                // Category tabs
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = cat == _selectedCategory ||
                            (cat == 'All' && _selectedCategory == null);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory = cat == 'All' ? null : cat;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: businesses.isEmpty ? 100 : 8,
                    child: businesses.isEmpty
                        ? Center(
                            child: Text(
                              'No businesses match your criteria',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                // Business grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = businesses[index];
                        return BusinessCard(
                          item: item,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(
                                title: item.name,
                                itemType: 'business',
                                content: item.description ??
                                    'No description available.',
                                metadata: {
                                  if (item.category != null)
                                    'category': item.category!,
                                  if (item.contactPhone != null)
                                    'phone': item.contactPhone!,
                                  if (item.contactEmail != null)
                                    'email': item.contactEmail!,
                                  if (item.website != null)
                                    'website': item.website!,
                                  if (item.address != null)
                                    'address': item.address!,
                                  if (item.isHomeBased)
                                    'is_home_based': 'true',
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: businesses.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
