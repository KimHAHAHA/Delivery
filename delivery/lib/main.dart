import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/pages/User/U_login.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase Init
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // ✅ Supabase Init
  await Supabase.initialize(
    url: 'https://oltfgdmbdgfxsfdgvesz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9sdGZnZG1iZGdmeHNmZGd2ZXN6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4NzE5ODUsImV4cCI6MjA3NDQ0Nzk4NX0.Yf2sC3i7aLfZNi-Sj1vhKMxkmVM51CoW2ENlxl_LS2c',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(title: 'Delivery', home: ULoginPage());
  }
}
