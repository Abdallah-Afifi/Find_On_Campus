import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/item_card.dart';
import 'item_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _tabController = TabController(length: 3, vsync: this);
    _loadItems();
  }

  @override
  void dispose() {
    _isMounted = false;
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    if (!_isMounted) return;
    
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    
    // Fetch all required data
    await Future.wait([
      itemProvider.fetchRecentItems(limit: 20),
      itemProvider.fetchItemsByType(ItemType.lost),
      itemProvider.fetchItemsByType(ItemType.found),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        final isLoading = itemProvider.isLoadingRecent || 
                          itemProvider.isLoadingLost || 
                          itemProvider.isLoadingFound;
        
        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 120.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'FindOnCampus',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    background: Container(
                      decoration: AppTheme.gradientBackground,
                    ),
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'Recent'),
                      Tab(text: 'Lost'),
                      Tab(text: 'Found'),
                    ],
                  ),
                ),
              ];
            },
            body: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : RefreshIndicator(
                    color: AppTheme.primaryColor,
                    onRefresh: _loadItems,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildItemList(context, itemProvider.recentItems),
                        _buildItemList(context, itemProvider.lostItems, isLostItems: true),
                        _buildItemList(context, itemProvider.foundItems, isLostItems: false),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildItemList(BuildContext context, List<Item> items, {bool? isLostItems}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLostItems == null ? Icons.list_alt_rounded :
              isLostItems ? Icons.search_off_rounded : Icons.check_circle_outline_rounded,
              size: 80,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              isLostItems == null ? 'No items to display' :
              isLostItems ? 'No lost items reported' : 'No found items reported',
              style: const TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isLostItems == null ? 'Check back later!' :
              isLostItems ? 'Report something you\'ve lost' : 'Report something you\'ve found',
              style: const TextStyle(color: AppTheme.textLight),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        
        // Add staggered animation effect
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 30)),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(0, 0, 0),
          margin: const EdgeInsets.only(bottom: 16),
          child: Hero(
            tag: 'item-${item.id}',
            child: ItemCard(
              item: item,
              onTap: () {
                // Navigate to item details page with hero animation
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetailsScreen(itemId: item.id),
                  ),
                ).then((_) => _loadItems());
              },
            ),
          ),
        );
      },
    );
  }
}