import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/item_service.dart';
import '../widgets/item_card.dart';
import 'item_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ItemService _itemService = ItemService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Item> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  ItemType? _filterType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await _itemService.searchItems(query, filterType: _filterType);
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching items: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching items: $e')),
      );
    }
  }

  void _updateFilterType(ItemType? newType) {
    setState(() {
      _filterType = newType;
    });
    
    // If we've already searched once, update the results with the new filter
    if (_hasSearched) {
      _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Items'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search for lost or found items...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
                
                const SizedBox(height: 12),
                
                // Filter options
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // All items
                    ChoiceChip(
                      label: const Text('All Items'),
                      selected: _filterType == null,
                      onSelected: (_) => _updateFilterType(null),
                    ),
                    
                    // Lost items
                    ChoiceChip(
                      label: const Text('Lost Items'),
                      selectedColor: Colors.red.shade200,
                      selected: _filterType == ItemType.lost,
                      onSelected: (_) => _updateFilterType(ItemType.lost),
                    ),
                    
                    // Found items
                    ChoiceChip(
                      label: const Text('Found Items'),
                      selectedColor: Colors.green.shade200,
                      selected: _filterType == ItemType.found,
                      onSelected: (_) => _updateFilterType(ItemType.found),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Search button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _performSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Search'),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? const Center(
                        child: Text('Search for items above'),
                      )
                    : _searchResults.isEmpty
                        ? const Center(
                            child: Text('No items found matching your search'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final item = _searchResults[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: ItemCard(
                                  item: item,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ItemDetailsScreen(
                                          itemId: item.id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}