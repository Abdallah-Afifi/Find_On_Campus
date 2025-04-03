import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// This needs to be outside and marked as a VM entry point
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Make sure Firebase is initialized for background handlers
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Make NotificationService a singleton
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  // Initialize the notification service
  Future<void> initialize() async {
    try {
      // Request permission for notifications
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      // Configure local notifications
      const AndroidInitializationSettings initializationSettingsAndroid = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
          
      const DarwinInitializationSettings initializationSettingsIOS = 
          DarwinInitializationSettings();
          
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
          print("Notification tapped: ${response.payload}");
        },
      );
      
      // Handle background messages - use the top-level handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(
          title: message.notification?.title ?? 'FindOnCampus',
          body: message.notification?.body ?? '',
          payload: message.data['itemId'],
        );
      });
      
      print('Notification service initialized');
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }
  
  // Save a user's FCM token to Firestore
  Future<void> saveToken(String userId) async {
    try {
      final token = await _firebaseMessaging.getToken();
      
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayUnion([token]),
        });
      }
    } catch (e) {
      print('Error saving token: $e');
    }
  }
  
  // Remove a user's FCM token when they sign out
  Future<void> removeToken(String userId) async {
    try {
      final token = await _firebaseMessaging.getToken();
      
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      }
    } catch (e) {
      print('Error removing token: $e');
    }
  }
  
  // Show a local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'find_on_campus_channel',
        'Find On Campus Notifications',
        channelDescription: 'Notifications for Find On Campus app',
        importance: Importance.max,
        priority: Priority.high,
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecond,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }
  
  // Send a notification to a specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    String? itemId,
  }) async {
    try {
      // This should be handled by a Cloud Function in a real app
      // For simplicity, we'll show a local notification for the demo
      _showLocalNotification(
        title: title,
        body: body,
        payload: itemId,
      );
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
  
  // Send a notification for a potential match
  Future<void> sendMatchNotification({
    required String userId,
    required String itemTitle,
    required String matchItemTitle,
    required String matchItemId,
  }) async {
    final title = 'Potential Match Found!';
    final body = 'Your item "$itemTitle" might match with "$matchItemTitle"';
    
    await sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      itemId: matchItemId,
    );
  }
  
  // Send a notification when an item status changes
  Future<void> sendStatusUpdateNotification({
    required String userId,
    required String itemTitle,
    required String newStatus,
  }) async {
    final title = 'Item Status Updated';
    final body = 'Your item "$itemTitle" is now $newStatus';
    
    await sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
    );
  }
}