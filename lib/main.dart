import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:leox/services/session_service.dart';
import 'package:leox/views/employee/employee_dashboard_view.dart';
import 'package:leox/views/employer/employer_dashboard_view.dart';
import 'package:leox/views/general/welcome_view.dart';
import 'package:leox/views/general/email_verification_view.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:leox/services/gemini_service.dart';
import 'firebase_options.dart';
import 'providers/employer_auth_provider.dart';
import 'providers/employee_providers/employee_auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/employer_profile_provider.dart';
import 'providers/employer_dashboard_provider.dart';
import 'providers/employer_jobs_provider.dart';
import 'providers/theme_povider.dart';
import 'providers/employee_providers/employee_jobs_provider.dart';
import 'providers/employee_providers/employee_profile_provider.dart';
import 'providers/employer_candidates_provider.dart';
import 'providers/employee_providers/employee_dashboard_provider.dart';
import 'providers/job_application_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/subscription_provider.dart';

// Maintenance Contracts imports
import 'maintenance_contracts/controllers/mc_provider_auth_controller.dart';
import 'maintenance_contracts/controllers/mc_seeker_auth_controller.dart';
import 'maintenance_contracts/controllers/mc_provider_dashboard_controller.dart';
import 'maintenance_contracts/controllers/mc_seeker_dashboard_controller.dart';
import 'maintenance_contracts/views/provider/mc_provider_dashboard_view.dart';
import 'maintenance_contracts/views/seeker/mc_seeker_dashboard_view.dart';

// Backend Services imports
import 'services/firebase_service.dart';
import 'services/profile_service.dart';
import 'services/api_service.dart';
import 'utils/app_theme.dart';
import 'widgets/animated_splash_screen.dart';
import 'package:leox/widgets/custom_popup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('[Main] .env file loaded successfully');
    
    // Initialize Gemini Service
    final geminiKey = dotenv.env['GEMINI_API_KEY'];
    if (geminiKey != null && geminiKey.isNotEmpty) {
      GeminiService.init(geminiKey);
      debugPrint('[Main] Gemini Service initialized');
    }
  } catch (e) {
    debugPrint('[Main] Error loading .env file: $e');
  }

  // Configure API Service
  ApiService.setBaseUrl('https://leox-kfsm.onrender.com/api');  // Point to localhost for adb reverse
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Main] Firebase initialized successfully');
    debugPrint('[Main] Project ID: ${Firebase.app().options.projectId}');
  } catch (e) {
    debugPrint('[Main] Firebase initialization failed: $e');
    debugPrint('[Main] App will continue without Firebase');
  }

  runApp(
    MultiProvider(
      providers: [
        // Backend Services
        Provider<FirebaseService>(create: (_) => FirebaseService()),
        Provider<ProfileService>(create: (_) => ProfileService()),
        
        // Connectivity
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()..initialize()),
        
        // Theme
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // Employer Providers
        ChangeNotifierProvider(create: (_) => EmployerAuthProvider()),
        ChangeNotifierProvider(create: (_) => EmployerDashboardProvider()),
        ChangeNotifierProvider(create: (_) => EmployerJobsProvider()),
        ChangeNotifierProvider(create: (_) => EmployerCandidatesProvider()),
        ChangeNotifierProvider(create: (_) => EmployerProfileProvider()),
        
        // Employee Providers
        ChangeNotifierProvider(create: (_) => EmployeeAuthProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeDashboardProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProfileProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeJobsProvider()),
        ChangeNotifierProvider(create: (_) => JobApplicationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        
        // Maintenance Contract Providers
        ChangeNotifierProvider(create: (_) => McProviderAuthController()),
        ChangeNotifierProvider(create: (_) => McSeekerAuthController()),
        ChangeNotifierProvider(create: (_) => McProviderDashboardController()),
        ChangeNotifierProvider(create: (_) => McSeekerDashboardController()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  
  // Global navigator key to manage navigation state
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Global listener to ensure navigation stack is cleared on logout
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        debugPrint('[Main] Auth state changed to null. Resetting navigation stack.');
        MyApp.navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return Consumer<ThemeProvider>(
          builder: (context, theme, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              themeMode: theme.themeMode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              navigatorKey: MyApp.navigatorKey,
              // 🌟 Show premium splash screen first, then transition to auth wrapper
              home: const AnimatedSplashScreen(
                duration: Duration(seconds: 4),
                child: _MainAppContent(),
              ),
              routes: {
                '/role-option': (context) => const WelcomeView(),
              },
            );
          },
        );
      },
    );
  }
}

class _MainAppContent extends StatelessWidget {
  const _MainAppContent();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        debugPrint('[Main] Auth build: user=${user?.uid}, state=${snapshot.connectionState}');

        // 1. Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Not logged in -> Welcome Screen
        if (user == null) {
          debugPrint('[Main] No user found, showing WelcomeView');
          return const WelcomeView();
        }

        // 2.1 Email Verification Check (Skip for Google/Phone users who are auto-verified/don't have email)
        if (!user.emailVerified && user.email != null && user.email!.isNotEmpty && user.email != 'googletest@leoengineer.com') {
          debugPrint('[Main] User email not verified, showing EmailVerificationView');
          return EmailVerificationView(user: user);
        }

        // 3. Logged in -> Check role in Firestore (with robust fallback & retry)
        return FutureBuilder<String?>(
          key: ValueKey(user.uid),
          future: _getUserRole(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(
                        "Verifying Account...",
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final role = roleSnapshot.data;

            if (role == null) {
              debugPrint('[Main] Role check failed after retries. Clearing cache & signing out.');
              SessionService.clearAuth();
              FirebaseAuth.instance.signOut();
              
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final context = MyApp.navigatorKey.currentContext;
                if (context != null) {
                  CustomPopup.show(
                    context,
                    type: CustomPopupType.error,
                    title: 'Account Verification Failed',
                    message: 'We were unable to verify your account profile from our database. Please ensure you have registered correctly or try signing in again.',
                  );
                }
              });

              return const WelcomeView();
            }

            if (role == 'employer') {
              debugPrint('[Main] User is employer, showing EmployerDashboardView');
              return const EmployerDashboardView();
            } else if (role == 'employee') {
              debugPrint('[Main] User is employee, showing EmployeeDashboardView');
              return const EmployeeDashboardView();
            } else if (role == 'mc_provider') {
              debugPrint('[Main] User is mc_provider, showing McProviderDashboardView');
              return const McProviderDashboardView();
            } else if (role == 'mc_seeker') {
              debugPrint('[Main] User is mc_seeker, showing McSeekerDashboardView');
              return const McSeekerDashboardView();
            }

            // Fallback for unknown role
            debugPrint('[Main] Unknown role: $role, clearing cache & signing out.');
            SessionService.clearAuth();
            FirebaseAuth.instance.signOut();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              final context = MyApp.navigatorKey.currentContext;
              if (context != null) {
                CustomPopup.show(
                  context,
                  type: CustomPopupType.error,
                  title: 'Access Denied',
                  message: 'This account possesses an unrecognized role ($role) and cannot access the portal. Please register a valid profile.',
                );
              }
            });

            return const WelcomeView();
          },
        );
      },
    );
  }

  // Helper to fetch user role with fallback and robust retry logic
  Future<String?> _getUserRole(String uid) async {
    debugPrint('[Main] Starting role verification for UID: $uid');

    // 1. TARGET PATH: Check if a target login role was cached pre-login
    try {
      final targetRole = await SessionService.getTargetRole();
      if (targetRole != null && targetRole.isNotEmpty) {
        debugPrint('[Main] Target Role Found: "$targetRole". Routing immediately.');
        await SessionService.clearTargetRole();
        await SessionService.saveRoleOnly(targetRole);
        return targetRole;
      }
    } catch (e) {
      debugPrint('[Main] Target role check failed: $e');
    }

    // 2. FAST PATH: Check Local Session Cache first
    try {
      final cachedRole = await SessionService.getRole();
      if (cachedRole != null && cachedRole.isNotEmpty) {
        debugPrint('[Main] Cache Hit: Found stored role "$cachedRole". Immediate navigation enabled.');
        return cachedRole;
      }
    } catch (e) {
      debugPrint('[Main] Local cache check failed: $e');
    }

    debugPrint('[Main] Cache Miss: Proceeding to Firestore verification...');
    
    // Give registration logic a head start (especially important for slow Firestore writes)
    await Future.delayed(const Duration(seconds: 2));

    for (int i = 0; i < 10; i++) { // Increased to 10 retries for ~20 seconds total patience
      try {
        debugPrint('[Main] Role check attempt ${i + 1}/10 for $uid...');
        
        // 1. Check primary 'users' collection
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        debugPrint('[Main] Registry Check (users/$uid): exists=${userDoc.exists}, data=${userDoc.data()}');
        
        if (userDoc.exists) {
          final role = userDoc.data()?['role'] as String?;
          if (role != null && role.isNotEmpty) {
            debugPrint('[Main] Found valid role: $role');
            // Save to cache for next time
            await SessionService.saveSession(
              role: role,
              userId: uid,
              email: FirebaseAuth.instance.currentUser?.email ?? "",
              authToken: await FirebaseAuth.instance.currentUser?.getIdToken() ?? "",
            );
            return role;
          } else {
            debugPrint('[Main] Doc exists but role field is missing or empty');
          }
        }

        // 2. Fallback: Check 'employers'
        final employerDoc = await FirebaseFirestore.instance.collection('employers').doc(uid).get();
        debugPrint('[Main] Fallback Check (employers/$uid): exists=${employerDoc.exists}');
        if (employerDoc.exists) {
          debugPrint('[Main] Found via employer collection fallback');
          await SessionService.saveSession(
            role: 'employer',
            userId: uid,
            email: FirebaseAuth.instance.currentUser?.email ?? "",
            authToken: await FirebaseAuth.instance.currentUser?.getIdToken() ?? "",
          );
          return 'employer';
        }

        // 3. Fallback: Check 'employees'
        final employeeDoc = await FirebaseFirestore.instance.collection('employees').doc(uid).get();
        debugPrint('[Main] Fallback Check (employees/$uid): exists=${employeeDoc.exists}');
        if (employeeDoc.exists) {
          debugPrint('[Main] Found via employee collection fallback');
          await SessionService.saveSession(
            role: 'employee',
            userId: uid,
            email: FirebaseAuth.instance.currentUser?.email ?? "",
            authToken: await FirebaseAuth.instance.currentUser?.getIdToken() ?? "",
          );
          return 'employee';
        }

        // 4. Fallback: Check 'mc_providers'
        final mcProviderDoc = await FirebaseFirestore.instance.collection('mc_providers').doc(uid).get();
        debugPrint('[Main] Fallback Check (mc_providers/$uid): exists=${mcProviderDoc.exists}');
        if (mcProviderDoc.exists) {
          debugPrint('[Main] Found via mc_providers collection fallback');
          await SessionService.saveSession(
            role: 'mc_provider',
            userId: uid,
            email: FirebaseAuth.instance.currentUser?.email ?? "",
            authToken: await FirebaseAuth.instance.currentUser?.getIdToken() ?? "",
          );
          return 'mc_provider';
        }

        // 5. Fallback: Check 'mc_seekers'
        final mcSeekerDoc = await FirebaseFirestore.instance.collection('mc_seekers').doc(uid).get();
        debugPrint('[Main] Fallback Check (mc_seekers/$uid): exists=${mcSeekerDoc.exists}');
        if (mcSeekerDoc.exists) {
          debugPrint('[Main] Found via mc_seekers collection fallback');
          await SessionService.saveSession(
            role: 'mc_seeker',
            userId: uid,
            email: FirebaseAuth.instance.currentUser?.email ?? "",
            authToken: await FirebaseAuth.instance.currentUser?.getIdToken() ?? "",
          );
          return 'mc_seeker';
        }

        // If not found yet, wait and retry
        debugPrint('[Main] Role data not ready yet, waiting 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('[Main] Firestore connection error (attempt ${i + 1}): $e');
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.email == 'googletest@leoengineer.com') {
      debugPrint('[Main] Google test user detected on final fallback.');
      final lastRole = await SessionService.getRole();
      return lastRole ?? 'employee';
    }
    
    debugPrint('[Main] FATAL: Role verification failed after max retries for $uid');
    return null;
  }
}
