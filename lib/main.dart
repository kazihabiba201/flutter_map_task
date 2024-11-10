import 'package:bari_koi/map/presentation/provider/map_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'map/data/repositories/direction_repositories.dart';
import 'map/presentation/screens/homepage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Dio dio = Dio();
  try {
    await dotenv.load(fileName: ".env");
    print('Environment variables loaded successfully.');
  } catch (e) {
    print('Error loading .env file: $e');
  }
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<MapProvider>(
        create: (context) => MapProvider(),
      ),
      ChangeNotifierProvider<DirectionsRepositoryProvider>(
        create: (context) => DirectionsRepositoryProvider(dio: dio),
      ),  ],

     child: const MyApp(),
    // ),
  ),);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'BariKoi Map',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: HomePage());
  }
}
