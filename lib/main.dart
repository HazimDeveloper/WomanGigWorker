import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/user_provider.dart';
import 'dart:developer' as developer;
// Create a global navigatorKey that can be accessed anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void initImageCache() {
  PaintingBinding.instance.imageCache.maximumSize = 200; // Default is 1000
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100 MB, default is 10 MB
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
    FirebaseStorage.instance.setMaxUploadRetryTime(const Duration(seconds: 3));
  FirebaseStorage.instance.setMaxOperationRetryTime(const Duration(seconds: 3));
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const TrustMeApp(),
    ),
  );
}