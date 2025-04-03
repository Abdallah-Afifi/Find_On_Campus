import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/item_card.dart';
import 'item_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  bool _hasSearched = false;
  ItemType? _filterType;
  String _selectedCategory = 'All Categories';
  bool _isMounted = false;
  final List<String> _categories = [
    'All Categories',
    'Electronics',
    'Books',
    'Clothing',
    'Accessories',
    'Keys',
    'ID Cards',
    'Bags',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    // Clear any previous search results when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      itemProvider.clearSearchResults();
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return;
    }

    if (!_isMounted) return;
    setState(() {
      _hasSearched = true;
    });

    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    await itemProvider.searchItems(
      query,
      filterType: _filterType,
      category: _selectedCategory != 'All Categories' ? _selectedCategory : null,
    );
  }

  void _updateFilterType(ItemType? newType) {
    if (!_isMounted) return;
    setState(() {
      _filterType = newType;
    });
    
    // If we've already searched once, update the results with the new filter
    if (_hasSearched) {
      _performSearch();
    }
  }

  void _updateCategory(String category) {
    if (!_isMounted) return;
    setState(() {
      _selectedCategory = category;
    });
    
    // If we've already searched once, update the results with the new category
    if (_hasSearched) {
      _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);
    final isLoading = itemProvider.isSearching;
    final searchResults = itemProvider.searchResults;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Find Items',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: AppTheme.gradientBackground,
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _animation,
              child: Column(
                children: [
                  // Search section
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search bar
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'What are you looking for?',
                              hintStyle: TextStyle(color: AppTheme.textLight),
                              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                              filled: true,
                              fillColor: AppTheme.searchBarBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(color: AppTheme.primaryColor),
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                            ),
                            style: const TextStyle(fontSize: 16),
                            onSubmitted: (_) => _performSearch(),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Filter label
                          const Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Type filter
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                _buildFilterChip(
                                  'All Items',
                                  selected: _filterType == null,
                                  onSelected: (_) => _updateFilterType(null),
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  'Lost Items',
                                  selected: _filterType == ItemType.lost,
                                  onSelected: (_) => _updateFilterType(ItemType.lost),
                                  color: AppTheme.lostItemColor,
                                  icon: Icons.search,
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  'Found Items',
                                  selected: _filterType == ItemType.found,
                                  onSelected: (_) => _updateFilterType(ItemType.found),
                                  color: AppTheme.foundItemColor,
                                  icon: Icons.check_circle,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Categories filter
                          const Text(
                            'Categories',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: _categories.map((category) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildFilterChip(
                                    category,
                                    selected: _selectedCategory == category,
                                    onSelected: (_) => _updateCategory(category),
                                    color: AppTheme.secondaryColor,
                                    icon: _getCategoryIcon(category),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Search button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _performSearch,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Search',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Results
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 16),
            sliver: isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                  )
                : !_hasSearched
                    ? SliverFillRemaining(
                        child: FadeTransition(
                          opacity: _animation,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://cdn-icons-png.flaticon.com/512/1086/1086933.png', 
                                  width: 120,
                                  height: 120,
                                  color: AppTheme.textLight.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Search for lost or found items',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Enter keywords above to find what you\'re looking for',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : searchResults.isEmpty
                        ? SliverFillRemaining(
                            child: FadeTransition(
                              opacity: _animation,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.network(
                                      'https://cdn-icons-png.flaticon.com/512/7486/7486744.png', 
                                      width: 120,
                                      height: 120,
                                      color: AppTheme.textLight.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No matching items found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try adjusting your search or filters',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = searchResults[index];
                                // Add staggered animation for each item
                                return AnimatedOpacity(
                                  duration: Duration(milliseconds: 400 + (index * 100)),
                                  opacity: 1.0,
                                  curve: Curves.easeInOut,
                                  child: AnimatedPadding(
                                    duration: Duration(milliseconds: 400 + (index * 100)),
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: Hero(
                                      tag: 'item-${item.id}',
                                      child: ItemCard(
                                        item: item,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (context, animation, secondaryAnimation) => ItemDetailsScreen(
                                                itemId: item.id,
                                              ),
                                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                return FadeTransition(opacity: animation, child: child);
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: searchResults.length,
                            ),
                          ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(
    String label, {
    required bool selected,
    required Function(bool) onSelected,
    required Color color,
    IconData? icon,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : color,
            ),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: Colors.white,
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppTheme.textSecondary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? color : AppTheme.textLight.withOpacity(0.3),
        ),
      ),
      elevation: selected ? 2 : 0,
      pressElevation: 4,
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Electronics':
        return Icons.devices;
      case 'Books':
        return Icons.book;
      case 'Clothing':
        return Icons.checkroom;
      case 'Accessories':
        return Icons.watch;
      case 'Keys':
        return Icons.key;
      case 'ID Cards':
        return Icons.badge;
      case 'Bags':
        return Icons.backpack;
      case 'All Categories':
        return Icons.category;
      default:
        return Icons.help_outline;
    }
  }
}