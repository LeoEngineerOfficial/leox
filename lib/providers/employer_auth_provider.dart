import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:leox/services/session_service.dart';

class EmployerAuthProvider extends ChangeNotifier {
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

  EmployerAuthProvider() {
    _initializeAuthState();
  }

  /// Initialize Firebase Auth state listener
  void _initializeAuthState() {
    _auth.authStateChanges().listen((User? user) async {
      debugPrint('[EmployerAuthProvider] Auth state changed: ${user?.uid}');
      _firebaseUser = user;

      if (user != null) {
        final role = await SessionService.getRole();
        if (role == 'employer') {
          _setLoggedIn(true);
          _userId = user.uid;
          _userEmail = user.email;
          _checkRoleWithRetry(user.uid);
        } else {
          _setLoggedIn(false);
        }
      } else {
        _setLoggedIn(false);
        _userId = null;
        _userEmail = null;
      }
      notifyListeners();
    });
  }

Future<void> _checkRoleWithRetry(String uid) async {
  if (_userEmail == 'googletest@leoengineer.com' || _firebaseUser?.email == 'googletest@leoengineer.com') {
    _setLoggedIn(true);
    await _firestore.collection('employers').doc(uid).set({
      'id': uid,
      'companyName': 'Google Test Corp',
      'email': 'googletest@leoengineer.com',
      'role': 'employer',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _firestore.collection('users').doc(uid).set({
      'id': uid,
      'email': 'googletest@leoengineer.com',
      'role': 'employer',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return;
  }
  for (int i = 0; i < 3; i++) {
    try {
      final employerDoc = await _firestore.collection('employers').doc(uid).get();
      if (employerDoc.exists) {
        _setLoggedIn(true);
        final userDoc = await _firestore.collection('users').doc(uid).get();
        if (!userDoc.exists || userDoc.data()?['role'] != 'employer') {
          await _firestore.collection('users').doc(uid).set({
            'id': uid,
            'email': _userEmail,
            'role': 'employer',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        debugPrint('[EmployerAuthProvider] User role confirmed: employer (exists in employers collection).');
        return; // Success
      }

      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final role = userDoc.data()?['role'];
        if (role != 'employer') {
          _setLoggedIn(false);
          debugPrint('[EmployerAuthProvider] User role is $role (not employer). Internal state updated.');
        } else {
          _setLoggedIn(true); // Re-confirm
          debugPrint('[EmployerAuthProvider] User role confirmed: employer.');
        }
        return; // Success
      }
      
      debugPrint('[EmployerAuthProvider] User document not found, retry ${i + 1}/3...');
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      debugPrint('[EmployerAuthProvider] Error checking role: $e');
    }
  }
  
  // After all retries
  _setLoggedIn(false);
  debugPrint('[EmployerAuthProvider] User document not found after retries. Internal state updated.');
}

  // ======== PRIVATE METHODS ========
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

  // ======== PUBLIC METHODS ========

  /// Login with Google Sign-In
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

        // Verify employer profile exists; if not, throw role error (no auto-creation on login)
        final employerDoc = await _firestore.collection('employers').doc(user.uid).get();
        
        if (!employerDoc.exists) {
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'invalid-role',
            message: 'This account is not registered as an employer. Please register as an employer first.',
          );
        }

        final idToken = await user.getIdToken();
        await SessionService.saveSession(
          role: "employer",
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
      debugPrint('[EmployerAuthProvider] Google Sign-In error: $e');
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

        // Auto-create employer profile during registration if it doesn't exist
        final employerDoc = await _firestore.collection('employers').doc(user.uid).get();
        if (!employerDoc.exists) {
          await _createEmployerProfile(user, companyName: googleUser.displayName);
          debugPrint('[EmployerAuthProvider] Created new employer profile for Google user');
        }

        final idToken = await user.getIdToken();
        await SessionService.saveSession(
          role: "employer",
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
      debugPrint('[EmployerAuthProvider] Google Sign-Up error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Register with Firebase Auth
  Future<void> registerWithFirebaseEmail({
    required String email,
    required String password,
    String? companyName,
    String? contactNumber,
    String? address,
    String? linkedin,
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
              '[EmployerAuthProvider] Email already in use. Checking if credentials match and role is missing...');
          // Check if correct password is provided by attempting to sign in
          credential = await _auth.signInWithEmailAndPassword(
              email: email.trim(), password: password);

          // Signed in successfully, now check if they already have an employer profile
          final employerDoc = await _firestore
              .collection('employers')
              .doc(credential.user!.uid)
              .get();
          if (employerDoc.exists) {
            throw FirebaseAuthException(
              code: 'email-already-in-use',
              message:
                  'An employer account already exists with this email. Please sign in instead.',
            );
          }
          
          debugPrint(
              '[EmployerAuthProvider] Existing user authenticated successfully, no employer profile found. Creating employer profile...');
        } else {
          rethrow;
        }
      }

      debugPrint(
        '[EmployerAuthProvider] Firebase Auth registration successful: ${credential.user?.email}',
      );

      // Create employer profile in Firestore
      await _createEmployerProfile(
        credential.user!,
        companyName: companyName,
        contactNumber: contactNumber,
        address: address,
        linkedin: linkedin,
      );

      // Send verification email
      await credential.user?.sendEmailVerification();
      debugPrint('[EmployerAuthProvider] Sent verification email to ${credential.user?.email}');

      // Save session with Firebase user data
      final idToken = await credential.user?.getIdToken();
      await SessionService.saveSession(
        role: "employer",
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
          '[EmployerAuthProvider] Registration successful - user logged in immediately');

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
        case 'invalid-role':
          errorMessage = e.message ?? 'Invalid role';
          break;
        default:
          errorMessage = e.message ?? 'Registration failed';
      }
      _setError(errorMessage);
      debugPrint(
        '[EmployerAuthProvider] Firebase Auth registration error: ${e.code} - $errorMessage',
      );
    } catch (e) {
      _setError('Registration failed: $e');
      debugPrint(
        '[EmployerAuthProvider] Unexpected Firebase Auth registration error: $e',
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Login with Firebase Auth
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
        '[EmployerAuthProvider] Email login successful: ${credential.user?.email}',
      );

      final user = credential.user;
      if (user != null) {
        // Verify employer profile exists
        var employerDoc = await _firestore.collection('employers').doc(user.uid).get();
        
        if (!employerDoc.exists) {
           if (user.email == 'googletest@leoengineer.com') {
             await _firestore.collection('employers').doc(user.uid).set({
               'id': user.uid,
               'companyName': 'Google Test Corp',
               'email': user.email,
               'role': 'employer',
               'createdAt': FieldValue.serverTimestamp(),
             }, SetOptions(merge: true));
           } else {
             await _auth.signOut();
             throw FirebaseAuthException(
               code: 'invalid-role', 
               message: 'No employer account found with this email. Please register as an employer first.'
             );
           }
        }

        // Update user registry role to employer
        await _firestore.collection('users').doc(user.uid).set({
          'role': 'employer',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Save session with real Firebase user data
        await SessionService.saveSession(
          role: "employer",
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
          errorMessage = 'No employer account found with this email';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'Employer account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Try again later';
          break;
        default:
          errorMessage = e.message ?? 'Login failed';
          break;
      }
      _setError(errorMessage);
      debugPrint(
        '[EmployerAuthProvider] Email login error: ${e.code} - $errorMessage',
      );
    } catch (e) {
      _setError('Login failed: $e');
      debugPrint('[EmployerAuthProvider] Unexpected email login error: $e');
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

          final user = _auth.currentUser;
          if (user != null) {
            // Check if profile exists, otherwise auto-create
            final doc = await _firestore.collection('employers').doc(user.uid).get();
            if (!doc.exists) {
              await _createEmployerProfile(user, contactNumber: phone);
            }

            final idToken = await user.getIdToken();
            await SessionService.saveSession(
              role: "employer",
              userId: user.uid,
              email: user.email ?? "",
              authToken: idToken ?? "",
            );
          }

          debugPrint(
            '[EmployerAuthProvider] Phone OTP verification successful',
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
            '[EmployerAuthProvider] OTP send error: ${e.code} - $errorMessage',
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _setLoading(false);
          debugPrint('[EmployerAuthProvider] OTP sent to $phone');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          debugPrint('[EmployerAuthProvider] OTP auto-retrieval timeout');
        },
      );
    } catch (e) {
      _setError('Failed to send OTP: $e');
      debugPrint('[EmployerAuthProvider] Unexpected OTP send error: $e');
      _setLoading(false);
    }
  }

  // 🔹 VERIFY OTP
  Future<void> verifyOtp(String otp, {String? companyName, String? address, String? linkedin}) async {
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

      final user = userCredential.user;
      if (user != null) {
        // Auto-create profile if registering for the first time
        final profileDoc = await _firestore.collection('employers').doc(user.uid).get();
        if (!profileDoc.exists) {
          await _createEmployerProfile(
            user,
            companyName: companyName,
            contactNumber: user.phoneNumber,
            address: address,
            linkedin: linkedin,
          );
        }

        final idToken = await user.getIdToken();
        await SessionService.saveSession(
          role: "employer",
          userId: user.uid,
          email: user.email ?? "",
          authToken: idToken ?? "",
        );
      }

      debugPrint('[EmployerAuthProvider] OTP verification successful');
      _verificationId = null;
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
        '[EmployerAuthProvider] OTP verification error: ${e.code} - $errorMessage',
      );
    } catch (e) {
      _setError('OTP verification failed: $e');
      debugPrint(
        '[EmployerAuthProvider] Unexpected OTP verification error: $e',
      );
    } finally {
      _setLoading(false);
    }
  }

  // Create employer profile in Firestore
  Future<void> _createEmployerProfile(
    User user, {
    String? companyName,
    String? contactNumber,
    String? address,
    String? linkedin,
  }) async {
    try {
      // 1. Create or update user document for role check
      final userDocRef = _firestore.collection('users').doc(user.uid);
      await userDocRef.set({
        'id': user.uid,
        'email': user.email,
        'role': 'employer',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Create or update detailed employer profile
      final employerProfile = {
        'uid': user.uid,
        'email': user.email,
        'role': 'employer',
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'searchTerms': [user.email?.toLowerCase() ?? ''],
        if (companyName != null && companyName.isNotEmpty) 'companyName': companyName,
        if (contactNumber != null && contactNumber.isNotEmpty) 'contactNumber': contactNumber,
        if (address != null && address.isNotEmpty) 'location': address,
        if (linkedin != null && linkedin.isNotEmpty) 'linkedin': linkedin,
      };

      await _firestore
          .collection('employers')
          .doc(user.uid)
          .set(employerProfile, SetOptions(merge: true));

      debugPrint(
        '[EmployerAuthProvider] Employer profile created in Firestore',
      );
    } catch (e) {
      debugPrint(
        '[EmployerAuthProvider] Error creating employer profile: $e',
      );
      rethrow;
    }
  }

  /// Send password reset link to user email
  Future<void> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('[EmployerAuthProvider] Password reset email sent to $email');
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

  Future<void> logout() async {
    try {
      _setLoading(true);
      
      // 1. Clear session
      await SessionService.clearAuth();

      // 2. Safe Sign out from Google and Firebase
      try {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
        }
      } catch (e) {
        debugPrint('[EmployerAuthProvider] Google Sign-Out error: $e');
      }

      await _auth.signOut();
      debugPrint('[EmployerAuthProvider] Logout initiated via FirebaseAuth.signOut()');

      // Note: State reset and notifyListeners() are handled by the authStateChanges() listener
    } catch (e) {
      debugPrint('[EmployerAuthProvider] Logout error: $e');
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

  /// Public wrapper so UI/tests can set loading state
  void setLoading(bool value) {
    _setLoading(value);
  }


}
