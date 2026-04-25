import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'constants/app_theme.dart';
import 'pages/splash_screen.dart';
import 'pages/login_page.dart';
import 'pages/registration_page.dart';
import 'pages/home_page.dart';
import 'pages/events_page.dart';
import 'pages/add_event_page.dart';
import 'pages/event_detail_page.dart';
import 'pages/registered_events_page.dart';
import 'pages/calendar_page.dart';
import 'pages/societies_page.dart';
import 'pages/profile_page.dart';
import 'pages/expenses_page.dart';
import 'pages/bookmarks_page.dart';
import 'pages/announcements_page.dart';
import 'pages/event_approval_page.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/reports_page.dart';
import 'pages/faq_page.dart';
import 'pages/poll_page.dart';
import 'pages/qr_generate_page.dart';
import 'pages/qr_scan_page.dart';
import 'pages/public_events_page.dart';
import 'pages/chatbot_page.dart';
// New settings pages
import 'pages/notification_settings_page.dart';
import 'pages/privacy_settings_page.dart';
import 'pages/change_password_page.dart';
import 'pages/account_settings_page.dart';
import 'pages/global_search_page.dart';
import 'pages/attended_events_page.dart';
import 'pages/event_attendance_list_page.dart';
import 'pages/landing_page.dart';
import 'pages/welcome_screen.dart';
import 'pages/edit_profile_page.dart';
import 'services/auth_service.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';
import 'services/cache_service.dart';
import 'services/offline_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env for development
  // For production builds, use: flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  String supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  String supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

  // Fallback to .env file if --dart-define values are not set (development mode)
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    await dotenv.load(fileName: ".env");
    supabaseUrl = dotenv.env['SUPABASE_URL']!;
    supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Initialize auth state (checks if user is already logged in)
  await AuthService.initializeAuth();

  // Initialize Cache Service (Hive for offline support)
  await CacheService.initialize();

  // Load persisted settings (theme, notifications, privacy)
  await SettingsService.loadSettings();

  // Initialize Offline Service (connectivity + action queue)
  await OfflineService.initialize();

  // Initialize Push Notifications (Firebase)
  await NotificationService.initialize();

  // Wrap app with Riverpod ProviderScope
  runApp(const ProviderScope(child: EventManagementApp()));
}


class EventManagementApp extends StatefulWidget {
  const EventManagementApp({super.key});

  @override
  State<EventManagementApp> createState() => _EventManagementAppState();
}

class _EventManagementAppState extends State<EventManagementApp> {
  @override
  void initState() {
    super.initState();
    // Listen to settings changes for theme updates
    SettingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    SettingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Sphere',
      navigatorKey: NotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,

      // Dynamic theme based on settings
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: SettingsService.themeMode,

      // Custom page transitions for dramatic effect
      onGenerateRoute: (settings) {
        Widget page;

        // Handle routes with arguments
        switch (settings.name) {
          case '/event-detail':
            // Deep link format: eventsphere://event-detail?id=<eventId>
            // When opened via share link, arguments contain the event UUID.
            // ShareService generates links using this route.
            final eventId = settings.arguments as String;
            page = EventDetailPage(eventId: eventId);
            break;
          case '/qr-generate':
            final eventId = settings.arguments as String;
            page = QrGeneratePage(eventId: eventId);
            break;
          case '/public-events':
            final userRole = settings.arguments as String;
            page = PublicEventsPage(userRole: userRole);
            break;
          case '/registered-events':
            final user = AuthService.getCurrentUser();
            final supabaseUser = Supabase.instance.client.auth.currentUser;
            final userId = user?.id ?? supabaseUser?.id;
            page = userId != null
                ? RegisteredEventsPage(userId: userId)
                : const LoginPage();
            break;
          case '/add-event':
            final args = settings.arguments as Map<String, dynamic>?;
            page = AddEventPage(
              preSeletedSocietyId: args?['societyId'],
              preSeletedSocietyName: args?['societyName'],
            );
            break;
          default:
            // Handle named routes
            page = _getPageForRoute(settings.name);
        }

        return _createPageRoute(page, settings);
      },

      home: const SplashScreen(),
    );
  }

  Widget _getPageForRoute(String? routeName) {
    switch (routeName) {
      case '/':
      case '/splash':
        return const SplashScreen();
      case '/landing':
        return const LandingPage();
      case '/welcome':
        return const WelcomeScreen();
      case '/login':
        return const LoginPage();
      case '/register':
        return const RegistrationPage();
      case '/home':
        return const HomePage();
      case '/events':
        return const EventsPage();
      case '/calendar':
        return const CalendarPage();
      case '/societies':
        return const SocietiesPage();
      case '/profile':
        return const ProfilePage();
      case '/expenses':
        return const ExpensesPageRedesigned();
      case '/bookmarks':
        return const BookmarksPage();
      case '/attended-events':
        return const AttendedEventsPage();
      case '/announcements':
        return const AnnouncementsPage();
      case '/event-approval':
        return const EventApprovalPage();
      case '/admin-dashboard':
        return const AdminDashboardPage();
      case '/event-attendance':
        return const EventAttendanceListPage();
      case '/reports':
        return const ReportsPage();
      case '/faq':
        return FaqPageRedesigned();
      case '/poll':
        return const PollPageRedesigned();
      case '/qr-scan':
        return const QrScanPage();
      case '/chatbot':
        return const ChatbotPage();
      // Settings pages
      case '/notification-settings':
        return const NotificationSettingsPage();
      case '/privacy-settings':
        return const PrivacySettingsPage();
      case '/change-password':
        return const ChangePasswordPage();
      case '/account-settings':
        return const AccountSettingsPage();
      case '/edit-profile':
        return const EditProfilePage();
      case '/search':
        return const GlobalSearchPage();
      case '/forgot-password':
        return const ChangePasswordPage();
      default:
        return const SplashScreen();
    }
  }

  PageRouteBuilder _createPageRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Dramatic slide + fade transition
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        var scaleTween = Tween(begin: 0.95, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: ScaleTransition(
              scale: animation.drive(scaleTween),
              child: child,
            ),
          ),
        );
      },
      transitionDuration: AppDurations.normal,
      reverseTransitionDuration: AppDurations.fast,
    );
  }
}
