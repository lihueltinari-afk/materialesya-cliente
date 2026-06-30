import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/app_router.dart';
import '../screens/pedidos_screen.dart';
import 'api_service.dart';

// Manejador en background: debe ser función top-level
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  static bool _inicializado = false;

  /// Llamar una vez en main(). Falla en silencio si Firebase no está configurado.
  static Future<void> inicializar() async {
    if (_inicializado) return;
    try {
      // Firebase.initializeApp() necesita firebase_options.dart generado con:
      //   flutterfire configure
      // Ver sección de configuración más abajo.
      await Firebase.initializeApp();
      _inicializado = true;

      final messaging = FirebaseMessaging.instance;

      // Pedir permiso al usuario (iOS + web)
      final settings = await messaging.requestPermission(
        alert: true, badge: true, sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      // Obtener token del dispositivo y enviarlo al backend
      final token = await messaging.getToken();
      if (token != null) await _guardarTokenEnBackend(token);
      messaging.onTokenRefresh.listen(_guardarTokenEnBackend);

      // App en primer plano: mostrar SnackBar
      FirebaseMessaging.onMessage.listen(_mostrarSnackBar);

      // App en background/cerrada: abrir pantalla del pedido al tocar
      FirebaseMessaging.onMessageOpenedApp.listen(_navegarAPedido);
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      final msgInicial = await messaging.getInitialMessage();
      if (msgInicial != null) _navegarAPedido(msgInicial);
    } catch (e) {
      // Firebase no configurado: la app funciona igual, sin notificaciones push
      debugPrint('[FCM] No inicializado: $e');
    }
  }

  static Future<void> _guardarTokenEnBackend(String token) async {
    try {
      await ApiService.patch('/auth/fcm-token', {'fcm_token': token});
    } catch (_) {}
  }

  static void _mostrarSnackBar(RemoteMessage msg) {
    final titulo = msg.notification?.title ?? '';
    final cuerpo = msg.notification?.body ?? '';
    final ctx = navigatorKey.currentContext;
    if (ctx == null || titulo.isEmpty) return;

    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFF1E3A5F),
      duration: const Duration(seconds: 5),
      content: Row(children: [
        const Icon(Icons.notifications_active, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13)),
          if (cuerpo.isNotEmpty)
            Text(cuerpo, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
      ]),
      action: SnackBarAction(
        label: 'Ver pedido',
        textColor: const Color(0xFFFFD280),
        onPressed: () => _navegarAPedido(msg),
      ),
    ));
  }

  static void _navegarAPedido(RemoteMessage msg) {
    final pedidoId = int.tryParse(msg.data['pedido_id']?.toString() ?? '');
    if (pedidoId == null) return;
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => DetallePedidoScreen(pedidoId: pedidoId)),
    );
  }
}

/*
════════════════════════════════════════════════════════════════
CONFIGURACIÓN REQUERIDA PARA ACTIVAR NOTIFICACIONES PUSH
════════════════════════════════════════════════════════════════

1. Crear proyecto en Firebase Console: https://console.firebase.google.com
   - Agregar app web (para Netlify)
   - Agregar app Android (si se va a compilar para mobile)

2. Instalar FlutterFire CLI:
   dart pub global activate flutterfire_cli

3. Configurar el proyecto (en el directorio app_cliente/):
   flutterfire configure

   Esto genera: lib/firebase_options.dart

4. Actualizar main.dart para usar las opciones:
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   // Agregar import: import 'firebase_options.dart';

5. Para web: ir a Firebase Console → Project Settings → Your apps → Web
   Copiar el config snippet y pegarlo en web/index.html antes de </body>

6. Variables de entorno en Railway (backend) para enviar notificaciones:
   FIREBASE_PROJECT_ID=tu-project-id
   FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@xxx.iam.gserviceaccount.com
   FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----...

   Descargar el archivo de credenciales desde:
   Firebase Console → Project Settings → Service Accounts → Generate new private key
════════════════════════════════════════════════════════════════
*/
