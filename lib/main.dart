import 'package:app/core/services/fcm_service.dart';
import 'package:app/features/auctions/presentation/product_details_page.dart';
import 'package:app/features/auth/presentation/auth_page.dart';
import 'package:app/core/theme/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background/terminated-state message handler. Runs in its own isolate, so it
/// must initialize Firebase itself. The system renders the notification; this
/// hook exists only so background delivery is registered.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FcmService.init();

  // Notification taps open the relevant auction via the global navigator.
  FcmService.onOpenProduct = (productId) {
    FcmService.navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => ProductDetails(docId: productId)),
    );
  };

  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(sharedPreferences: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;
  const MyApp({super.key, required this.sharedPreferences});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider(sharedPreferences)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: FcmService.navigatorKey,
        home: const AuthPage(),
      ),
    );
  }
}