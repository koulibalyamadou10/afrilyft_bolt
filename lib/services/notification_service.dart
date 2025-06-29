import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Initialiser les notifications
  static Future<void> initialize() async {
    // Demander les permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permissions de notification accordées');
    }

    // Initialiser les notifications locales
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(initializationSettings);

    // Écouter les messages en arrière-plan
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Écouter les messages quand l'app est ouverte
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Écouter les clics sur les notifications
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);
  }

  // Obtenir le token FCM
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Envoyer une notification push aux chauffeurs
  static Future<void> notifyDriversForRide({
    required String rideId,
    required String customerName,
    required String pickupAddress,
    required List<String> driverTokens,
  }) async {
    // Cette fonction sera appelée depuis le backend
    // Pour l'instant, on simule avec des notifications locales
    
    for (String token in driverTokens) {
      await _showLocalNotification(
        title: '🚗 Nouvelle demande de trajet',
        body: '$customerName recherche un chauffeur depuis $pickupAddress',
        payload: rideId,
      );
    }
  }

  // Afficher une notification locale
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'ride_requests',
      'Demandes de trajet',
      channelDescription: 'Notifications pour les nouvelles demandes de trajet',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Gérer les messages en arrière-plan
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('📱 Message reçu en arrière-plan: ${message.messageId}');
  }

  // Gérer les messages quand l'app est ouverte
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📱 Message reçu au premier plan: ${message.messageId}');
    
    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: message.data['ride_id'],
      );
    }
  }

  // Gérer les clics sur les notifications
  static void _handleNotificationClick(RemoteMessage message) {
    print('📱 Notification cliquée: ${message.messageId}');
    
    final rideId = message.data['ride_id'];
    if (rideId != null) {
      // Naviguer vers la page de détail du trajet
      // Get.toNamed('/ride-detail', arguments: rideId);
    }
  }
}