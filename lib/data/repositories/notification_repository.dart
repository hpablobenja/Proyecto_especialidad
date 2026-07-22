import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Marcar notificación como leída
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  // Marcar todas las notificaciones como leídas
  Future<void> markAllAsRead() async {
    final userId = await _getCurrentUserId();
    final unreadNotifications =
        await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .get();

    final batch = _firestore.batch();
    for (var doc in unreadNotifications.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // Crear notificación (para uso administrativo)
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? courseId,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      if (courseId != null) 'courseId': courseId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Eliminar notificación
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Obtener ID del usuario actual
  Future<String?> _getCurrentUserId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) return currentUser.uid;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  // Stream de notificaciones del usuario actual
  Stream<List<NotificationModel>> getUserNotifications() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(<NotificationModel>[]);
      }
      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .map((snapshot) {
            final notifications =
                snapshot.docs
                    .map((doc) => NotificationModel.fromFirestore(doc))
                    .toList();
            // Ordenar en el cliente
            notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return notifications;
          });
    });
  }

  // Stream de notificaciones no leídas
  Stream<List<NotificationModel>> getUnreadNotifications() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(<NotificationModel>[]);
      }
      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
            final notifications =
                snapshot.docs
                    .map((doc) => NotificationModel.fromFirestore(doc))
                    .toList();
            // Ordenar en el cliente
            notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return notifications;
          });
    });
  }

  // Contador de notificaciones no leídas
  Stream<int> getUnreadCount() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(0);
      }
      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    });
  }
}
