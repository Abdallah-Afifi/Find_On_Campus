import 'dart:io';
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/item_service.dart';

class ItemProvider extends ChangeNotifier {
  final ItemService _itemService = ItemService();
  
  // Items state
  List<Item> _recentItems = [];
  List<Item> _lostItems = [];
  List<Item> _foundItems = [];
  List<Item> _userItems = [];
  List<Item> _searchResults = [];
  
  // Loading states
  bool _isLoadingRecent = false;
  bool _isLoadingLost = false;
  bool _isLoadingFound = false;
  bool _isLoadingUserItems = false;
  bool _isSearching = false;
  
  // Getters
  List<Item> get recentItems => _recentItems;
  List<Item> get lostItems => _lostItems;
  List<Item> get foundItems => _foundItems;
  List<Item> get userItems => _userItems;
  List<Item> get searchResults => _searchResults;
  
  bool get isLoadingRecent => _isLoadingRecent;
  bool get isLoadingLost => _isLoadingLost;
  bool get isLoadingFound => _isLoadingFound;
  bool get isLoadingUserItems => _isLoadingUserItems;
  bool get isSearching => _isSearching;
  
  // Fetch recent items
  Future<void> fetchRecentItems({int limit = 10}) async {
    _isLoadingRecent = true;
    notifyListeners();
    
    try {
      _recentItems = await _itemService.getRecentItems(limit: limit);
    } catch (e) {
      print('Error in ItemProvider.fetchRecentItems: $e');
    } finally {
      _isLoadingRecent = false;
      notifyListeners();
    }
  }
  
  // Fetch items by type
  Future<void> fetchItemsByType(ItemType type) async {
    if (type == ItemType.lost) {
      _isLoadingLost = true;
    } else {
      _isLoadingFound = true;
    }
    notifyListeners();
    
    try {
      final items = await _itemService.getItemsByType(type);
      
      if (type == ItemType.lost) {
        _lostItems = items;
        _isLoadingLost = false;
      } else {
        _foundItems = items;
        _isLoadingFound = false;
      }
    } catch (e) {
      print('Error in ItemProvider.fetchItemsByType: $e');
      if (type == ItemType.lost) {
        _isLoadingLost = false;
      } else {
        _isLoadingFound = false;
      }
    }
    
    notifyListeners();
  }
  
  // Fetch user items
  Future<void> fetchUserItems(String userId) async {
    if (userId.isEmpty) return;
    
    _isLoadingUserItems = true;
    notifyListeners();
    
    try {
      _userItems = await _itemService.getUserItems(userId);
    } catch (e) {
      print('Error in ItemProvider.fetchUserItems: $e');
    } finally {
      _isLoadingUserItems = false;
      notifyListeners();
    }
  }
  
  // Search for items
  Future<void> searchItems(String query, {ItemType? filterType, String? category}) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    _isSearching = true;
    notifyListeners();
    
    try {
      final results = await _itemService.searchItems(query, filterType: filterType);
      
      // Apply category filter if specified
      if (category != null && category != 'All Categories') {
        _searchResults = results.where((item) => item.category == category).toList();
      } else {
        _searchResults = results;
      }
    } catch (e) {
      print('Error in ItemProvider.searchItems: $e');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }
  
  // Report new item
  Future<String> reportItem({
    required String title,
    required String description,
    required String category,
    required String location,
    required DateTime date,
    required ItemType type,
    required String userId,
    File? photo,
  }) async {
    try {
      final itemId = await _itemService.addItem(
        title: title,
        description: description,
        category: category,
        location: location,
        date: date,
        type: type,
        userId: userId,
        photo: photo,
      );
      
      // Refresh relevant item lists based on the type
      if (type == ItemType.lost) {
        fetchItemsByType(ItemType.lost);
      } else {
        fetchItemsByType(ItemType.found);
      }
      
      // Also refresh user items if we have a user ID
      if (userId.isNotEmpty) {
        fetchUserItems(userId);
      }
      
      // Refresh recent items
      fetchRecentItems();
      
      return itemId;
    } catch (e) {
      print('Error in ItemProvider.reportItem: $e');
      rethrow;
    }
  }
  
  // Get a single item by ID with optional cache check
  Future<Item?> getItemById(String id, {bool useCache = true}) async {
    // Check if the item is already in one of our cached lists
    if (useCache) {
      // Look in all cached lists
      for (final item in [..._recentItems, ..._lostItems, ..._foundItems, ..._userItems]) {
        if (item.id == id) {
          return item;
        }
      }
    }
    
    // If not found in cache or useCache is false, fetch from service
    try {
      return await _itemService.getItemById(id);
    } catch (e) {
      print('Error in ItemProvider.getItemById: $e');
      return null;
    }
  }
  
  // Update item status
  Future<void> updateItemStatus(String itemId, ItemStatus status) async {
    try {
      await _itemService.updateItemStatus(itemId, status);
      
      // Update item in all cached lists
      _updateItemInCache(itemId, (item) {
        return Item(
          id: item.id,
          title: item.title,
          description: item.description,
          category: item.category,
          location: item.location,
          date: item.date,
          type: item.type,
          status: status,
          userId: item.userId,
          photoUrl: item.photoUrl,
          createdAt: item.createdAt,
          matchingItemIds: item.matchingItemIds,
        );
      });
      
      notifyListeners();
    } catch (e) {
      print('Error in ItemProvider.updateItemStatus: $e');
      rethrow;
    }
  }
  
  // Delete an item
  Future<void> deleteItem(String itemId, String userId) async {
    try {
      await _itemService.deleteItem(itemId, userId);
      
      // Remove item from all cached lists
      _recentItems.removeWhere((item) => item.id == itemId);
      _lostItems.removeWhere((item) => item.id == itemId);
      _foundItems.removeWhere((item) => item.id == itemId);
      _userItems.removeWhere((item) => item.id == itemId);
      _searchResults.removeWhere((item) => item.id == itemId);
      
      notifyListeners();
    } catch (e) {
      print('Error in ItemProvider.deleteItem: $e');
      rethrow;
    }
  }
  
  // Helper method to update an item in all cached lists
  void _updateItemInCache(String itemId, Item Function(Item) update) {
    for (var i = 0; i < _recentItems.length; i++) {
      if (_recentItems[i].id == itemId) {
        _recentItems[i] = update(_recentItems[i]);
      }
    }
    
    for (var i = 0; i < _lostItems.length; i++) {
      if (_lostItems[i].id == itemId) {
        _lostItems[i] = update(_lostItems[i]);
      }
    }
    
    for (var i = 0; i < _foundItems.length; i++) {
      if (_foundItems[i].id == itemId) {
        _foundItems[i] = update(_foundItems[i]);
      }
    }
    
    for (var i = 0; i < _userItems.length; i++) {
      if (_userItems[i].id == itemId) {
        _userItems[i] = update(_userItems[i]);
      }
    }
    
    for (var i = 0; i < _searchResults.length; i++) {
      if (_searchResults[i].id == itemId) {
        _searchResults[i] = update(_searchResults[i]);
      }
    }
  }
  
  // Clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }
}