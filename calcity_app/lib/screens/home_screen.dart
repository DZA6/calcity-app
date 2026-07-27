import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/content_provider.dart';
import '../widgets/news_card.dart';
import '../widgets/event_card.dart';
import '../widgets/business_card.dart';
import '../services/ad_service.dart';
import 'news_screen.dart';
import 'events_screen.dart';
import 'businesses_screen.dart';
import 'tip_screen.dart';
import 'alerts_screen.dart';
import 'council_screen.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentProvider>().refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ContentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.news.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final theme = Theme.of(context);

          return RefreshIndicator(
            onRefresh: () => provider.refreshAll(),
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(child: _buildAlertBanner(context)),
                SliverToBoxAdapter(child: _buildQuickActions(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: _buildSectionHeader(
                      context,
                      title: 'Latest News',
                      icon: Icons.article_outlined,
                      count: provider.news.length,
                      onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NewsScreen()),
                      ),
                    ),
                  ),
                ),
                if (provider.news.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 270,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.news.length,
                        itemBuilder: (context, index) {
                          final item = provider.news[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: NewsCard(
                              item: item,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetailScreen(
                                    title: item.title,
                                    itemType: 'news',
                                    content: item.content,
                                    metadata: {
                                      'date': item.createdAt.toIso8601String(),
                                      if (item.sourceUrl != null)
                                        'source_url': item.sourceUrl!,
                                      if (item.featured) 'featured': 'true',
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: _buildEmptyState(context, Icons.article_outlined, 'No news yet'),
                  ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: _buildSectionHeader(
                      context,
                      title: 'Upcoming Events',
                      icon: Icons.event_outlined,
                      count: provider.events.length,
                      onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EventsScreen()),
                      ),
                    ),
                  ),
                ),
                if (provider.events.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = provider.events[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            left: 20,
                            right: 20,
                            bottom: index < provider.events.length - 1 ? 8 : 0,
                          ),
                          child: EventCard(
                            item: item,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(
                                  title: item.title,
                                  itemType: 'event',
                                  content: item.description ?? 'No description available.',
                                  metadata: {
                                    if (item.startDate != null)
                                      'start_date': item.startDate!.toIso8601String(),
                                    if (item.endDate != null)
                                      'end_date': item.endDate!.toIso8601String(),
                                    if (item.location != null) 'location': item.location!,
                                    if (item.category != null) 'category': item.category!,
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: provider.events.length > 3 ? 3 : provider.events.length,
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: _buildEmptyState(context, Icons.event_outlined, 'No events yet'),
                  ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: _buildSectionHeader(
                      context,
                      title: 'Featured Businesses',
                      icon: Icons.store_outlined,
                      count: provider.featuredBusinesses.length,
                      onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BusinessesScreen()),
                      ),
                    ),
                  ),
                ),
                if (provider.featuredBusinesses.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = provider.featuredBusinesses[index];
                          return BusinessCard(
                            item: item,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(
                                  title: item.name,
                                  itemType: 'business',
                                  content: item.description ?? 'No description available.',
                                  metadata: {
                                    if (item.category != null) 'category': item.category!,
                                    if (item.contactPhone != null) 'phone': item.contactPhone!,
                                    if (item.contactEmail != null) 'email': item.contactEmail!,
                                    if (item.website != null) 'website': item.website!,
                                    if (item.address != null) 'address': item.address!,
                                    if (item.isHomeBased) 'is_home_based': 'true',
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: provider.featuredBusinesses.length,
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: _buildEmptyState(context, Icons.store_outlined, 'No businesses yet'),
                  ),

                // City Council Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: _buildSectionHeader(
                      context,
                      title: 'City Council',
                      icon: Icons.groups_outlined,
                      count: provider.councilAgendas.length,
                      onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CouncilScreen()),
                      ),
                    ),
                  ),
                ),
                if (provider.councilAgendas.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.councilAgendas.length > 5
                            ? 5
                            : provider.councilAgendas.length,
                        itemBuilder: (context, index) {
                          final item = provider.councilAgendas[index];
                          final dateStr = item.meetingDate != null
                              ? '${item.meetingDate!.month}/${item.meetingDate!.day}'
                              : 'TBD';
                          return Container(
                            width: 200,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: _buildEmptyState(
                      context,
                      Icons.groups_outlined,
                      'No upcoming council meetings posted',
                    ),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Banner Ad
                if (AdService().bannerLoaded && AdService().bannerAd != null)
                  SliverToBoxAdapter(
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: AdService().bannerAd!.size.width.toDouble(),
                        height: AdService().bannerAd!.size.height.toDouble(),
                        child: AdWidget(ad: AdService().bannerAd!),
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                left: -20,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 80,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Content
              Positioned(
                left: 24,
                bottom: 28,
                right: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'California City',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
                          onPressed: () => context.read<ContentProvider>().refreshAll(),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your Community Hub',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Discover what\'s happening',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertBanner(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final activeAlerts = provider.activeAlerts
        .where((a) => a.severity.toLowerCase() == 'emergency' ||
            a.severity.toLowerCase() == 'warning' ||
            a.severity.toLowerCase() == 'info')
        .toList();

    if (activeAlerts.isEmpty) return const SizedBox.shrink();

    // Show highest severity alert
    final priority = ['emergency', 'warning', 'info'];
    activeAlerts.sort((a, b) =>
        priority.indexOf(a.severity.toLowerCase())
            .compareTo(priority.indexOf(b.severity.toLowerCase())));

    final topAlert = activeAlerts.first;

    Color bannerColor;
    IconData bannerIcon;
    switch (topAlert.severity.toLowerCase()) {
      case 'emergency':
        bannerColor = Colors.red.shade700;
        bannerIcon = Icons.error;
        break;
      case 'warning':
        bannerColor = Colors.amber.shade800;
        bannerIcon = Icons.warning_amber;
        break;
      default:
        bannerColor = Colors.blue.shade700;
        bannerIcon = Icons.info_outline;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AlertsScreen()),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bannerColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: bannerColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(bannerIcon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topAlert.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to read',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _quickActionCard(context, Icons.article_outlined, 'News', const NewsScreen(), theme),
          const SizedBox(width: 6),
          _quickActionCard(context, Icons.event_outlined, 'Events', const EventsScreen(), theme),
          const SizedBox(width: 6),
          _quickActionCard(context, Icons.store_outlined, 'Biz', const BusinessesScreen(), theme),
          const SizedBox(width: 6),
          _quickActionCard(context, Icons.lightbulb_outlined, 'Tip', const TipScreen(), theme),
          const SizedBox(width: 6),
          _quickActionCard(context, Icons.warning_amber, 'Alerts', const AlertsScreen(), theme),
        ],
      ),
    );
  }

  Widget _quickActionCard(
    BuildContext context,
    IconData icon,
    String label,
    Widget screen,
    ThemeData theme,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required int count,
    required VoidCallback onSeeAll,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Text(
          '$count items',
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('See All'),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String message) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
