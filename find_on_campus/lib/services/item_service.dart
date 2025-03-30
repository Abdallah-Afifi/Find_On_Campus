import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../models/item.dart';

class ItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CollectionReference _itemsCollection = FirebaseFirestore.instance.collection('items');
  
  // Add a new item to the database
  Future<String> addItem({
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
      final uuid = const Uuid().v4();
      String? photoUrl;
      
      // Upload photo if provided
      if (photo != null) {
        photoUrl = await _uploadPhoto(photo, uuid);
      }
      
      final Item newItem = Item(
        id: uuid,
        title: title,
        description: description,
        category: category,
        location: location,
        date: date,
        type: type,
        status: ItemStatus.pending,
        userId: userId,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
      );
      
      await _itemsCollection.doc(uuid).set(newItem.toJson());
      
      // Update user's reported items
      await _firestore.collection('users').doc(userId).update({
        'reportedItems': FieldValue.arrayUnion([uuid]),
      });
      
      // Find potential matches
      if (type == ItemType.lost) {
        await findPotentialMatches(newItem, ItemType.found);
      } else {
        await findPotentialMatches(newItem, ItemType.lost);
      }
      
      return uuid;
    } catch (e) {
      print('Error adding item: $e');
      throw e;
    }
  }
  
  // Upload photo to Firebase Storage
  Future<String> _uploadPhoto(File photo, String itemId) async {
    try {
      final ref = _storage.ref().child('item_photos/$itemId');
      final uploadTask = ref.putFile(photo);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading photo: $e');
      throw e;
    }
  }
  
  // Get all items by type (lost or found)
  Future<List<Item>> getItemsByType(ItemType type) async {
    try {
      final snapshot = await _itemsCollection
          .where('type', isEqualTo: type.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .get();
          
      return snapshot.docs
          .map((doc) => Item.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print('Error getting items by type: $e');
      return [];
    }
  }
  
  // Get recent items (both lost and found)
  Future<List<Item>> getRecentItems({int limit = 10}) async {
    try {
      final snapshot = await _itemsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
          
      return snapshot.docs
          .map((doc) => Item.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print('Error getting recent items: $e');
      return [];
    }
  }
  
  // Get items by user ID
  Future<List<Item>> getUserItems(String userId) async {
    try {
      final snapshot = await _itemsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
          
      return snapshot.docs
          .map((doc) => Item.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print('Error getting user items: $e');
      return [];
    }
  }
  
  // Get a single item by ID
  Future<Item?> getItemById(String id) async {
    try {
      final doc = await _itemsCollection.doc(id).get();
      
      if (doc.exists) {
        return Item.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
      }
      
      return null;
    } catch (e) {
      print('Error getting item by ID: $e');
      return null;
    }
  }
  
  // Update item status
  Future<void> updateItemStatus(String itemId, ItemStatus status) async {
    try {
      await _itemsCollection.doc(itemId).update({
        'status': status.toString().split('.').last,
      });
    } catch (e) {
      print('Error updating item status: $e');
      throw e;
    }
  }
  
  // Search for items based on keywords
  Future<List<Item>> searchItems(String query, {ItemType? filterType}) async {
    try {
      Query itemQuery = _itemsCollection;
      
      if (filterType != null) {
        itemQuery = itemQuery.where('type', isEqualTo: filterType.toString().split('.').last);
      }
      
      final snapshot = await itemQuery.get();
      
      final allItems = snapshot.docs
          .map((doc) => Item.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
      
      // Basic search implementation - can be improved with full-text search solutions
      final queryLowerCase = query.toLowerCase();
      return allItems.where((item) {
        return item.title.toLowerCase().contains(queryLowerCase) ||
              item.description.toLowerCase().contains(queryLowerCase) ||
              item.category.toLowerCase().contains(queryLowerCase) ||
              item.location.toLowerCase().contains(queryLowerCase);
      }).toList();
    } catch (e) {
      print('Error searching items: $e');
      return [];
    }
  }
  
  // Find potential matches for a new item
  Future<List<String>> findPotentialMatches(Item newItem, ItemType matchType) async {
    try {
      // Get items of the opposite type
      final oppositeTypeItems = await getItemsByType(matchType);
      
      // Filter items that might be a match based on category and date
      final potentialMatches = oppositeTypeItems.where((item) {
        // Same category
        final sameCategory = item.category == newItem.category;
        
        // Date within a reasonable range (7 days)
        final dateDifference = (item.date.difference(newItem.date).inDays).abs();
        final dateWithinRange = dateDifference <= 7;
        
        return sameCategory && dateWithinRange;
      }).toList();
      
      // Store the potential match IDs
      final matchIds = potentialMatches.map((item) => item.id).toList();
      
      if (matchIds.isNotEmpty) {
        // Update the new item with potential matches
        await _itemsCollection.doc(newItem.id).update({
          'matchingItemIds': matchIds,
        });
        
        // Update the potential matches with this new item
        for (final match in potentialMatches) {
          final existingMatchIds = match.matchingItemIds ?? [];
          final updatedMatchIds = [...existingMatchIds, newItem.id];
          
          await _itemsCollection.doc(match.id).update({
            'matchingItemIds': updatedMatchIds,
          });
        }
      }
      
      return matchIds;
    } catch (e) {
      print('Error finding potential matches: $e');
      return [];
    }
  }
  
  // Delete an item
  Future<void> deleteItem(String itemId, String userId) async {
    try {
      // Delete the item
      await _itemsCollection.doc(itemId).delete();
      
      // Remove the item from user's reportedItems
      await _firestore.collection('users').doc(userId).update({
        'reportedItems': FieldValue.arrayRemove([itemId]),
      });
      
      // Delete the photo if it exists
      try {
        await _storage.ref().child('item_photos/$itemId').delete();
      } catch (e) {
        // Ignore if no photo exists
      }
    } catch (e) {
      print('Error deleting item: $e');
      throw e;
    }
  }
}