import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final List<String> reportedItems;
  final int rewardPoints;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.reportedItems = const [],
    this.rewardPoints = 0,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'reportedItems': reportedItems,
      'rewardPoints': rewardPoints,
    };
  }

  // Create AppUser from Firestore snapshot
  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return AppUser(
      id: snapshot.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      reportedItems: data['reportedItems'] != null
          ? List<String>.from(data['reportedItems'])
          : [],
      rewardPoints: data['rewardPoints'] ?? 0,
    );
  }

  // Create a new AppUser with updated fields
  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    List<String>? reportedItems,
    int? rewardPoints,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      reportedItems: reportedItems ?? this.reportedItems,
      rewardPoints: rewardPoints ?? this.rewardPoints,
    );
  }
}