import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:leox/services/session_service.dart';
import '../models/mc_provider_model.dart';

class McProviderAuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: (!kIsWeb && Platform.isIOS) ? '340682426505-9gpg37b8g1ctmrna8ps3bnlpq2cood0g.apps.googleusercontent.com' : null,
    serverClientId: '340682426505-q2q1h7ooeua23piinorknvbcu0scma06.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  McProviderModel? _currentProvider;
  McProviderModel? get currentProvider => _currentProvider;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<String?> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint("Error signing out from Google Sign-In: $e");
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return "Sign-In cancelled by user";
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {

        final doc = await _firestore.collection('mc_providers').doc(user.uid).get();
        if (!doc.exists) {
          await _auth.signOut();
          _isLoading = false;
          notifyListeners();
          return "No provider profile found. Please register first.";
        }
        _currentProvider = McProviderModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);

        // Sync with primary 'users' collection
        await _firestore.collection('users').doc(user.uid).set({
          'id': user.uid,
          'email': user.email ?? '',
          'role': 'mc_provider',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Save session in local cache for role tracking
        final idToken = await user.getIdToken();
        await SessionService.saveSession(
          role: "mc_provider",
          userId: user.uid,
          email: user.email ?? "",
          authToken: idToken ?? "",
        );
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> signUpWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint("Error signing out from Google Sign-In: $e");
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return "Sign-In cancelled by user";
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {

        final doc = await _firestore.collection('mc_providers').doc(user.uid).get();
        if (doc.exists) {
          _currentProvider = McProviderModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        } else {
          final newProvider = McProviderModel(
            id: user.uid,
            companyName: googleUser.displayName ?? 'New Company',
            email: googleUser.email,
            phone: '',
            location: '',
            rating: 0.0,
            profilePicture: googleUser.photoUrl ?? '',
          );
          await _firestore.collection('mc_providers').doc(newProvider.id).set(newProvider.toJson());
          _currentProvider = newProvider;
        }

        // Sync with primary 'users' collection
        await _firestore.collection('users').doc(user.uid).set({
          'id': user.uid,
          'email': user.email ?? '',
          'role': 'mc_provider',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Save session in local cache for role tracking
        final idToken = await user.getIdToken();
        await SessionService.saveSession(
          role: "mc_provider",
          userId: user.uid,
          email: user.email ?? "",
          authToken: idToken ?? "",
        );
      }

      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> fetchProviderProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('mc_providers').doc(uid).get();
      if (doc.exists) {
        _currentProvider = McProviderModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching provider profile: $e");
    }
  }

  Future<String?> registerWithEmail(String email, String password, String companyName, String phone, String location) async {
    _isLoading = true;
    notifyListeners();
    try {
      UserCredential userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      } on FirebaseAuthException catch (authEx) {
        if (authEx.code == 'email-already-in-use') {
          debugPrint('[McProviderAuthController] Email already in use. Checking credentials and MC provider profile...');
          userCredential = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
          
          final doc = await _firestore.collection('mc_providers').doc(userCredential.user!.uid).get();
          if (doc.exists) {
            throw FirebaseAuthException(
              code: 'email-already-in-use',
              message: 'A provider account already exists with this email. Please sign in instead.',
            );
          }
          
          debugPrint('[McProviderAuthController] Existing user authenticated. Creating provider profile...');
        } else {
          rethrow;
        }
      }
      
      McProviderModel newProvider = McProviderModel(
        id: userCredential.user!.uid,
        companyName: companyName,
        email: email,
        phone: phone,
        location: location,
        rating: 0.0,
        profilePicture: '',
      );

      await _firestore.collection('mc_providers').doc(newProvider.id).set(newProvider.toJson());
      _currentProvider = newProvider;
      
      // Sync with primary 'users' collection
      await _firestore.collection('users').doc(newProvider.id).set({
        'id': newProvider.id,
        'email': email,
        'role': 'mc_provider',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Send email verification link
      try {
        await userCredential.user?.sendEmailVerification();
      } catch (e) {
        debugPrint('[McProviderAuthController] Error sending email verification: $e');
      }

      // Save target role & session in local cache for role tracking
      await SessionService.saveTargetRole("mc_provider");
      final idToken = await userCredential.user?.getIdToken();
      await SessionService.saveSession(
        role: "mc_provider",
        userId: newProvider.id,
        email: email,
        authToken: idToken ?? "",
      );

      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Incorrect password for the existing account registered with this email.';
      }
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> loginWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      var doc = await _firestore.collection('mc_providers').doc(userCredential.user!.uid).get();
      if (!doc.exists) {
        if (userCredential.user!.email == 'googletest@leoengineer.com') {
          final newProvider = McProviderModel(
            id: userCredential.user!.uid,
            companyName: 'Google Test Provider',
            email: userCredential.user!.email ?? '',
            phone: '9999999999',
            location: 'Test Location',
            rating: 5.0,
            profilePicture: '',
          );
          await _firestore.collection('mc_providers').doc(newProvider.id).set(newProvider.toJson());
          doc = await _firestore.collection('mc_providers').doc(userCredential.user!.uid).get();
        } else {
          await _auth.signOut();
          _isLoading = false;
          notifyListeners();
          return 'This account is not registered as a service provider. Please register as a provider first.';
        }
      }
      
      _currentProvider = McProviderModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      
      // Sync with primary 'users' collection
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'role': 'mc_provider',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Save session in local cache for role tracking
      final idToken = await userCredential.user?.getIdToken();
      await SessionService.saveSession(
        role: "mc_provider",
        userId: userCredential.user!.uid,
        email: email,
        authToken: idToken ?? "",
      );

      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> logout() async {
    try {
      await SessionService.clearAuth();
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint("Error signing out from Google: $e");
    }
    await _auth.signOut();
    _currentProvider = null;
    notifyListeners();
  }

  Future<void> updateProviderProfile({
    required String companyName,
    required String phone,
    required String location,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _firestore.collection('mc_providers').doc(user.uid).update({
        'companyName': companyName,
        'phone': phone,
        'location': location,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update local state
      if (_currentProvider != null) {
        _currentProvider = McProviderModel(
          id: _currentProvider!.id,
          companyName: companyName,
          email: _currentProvider!.email,
          phone: phone,
          location: location,
          rating: _currentProvider!.rating,
          profilePicture: _currentProvider!.profilePicture,
        );
      }
    } catch (e) {
      debugPrint("Error updating provider profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> deleteAccount() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return "No user logged in";
      }
      final providerId = user.uid;

      // 2. Delete from Firebase Storage (Profile Picture)
      try {
        await FirebaseStorage.instance
            .ref()
            .child('maintenance_contracts/profiles/$providerId')
            .delete();
      } catch (e) {
        // Ignore if file doesn't exist or deletion fails
        debugPrint("Error deleting provider profile picture from storage: $e");
      }

      // 3. Delete related data in Firestore
      // 3a. Delete services offered by this provider
      final servicesSnapshot = await _firestore
          .collection('mc_services')
          .where('providerId', isEqualTo: providerId)
          .get();
      for (var doc in servicesSnapshot.docs) {
        await doc.reference.delete();
      }

      // 3b. Delete incoming requests for this provider
      final requestsSnapshot = await _firestore
          .collection('mc_requests')
          .where('providerId', isEqualTo: providerId)
          .get();
      for (var doc in requestsSnapshot.docs) {
        await doc.reference.delete();
      }

      // 3c. Delete reviews for this provider
      final reviewsSnapshot = await _firestore
          .collection('mc_reviews')
          .where('providerId', isEqualTo: providerId)
          .get();
      for (var doc in reviewsSnapshot.docs) {
        await doc.reference.delete();
      }

      // 3d. Delete the provider's profile document
      await _firestore.collection('mc_providers').doc(providerId).delete();

      // 4. Delete user from Firebase Auth
      await user.delete();

      _currentProvider = null;
      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }
}
