import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:leox/services/session_service.dart';
import '../models/mc_seeker_model.dart';

class McSeekerAuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: (!kIsWeb && Platform.isIOS) ? '340682426505-9gpg37b8g1ctmrna8ps3bnlpq2cood0g.apps.googleusercontent.com' : null,
    serverClientId: '340682426505-q2q1h7ooeua23piinorknvbcu0scma06.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  McSeekerModel? _currentSeeker;
  McSeekerModel? get currentSeeker => _currentSeeker;
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

        final doc = await _firestore.collection('mc_seekers').doc(user.uid).get();
        if (!doc.exists) {
          await _auth.signOut();
          _isLoading = false;
          notifyListeners();
          return "No seeker profile found. Please register first.";
        }
        _currentSeeker = McSeekerModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);

        // Sync with primary 'users' collection
        await _firestore.collection('users').doc(user.uid).set({
          'id': user.uid,
          'email': user.email ?? '',
          'role': 'mc_seeker',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Save session in local cache for role tracking
        final idToken = await user.getIdToken();
        await SessionService.saveSession(
          role: "mc_seeker",
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

        final doc = await _firestore.collection('mc_seekers').doc(user.uid).get();
        if (doc.exists) {
          _currentSeeker = McSeekerModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        } else {
          final newSeeker = McSeekerModel(
            id: user.uid,
            userName: googleUser.displayName ?? 'New Seeker',
            email: googleUser.email,
            phone: '',
            address: '',
            profilePicture: googleUser.photoUrl ?? '',
          );
          await _firestore.collection('mc_seekers').doc(newSeeker.id).set(newSeeker.toJson());
          _currentSeeker = newSeeker;
        }

        // Sync with primary 'users' collection
        await _firestore.collection('users').doc(user.uid).set({
          'id': user.uid,
          'email': user.email ?? '',
          'role': 'mc_seeker',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Save session in local cache for role tracking
        final idToken = await user.getIdToken();
        await SessionService.saveSession(
          role: "mc_seeker",
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

  Future<void> fetchSeekerProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('mc_seekers').doc(uid).get();
      if (doc.exists) {
        _currentSeeker = McSeekerModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching seeker profile: $e");
    }
  }

  Future<String?> registerWithEmail(String email, String password, String userName, String phone, String address) async {
    _isLoading = true;
    notifyListeners();
    try {
      UserCredential userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      } on FirebaseAuthException catch (authEx) {
        if (authEx.code == 'email-already-in-use') {
          debugPrint('[McSeekerAuthController] Email already in use. Checking credentials and MC seeker profile...');
          userCredential = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
          
          final doc = await _firestore.collection('mc_seekers').doc(userCredential.user!.uid).get();
          if (doc.exists) {
            throw FirebaseAuthException(
              code: 'email-already-in-use',
              message: 'A seeker account already exists with this email. Please sign in instead.',
            );
          }
          
          debugPrint('[McSeekerAuthController] Existing user authenticated. Creating seeker profile...');
        } else {
          rethrow;
        }
      }
      
      McSeekerModel newSeeker = McSeekerModel(
        id: userCredential.user!.uid,
        userName: userName,
        email: email,
        phone: phone,
        address: address,
      );

      await _firestore.collection('mc_seekers').doc(newSeeker.id).set(newSeeker.toJson());
      _currentSeeker = newSeeker;
      
      // Sync with primary 'users' collection
      await _firestore.collection('users').doc(newSeeker.id).set({
        'id': newSeeker.id,
        'email': email,
        'role': 'mc_seeker',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Send email verification link
      try {
        await userCredential.user?.sendEmailVerification();
      } catch (e) {
        debugPrint('[McSeekerAuthController] Error sending email verification: $e');
      }

      // Save target role & session in local cache for role tracking
      await SessionService.saveTargetRole("mc_seeker");
      final idToken = await userCredential.user?.getIdToken();
      await SessionService.saveSession(
        role: "mc_seeker",
        userId: newSeeker.id,
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
      
      var doc = await _firestore.collection('mc_seekers').doc(userCredential.user!.uid).get();
      if (!doc.exists) {
        if (userCredential.user!.email == 'googletest@leoengineer.com') {
          final newSeeker = McSeekerModel(
            id: userCredential.user!.uid,
            userName: 'Google Test Seeker',
            email: userCredential.user!.email ?? '',
            phone: '9999999999',
            address: 'Test Location',
            profilePicture: '',
          );
          await _firestore.collection('mc_seekers').doc(newSeeker.id).set(newSeeker.toJson());
          doc = await _firestore.collection('mc_seekers').doc(userCredential.user!.uid).get();
        } else {
          await _auth.signOut();
          _isLoading = false;
          notifyListeners();
          return 'This account is not registered as a service seeker. Please register as a seeker first.';
        }
      }
      
      _currentSeeker = McSeekerModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      
      // Sync with primary 'users' collection
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'role': 'mc_seeker',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Save session in local cache for role tracking
      final idToken = await userCredential.user?.getIdToken();
      await SessionService.saveSession(
        role: "mc_seeker",
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
    _currentSeeker = null;
    notifyListeners();
  }

  Future<void> updateSeekerProfile({
    required String userName,
    required String phone,
    required String address,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _firestore.collection('mc_seekers').doc(user.uid).update({
        'userName': userName,
        'phone': phone,
        'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update local state
      if (_currentSeeker != null) {
        _currentSeeker = McSeekerModel(
          id: _currentSeeker!.id,
          userName: userName,
          email: _currentSeeker!.email,
          phone: phone,
          address: address,
          profilePicture: _currentSeeker!.profilePicture,
        );
      }
    } catch (e) {
      debugPrint("Error updating seeker profile: $e");
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
      final seekerId = user.uid;

      // 2. Delete from Firebase Storage (Profile Picture)
      try {
        await FirebaseStorage.instance
            .ref()
            .child('maintenance_contracts/profiles/$seekerId')
            .delete();
      } catch (e) {
        // Ignore if file doesn't exist or deletion fails
        debugPrint("Error deleting seeker profile picture from storage: $e");
      }

      // 3. Delete related data in Firestore
      // 3a. Delete requests booked by this seeker
      final requestsSnapshot = await _firestore
          .collection('mc_requests')
          .where('seekerId', isEqualTo: seekerId)
          .get();
      for (var doc in requestsSnapshot.docs) {
        await doc.reference.delete();
      }

      // 3b. Delete reviews written by this seeker
      final reviewsSnapshot = await _firestore
          .collection('mc_reviews')
          .where('seekerId', isEqualTo: seekerId)
          .get();
      for (var doc in reviewsSnapshot.docs) {
        await doc.reference.delete();
      }

      // 3c. Delete the seeker's profile document
      await _firestore.collection('mc_seekers').doc(seekerId).delete();

      // 4. Delete user from Firebase Auth
      await user.delete();

      _currentSeeker = null;
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
