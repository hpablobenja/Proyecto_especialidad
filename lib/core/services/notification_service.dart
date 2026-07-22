import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio de notificaciones preparado para Firebase Messaging
/// Este servicio está configurado para recibir notificaciones desde la consola de Firebase
/// (Notifications e In-App Messaging) cuando se implemente en el futuro.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Inicializar el servicio de notificaciones
  /// Prepara la app para recibir notificaciones desde Firebase Console
  Future<void> initialize() async {
    // Configurar notificaciones locales para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configurar notificaciones locales para iOS
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Solicitar permisos de notificación
    await _requestPermissions();

    // Configurar handlers de mensajes FCM (para uso futuro desde Firebase Console)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Obtener y guardar el token FCM
    await _setupFCMToken();

    // Escuchar cambios en el token
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _saveFCMToken(newToken);
    });
  }

  /// Solicitar permisos de notificación
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('Permiso de notificación: ${settings.authorizationStatus}');
    }
  }

  /// Configurar token FCM
  Future<void> _setupFCMToken() async {
    _fcmToken = await _messaging.getToken();
    if (_fcmToken != null) {
      await _saveFCMToken(_fcmToken!);
    }
  }

  /// Guardar token FCM en SharedPreferences y Firestore
  Future<void> _saveFCMToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (kDebugMode) {
        print('No hay usuario autenticado; no se actualiza Firestore.');
      }
      return;
    }

    final userId = currentUser.uid;

    await _firestore.collection('users').doc(userId).update({
      'fcmToken': token,
      'tokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Manejar mensaje en primer plano (desde Firebase Console)
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Mensaje recibido en primer plano: ${message.notification?.title}');
    }

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'redmaestra_channel',
            'RedMaestra Notificaciones',
            channelDescription: 'Canal de notificaciones para RedMaestra',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Manejar mensaje cuando la app está en segundo plano/cerrada (desde Firebase Console)
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    if (kDebugMode) {
      print('Mensaje recibido en background: ${message.notification?.title}');
    }
  }

  /// Manejar cuando el usuario toca una notificación (desde Firebase Console)
  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print('Notificación abierta: ${message.notification?.title}');
    }
    // Aquí puedes navegar a una pantalla específica según el payload
  }

  /// Manejar tap en notificación local
  void _onNotificationTap(NotificationResponse response) {
    if (kDebugMode) {
      print('Notificación local tocada: ${response.payload}');
    }
  }

  /// Suscribirse a un tópico (para uso futuro desde Firebase Console)
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    if (kDebugMode) {
      print('Suscrito al tópico: $topic');
    }
  }

  /// Desuscribirse de un tópico (para uso futuro desde Firebase Console)
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    if (kDebugMode) {
      print('Desuscrito del tópico: $topic');
    }
  }
}
