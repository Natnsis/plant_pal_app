import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/log_in_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_dashboard.dart';
import 'screens/notification_inbox.dart';
import 'screens/my_plants_screen.dart';
import 'screens/plant_detail_screen.dart';
import 'screens/scan_flow.dart';
import 'screens/diagnosis_flow.dart';
import 'screens/all_reminders_screen.dart';
import 'screens/community_feed.dart';
import 'screens/profile_screens.dart';
import 'screens/marketplace_onboarding.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlantPal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentGreen,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AppEntry(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/sign-up':
            return MaterialPageRoute(
              builder: (_) => const SignUpScreen(),
            );
          case '/login':
            return MaterialPageRoute(
              builder: (_) => const LogInScreen(),
            );
          case '/forgot-password':
            return MaterialPageRoute(
              builder: (_) => const ForgotPasswordScreen(),
            );
          case '/home':
            return MaterialPageRoute(
              builder: (_) => const HomeDashboard(),
            );
          case '/notifications':
            return MaterialPageRoute(
              builder: (_) => const NotificationInbox(),
            );
          case '/my-plants':
            return MaterialPageRoute(
              builder: (_) => const MyPlantsScreen(),
            );
          case '/scan':
            return MaterialPageRoute(
              builder: (_) => const CameraCaptureScreen(),
            );
          case '/diagnose':
            return MaterialPageRoute(
              builder: (_) => const DiagnoseCaptureScreen(),
            );
          case '/diagnosis-history':
            return MaterialPageRoute(
              builder: (_) => const DiagnosisHistoryScreen(),
            );
          case '/reminders':
            return MaterialPageRoute(
              builder: (_) => const AllRemindersScreen(),
            );
          case '/community':
            return MaterialPageRoute(
              builder: (_) => const CommunityFeedScreen(),
            );
          case '/profile':
            return MaterialPageRoute(
              builder: (_) => const ProfileScreen(),
            );
          case '/weather':
            return MaterialPageRoute(
              builder: (_) => const WeatherDetailScreen(),
            );
          case '/onboarding':
            return MaterialPageRoute(
              builder: (routeContext) => MarketplaceOnboarding(
                onComplete: () {
                  Navigator.of(routeContext).pushReplacementNamed('/home');
                },
              ),
            );
          default:
            // Handle /plant/{id} dynamic routes
            if (settings.name != null && settings.name!.startsWith('/plant/')) {
              final id = int.tryParse(settings.name!.replaceFirst('/plant/', ''));
              if (id != null) {
                return MaterialPageRoute(
                  builder: (_) => PlantDetailScreen(plantId: id),
                );
              }
            }

            return MaterialPageRoute(
              builder: (_) => const AppEntry(),
            );
        }
      },
    );
  }
}

/// Handles splash → onboarding → (future: home) routing.
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    if (useMockData) {
      // In mock mode: skip splash + onboarding, go straight to home with mock token
      _showSplash = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        TokenStore.save('mock_token', 'mock_refresh');
        Navigator.of(context).pushReplacementNamed('/home');
      });
    }
  }

  void _onSplashDone() {
    setState(() => _showSplash = false);
  }


  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onDone: _onSplashDone);
    }
    return MarketplaceOnboarding(
      onComplete: () {
        Navigator.of(context).pushReplacementNamed('/home');
      },
    );
  }
}
