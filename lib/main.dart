import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");
  
  // Inicializar Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Inicializar Notificaciones Locales
  AwesomeNotifications().initialize(
    null, // usa icono por defecto
    [
      NotificationChannel(
        channelKey: 'dory_alerts',
        channelName: 'Alertas de Dory',
        channelDescription: 'Canal para recordatorios de pagos',
        defaultColor: const Color(0xFF00FFCC),
        importance: NotificationImportance.High,
        channelShowBadge: true,
      )
    ],
  );

  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });

  runApp(const DoryApp());
}

class DoryApp extends StatelessWidget {
  const DoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DORY',
      theme: DoryTheme.cyberpunkTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthStateHandler(),
    );
  }
}

class AuthStateHandler extends StatelessWidget {
  const AuthStateHandler({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final session = snapshot.data!.session;
          if (session != null) {
            return const MainScreen();
          }
        }
        return const AuthScreen();
      },
    );
  }
}
