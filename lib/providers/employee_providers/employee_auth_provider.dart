import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:leox/services/session_service.dart';

class EmployeeAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: (!kIsWeb && Platform.isIOS) ? '340682426505-9gpg37b8g1ctmrna8ps3bnlpq2cood0g.apps.googleusercontent.com' : null,
    serverClientId: '340682426505-q2q1h7ooeua23piinorknvbcu0scma06.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  User? _firebaseUser;
  User? get firebaseUser => _firebaseUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  String? _userId;
  String? get userId => _userId;

  String? _userEmail;
  String? get userEmail => _userEmail;

  String? _verificationId;
  String? get verificationId => _verificationId;

  // ======== CONSTRUCTOR ========
  EmployeeAuthProvider() {
    _initializeAuthState();
  }

  /// Initialize Firebase Auth state listener
  void _initializeAuthState() {
    _auth.authStateChanges().listen((User? user) async {
      debugPrint('[EmployeeAuthProvider] Auth state changed: ${user?.uid}');
      
      if (user != null) {
        final role = await SessionService.getRole();
        if (role == 'employee') {
          _setLoggedIn(true);
          _firebaseUser = user;
          _userId = user.uid;
          _userEmail = user.email;
          _checkRoleWithRetry(user.uid);
        } else {
          _setLoggedIn(false);
        }
      } else {
        _setLoggedIn(false);
        _firebaseUser = null;
        _userId = null;
        _userEmail = null;
      }
      notifyListeners();
    });
  }

Future<void> _checkRoleWithRetry(String uid) async {
  if (_userEmail == 'googletest@leoengineer.com' || _firebaseUser?.email == 'googletest@leoengineer.com') {
    _setLoggedIn(true);
    await _firestore.collection('employees').doc(uid).set({
      'id': uid,
      'name': 'Google Reviewer',
      'email': 'googletest@leoengineer.com',
      'role': 'employee',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _firestore.collection('users').doc(uid).set({
      'id': uid,
      'email': 'googletest@leoengineer.com',
      'role': 'employee',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return;
  }
  for (int i = 0; i < 3; i++) {
    try {
      final employeeDoc = await _firestore.collection('employees').doc(uid).get();
      if (employeeDoc.exists) {
        _setLoggedIn(true);
        final userDoc = await _firestore.collection('users').doc(uid).get();
        if (!userDoc.exists || userDoc.data()?['role'] != 'employee') {
          await _firestore.collection('users').doc(uid).set({
            'id': uid,
            'email': _userEmail,
            'role': 'employee',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        debugPrint('[EmployeeAuthProvider] User role confirmed: employee (exists in employees collection).');
        return; // Success
      }

      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final role = userDoc.data()?['role'];
        if (role != 'employee') {
          _setLoggedIn(false);
          debugPrint('[EmployeeAuthProvider] User role is $role (not employee). Internal state updated.');
        } else {
          _setLoggedIn(true); // Re-confirm
          debugPrint('[EmployeeAuthProvider] User role confirmed: employee.');
        }
        return; // Success
      }
      
      debugPrint('[EmployeeAuthProvider] User document not found, retry ${i + 1}/3...');
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      debugPrint('[EmployeeAuthProvider] Error checking role: $e');
    }
  }
  
  // After all retries
  _setLoggedIn(false);
  debugPrint('[EmployeeAuthProvider] User document not found after retries. Internal state updated.');
}


  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _setSuccessMessage(String? message) {
    _successMessage = message;
    notifyListeners();
  }

  void _setLoggedIn(bool value, {String? userId, String? email}) {
    _isLoggedIn = value;
    _userId = userId;
    _userEmail = email;
    notifyListeners();
  }

  Future<void> loginWithEmail(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      // Sign in first
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      debugPrint(
        '[EmployeeAuthProvider] Email login successful: ${credential.user?.email}',
      );

      final user = credential.user;
      if (user != null) {
        // Verify employee profile exists
        var employeeDoc = await _firestore.collection('employees').doc(user.uid).get();
        
        if (!employeeDoc.exists) {
           if (user.email == 'googletest@leoengineer.com') {
             await _firestore.collection('employees').doc(user.uid).set({
               'id': user.uid,
               'name': 'Google Reviewer',
               'email': user.email,
               'role': 'employee',
               'createdAt': FieldValue.serverTimestamp(),
             }, SetOptions(merge: true));
           } else {
             await _auth.signOut();
             throw FirebaseAuthException(
               code: 'invalid-role', 
               message: 'No employee account found with this email. Please register as an employee first.'
             );
           }
        }

        // Update user registry role to employee
        await _firestore.collection('users').doc(user.uid).set({
          'role': 'employee',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Save session with real Firebase user data
        await SessionService.saveSession(
          role: "employee",
          userId: user.uid,
          email: user.email ?? "",
          authToken: await user.getIdToken() ?? "",
        );

        // Manually update internal state for immediate navigation
        _firebaseUser = user;
        _userId = user.uid;
        _userEmail = user.email;
        _isLoggedIn = true;
        notifyListeners();
      }

      // Auth state listener will automatically update state
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No employee account found with this email';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'Employee account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Try again later';
          break;
        case 'invalid-role':
          errorMessage = e.message ?? 'Invalid role';
          break;
        default:
          errorMessage = e.message ?? 'Login failed';
          break;
      }
      _setError(errorMessage);
      debugPrint(
        '[EmployeeAuthProvider] Email login error: ${e.code} - $errorMessage',
      );
    } catch (e) {
      _setError('Login failed: $e');
      debugPrint('[EmployeeAuthProvider] Unexpected email login error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 🔹 SEND OTP
  Future<void> sendOtp(String phone) async {
    _setLoading(true);
    _setError(null);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);

          // Save session with Firebase user data
          final user = _auth.currentUser;
          if (user != null) {
            final idToken = await user.getIdToken();
            await SessionService.saveSession(
              role: "employee",
              userId: user.uid,
              email: user.email ?? "",
              authToken: idToken ?? "",
            );
          }

          debugPrint(
            '[EmployeeAuthProvider] Phone OTP verification successful',
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage = 'Phone verification failed';
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Invalid phone number';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many OTP requests. Try again later';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded';
              break;
          }
          _setError(errorMessage);
          debugPrint(
            '[EmployeeAuthProvider] OTP send error: ${e.code} - $errorMessage',
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _setLoading(false);
          debugPrint('[EmployeeAuthProvider] OTP sent to $phone');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          debugPrint('[EmployeeAuthProvider] OTP auto-retrieval timeout');
        },
      );
    } catch (e) {
      _setError('Failed to send OTP: $e');
      debugPrint('[EmployeeAuthProvider] Unexpected OTP send error: $e');
      _setLoading(false);
    }
  }

  // 🔹 VERIFY OTP
  Future<void> verifyOtp(String otp, {String? name}) async {
    _setLoading(true);
    _setError(null);

    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otp,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Save session with Firebase user data
      final user = userCredential.user;
      if (user != null) {
        // Auto-create profile if registering for the first time
        final profileDoc = await _firestore.collection('employees').doc(user.uid).get();
        if (!profileDoc.exists) {
          await _createEmployeeProfile(user, name: name);
        }

        final idToken = await user.getIdToken();
        await SessionService.saveSession(
          role: "employee",
          userId: user.uid,
          email: user.email ?? "",
          authToken: idToken ?? "",
        );
      }

      debugPrint('[EmployeeAuthProvider] OTP verification successful');

      // Clear verification ID after successful use
      _verificationId = null;

      // Auth state listener will automatically update state
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'OTP verification failed';
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP code';
          break;
        case 'session-expired':
          errorMessage = 'OTP has expired. Please request a new one';
          break;
        case 'quota-exceeded':
          errorMessage = 'Too many failed attempts. Try again later';
          break;
      }
      _setError(errorMessage);
      debugPrint(
        '[EmployeeAuthProvider] OTP verification error: ${e.code} - $errorMessage',
      );
    } catch (e) {
      _setError('OTP verification failed: $e');
      debugPrint(
        '[EmployeeAuthProvider] Unexpected OTP verification error: $e',
      );
    } finally {
      _setLoading(false);
    }
  }

  // ======== GOOGLE SIGN-IN ===
  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);

    try {
      // Ensure Google Sign In is signed out first to force account picker
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _setLoading(false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {

        // Verify employee profile exists; if not, throw role error (no auto-creation on login)
        final employeeDoc = await _firestore.collection('employees').doc(user.uid).get();
        
        if (!employeeDoc.exists) {
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'invalid-role',
            message: 'This account is not registered as an employee. Please register as an employee first.',
          );
        }

        final idToken = await user.getIdToken();
        await SessionService.saveSession(
          role: "employee",
          userId: user.uid,
          email: user.email ?? "",
          authToken: idToken ?? "",
        );

        // Manually update state for immediate UI reaction
        _firebaseUser = user;
        _userId = user.uid;
        _userEmail = user.email;
        _isLoggedIn = true;
        notifyListeners();
      }
    } catch (e) {
      _setError(e is FirebaseAuthException ? e.message : "Google Sign-In failed: $e");
    } finally {
      _setLoading(false);
    }
  }

  /// Sign up with Google (for registration)
  Future<void> signUpWithGoogle() async {
    _setLoading(true);
    _setError(null);

    try {
      await _googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _setLoading(false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {

        // Auto-create employee profile during registration if it doesn't exist
        final employeeDoc = await _firestore.collection('employees').doc(user.uid).get();
        if (!employeeDoc.exists) {
          await _createEmployeeProfile(user, name: googleUser.displayName);
          debugPrint('[EmployeeAuthProvider] Created new employee profile for Google user');
        }

        final idToken = await user.getIdToken();
        await SessionService.saveSession(
          role: "employee",
          userId: user.uid,
          email: user.email ?? "",
          authToken: idToken ?? "",
        );

        _firebaseUser = user;
        _userId = user.uid;
        _userEmail = user.email;
        _isLoggedIn = true;
        notifyListeners();
      }
    } catch (e) {
      _setError(e is FirebaseAuthException ? e.message : "Google Registration failed: $e");
    } finally {
      _setLoading(false);
    }
  }

  // ======== FIREBASE EMAIL REGISTRATION ========

  /// Register with Firebase Auth
  Future<void> registerWithFirebaseEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      UserCredential credential;
      try {
        // Create user with Firebase Auth
        credential = await _auth.createUserWithEmailAndPassword(
            email: email.trim(), password: password);
      } on FirebaseAuthException catch (authEx) {
        if (authEx.code == 'email-already-in-use') {
          debugPrint(
              '[EmployeeAuthProvider] Email already in use. Checking if credentials match and role is missing...');
          // Check if correct password is provided by attempting to sign in
          credential = await _auth.signInWithEmailAndPassword(
              email: email.trim(), password: password);

          // Signed in successfully, now check if they already have an employee profile
          final employeeDoc = await _firestore
              .collection('employees')
              .doc(credential.user!.uid)
              .get();
          if (employeeDoc.exists) {
            throw FirebaseAuthException(
              code: 'email-already-in-use',
              message:
                  'An employee account already exists with this email. Please sign in instead.',
            );
          }
          
          debugPrint(
              '[EmployeeAuthProvider] Existing user authenticated successfully, no employee profile found. Creating employee profile...');
        } else {
          rethrow;
        }
      }

      debugPrint(
        '[EmployeeAuthProvider] Firebase Auth registration successful: ${credential.user?.email}',
      );

      // Create employee profile in Firestore
      await _createEmployeeProfile(credential.user!, name: name);

      // Send verification email
      await credential.user?.sendEmailVerification();
      debugPrint('[EmployeeAuthProvider] Sent verification email to ${credential.user?.email}');

      // Save session with Firebase user data
      final idToken = await credential.user?.getIdToken();
      await SessionService.saveSession(
        role: "employee",
        userId: credential.user?.uid ?? "",
        email: credential.user?.email ?? "",
        authToken: idToken ?? "",
      );

      // Set success message for UI feedback
      _setSuccessMessage('Registration successful! Welcome to LeoOpus.');

      // Manually update auth state to trigger immediate login
      _firebaseUser = credential.user;
      _userId = credential.user!.uid;
      _userEmail = credential.user!.email;
      _isLoggedIn = true;

      notifyListeners();
      debugPrint(
          '[EmployeeAuthProvider] Registration successful - user logged in immediately');

      // Auth state listener will also update state
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed';
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        case 'email-already-in-use':
          errorMessage =
              e.message ?? 'An account already exists with this email';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage =
              'Incorrect password for the existing account registered with this email.';
          break;
        default:
          errorMessage = e.message ?? 'Registration failed';
      }
      _setError(errorMessage);
      debugPrint(
        '[EmployeeAuthProvider] Firebase Auth registration error: ${e.code} - $errorMessage',
      );
    } catch (e) {
      _setError('Registration failed: $e');
      debugPrint(
        '[EmployeeAuthProvider] Unexpected Firebase Auth registration error: $e',
      );
    } finally {
      _setLoading(false);
    }
  }

  // Create employee profile in Firestore
  Future<void> _createEmployeeProfile(User user, {String? name}) async {
    try {
      // 1. Create or update user document for role check
      final userDocRef = _firestore.collection('users').doc(user.uid);
      await userDocRef.set({
        'id': user.uid,
        'email': user.email,
        'role': 'employee',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Create detailed employee profile
      final employeeProfile = {
        'uid': user.uid,
        'email': user.email,
        'firstName': name ?? '',
        'lastName': '',
        'role': 'employee',
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'searchTerms': [user.email?.toLowerCase() ?? ''],
      };

      await _firestore
          .collection('employees')
          .doc(user.uid)
          .set(employeeProfile);

      debugPrint(
        '[EmployeeAuthProvider] Employee profile created in Firestore',
      );

      // Show success message
      _showSuccessMessage('Registration successful! Welcome to LEO OPUS');
    } catch (e) {
      debugPrint('[EmployeeAuthProvider] Error creating employee profile: $e');
      // Don't fail registration if profile creation fails
    }
  }
/*
  // Check if profile exists and repair if missing (for already logged-in users)
  Future<void> _checkAndRepairProfile(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await _createEmployeeProfile(user);
        debugPrint('[EmployeeAuthProvider] Repaired missing employee profile for ${user.uid}');
      }
    } catch (e) {
      debugPrint('[EmployeeAuthProvider] Profile repair check failed: $e');
    }
  }
*/
  /// Show success message
  void _showSuccessMessage(String message) {
    _setSuccessMessage(message);
    debugPrint('[EmployeeAuthProvider] Success: $message');
  }

  /// Send password reset link to user email
  Future<void> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('[EmployeeAuthProvider] Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Failed to send password reset email');
      rethrow;
    } catch (e) {
      _setError('Failed to send password reset email: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ======== LOGOUT ========

  Future<void> logout() async {
    try {
      _setLoading(true);
      
      // 1. Clear session and sign out from Google/Firebase
      await SessionService.clearAuth();
      
      try {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
        }
      } catch (e) {
        debugPrint('[EmployeeAuthProvider] Google Sign-Out error: $e');
      }

      await _auth.signOut();
      debugPrint('[EmployeeAuthProvider] Logout initiated via FirebaseAuth.signOut()');

      // Note: State reset and notifyListeners() are handled by the authStateChanges() listener
    } catch (e) {
      debugPrint('[EmployeeAuthProvider] Logout error: $e');
    } finally {
      _setLoading(false);
    }
  }


  // ======== HELPERS ========

  /// Clear error message (call after showing error to UI)
  void clearError() {
    if (_errorMessage != null) {
      _setError(null);
    }
  }

  /// Clear success message (call after showing success to UI)
  void clearSuccessMessage() {
    _setSuccessMessage(null);
  }

  /// Check if user has pending phone OTP (waiting for verification code)
  bool get isPendingOtpVerification =>
      _verificationId != null && _verificationId!.isNotEmpty;
}
