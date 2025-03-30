import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/item_service.dart';
import '../widgets/item_card.dart';
import 'item_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final ItemService _itemService = ItemService();
  late TabController _tabController;
  List<Item> _recentItems = [];
  List<Item> _lostItems = [];
  List<Item> _foundItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recentItems = await _itemService.getRecentItems(limit: 20);
      final lostItems = await _itemService.getItemsByType(ItemType.lost);
      final foundItems = await _itemService.getItemsByType(ItemType.found);

      setState(() {
        _recentItems = recentItems;
        _lostItems = lostItems;
        _foundItems = foundItems;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Recent'),
            Tab(text: 'Lost'),
            Tab(text: 'Found'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadItems,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildItemList(_recentItems),
                  _buildItemList(_lostItems),
                  _buildItemList(_foundItems),
                ],
              ),
            ),
    );
  }

  Widget _buildItemList(List<Item> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No items to display'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ItemCard(
            item: item,
            onTap: () {
              // Navigate to item details page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailsScreen(itemId: item.id),
                ),
              ).then((_) => _loadItems());
            },
          ),
        );
      },
    );
  }
}