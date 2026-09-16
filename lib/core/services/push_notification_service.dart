import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_client.dart';

/// Gère l'enregistrement du token FCM auprès du backend et l'affichage des
/// notifications reçues au premier plan (Android n'affiche pas nativement
/// une notification "data-only" ou reçue pendant que l'app est ouverte).
class PushNotificationService {
  PushNotificationService._internal();
  static final PushNotificationService instance =
      PushNotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _api = ApiClient.instance;
  bool _initialized = false;

  static const _channel = AndroidNotificationChannel(
    'iai_horizon_default',
    'Notifications IAI Horizon',
    description: 'Candidatures, offres et mises à jour de compte',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Comme pour enregistrerToken()/supprimerToken() : sans
    // firebase-messaging-sw.js, toute interaction avec FirebaseMessaging sur
    // le web (y compris juste demander la permission) peut planter côté JS
    // (ex. "Unexpected token... is not valid JSON" en essayant de charger le
    // service worker), donc on n'initialise rien de tout ça sur le web.
    if (kIsWeb) return;

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  /// À appeler juste après une connexion/inscription réussie : récupère le
  /// token FCM de l'appareil et l'enregistre côté backend pour cet utilisateur.
  Future<void> enregistrerToken() async {
    // Le web n'a pas de firebase-messaging-sw.js configuré : getToken() peut
    // rester bloqué indéfiniment (le navigateur attend un service worker qui
    // n'arrivera jamais). On n'active donc les notifications push que sur
    // mobile, où le token est ensuite obtenu avec un timeout de sécurité.
    if (kIsWeb) return;
    try {
      final token = await _messaging.getToken().timeout(const Duration(seconds: 10));
      if (token != null) {
        await _api.post('/notifications/device-token', {
          'token': token,
          'plateforme': Platform.isIOS ? 'ios' : 'android',
        });
      }
    } catch (e) {
      debugPrint('Échec enregistrement token FCM: $e');
    }
  }

  /// À appeler à la déconnexion : évite d'envoyer des notifications d'un
  /// compte à un autre utilisateur qui réutiliserait le même appareil.
  Future<void> supprimerToken() async {
    // Même garde que enregistrerToken() : sans service worker Firebase sur
    // le web, getToken() peut ne jamais se résoudre et bloquer la
    // déconnexion (le bouton "Se déconnecter" semblait alors ne rien faire).
    if (kIsWeb) return;
    try {
      final token = await _messaging.getToken().timeout(const Duration(seconds: 10));
      if (token != null) {
        await _api
            .delete('/notifications/device-token', body: {'token': token})
            .timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      debugPrint('Échec suppression token FCM: $e');
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}

/// Handler des messages reçus alors que l'app est en arrière-plan ou fermée.
/// Doit être une fonction top-level (contrainte Firebase) et annotée
/// @pragma pour survivre à la minification/tree-shaking en release.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {}
