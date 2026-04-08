import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/app_theme.dart';
import 'providers/user_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/main_screen.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // If Firebase configuration is missing, it will throw an exception.
    // For local UI testing without a firebase project we optionally catch this
    // but a real app needs a valid google-services.json / GoogleService-Info.plist.
    debugPrint("Firebase init failed (expected if missing config options): $e");
  }

  runApp(const ConnectApp());
}


class ConnectApp extends StatelessWidget {
  const ConnectApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Connect Social Media',
            theme: AppTheme.getLightTheme(themeProvider.seedColor),
            darkTheme: AppTheme.getDarkTheme(themeProvider.seedColor),
            themeMode: themeProvider.themeMode,
            home: StreamBuilder(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.hasData) {
                    return const MainScreen();
                  } else if (snapshot.hasError) {
                    return Center(child: Text('${snapshot.error}'));
                  }
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return const LoginScreen();
              },
            ),
          );
        }
      ),
    );
  }
}
