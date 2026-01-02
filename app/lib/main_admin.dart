import 'package:app/admin/auth/admin_login_screen.dart';
import 'package:app/admin/admin_layout.dart';
import 'package:app/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:app/providers/order_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Use PathUrlStrategy for cleaner URLs on Web
  // setUrlStrategy(PathUrlStrategy()); 
  
  runApp(const AdminApp());
}


class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'Fashion Admin Portal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: FirebaseAuth.instance.currentUser != null 
            ? const AdminLayout() // Auto-login if session persists
            : const AdminLoginScreen(),
      ),
    );
  }
}
