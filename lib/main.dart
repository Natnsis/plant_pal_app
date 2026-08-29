import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/pp_theme.dart';
import 'screens/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: PP.bone,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const PlantPalApp());
}

class PlantPalApp extends StatelessWidget {
  const PlantPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlantPal',
      debugShowCheckedModeBanner: false,
      theme: buildPlantPalTheme(),
      home: const WelcomeScreen(),
    );
  }
}
