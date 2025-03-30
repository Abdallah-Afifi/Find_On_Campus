import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemType { lost, found }
enum ItemStatus { pending, resolved, claimed }

class Item {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final DateTime date;
  final ItemType type;
  final ItemStatus status;
  final String userId;
  final String? photoUrl;
  final DateTime createdAt;
  final List<String>? matchingItemIds;

  Item({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.date,
    required this.type,
    required this.status,
    required this.userId,
    this.photoUrl,
    required this.createdAt,
    this.matchingItemIds,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'date': date,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'userId': userId,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'matchingItemIds': matchingItemIds,
    };
  }

  // Create Item from Firestore snapshot
  factory Item.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return Item(
      id: snapshot.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'] == 'lost' ? ItemType.lost : ItemType.found,
      status: _parseStatus(data['status']),
      userId: data['userId'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      matchingItemIds: data['matchingItemIds'] != null
          ? List<String>.from(data['matchingItemIds'])
          : null,
    );
  }

  static ItemStatus _parseStatus(String? status) {
    switch (status) {
      case 'resolved':
        return ItemStatus.resolved;
      case 'claimed':
        return ItemStatus.claimed;
      default:
        return ItemStatus.pending;
    }
  }
}