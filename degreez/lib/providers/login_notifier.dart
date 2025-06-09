import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A provider class that manages authentication state using Google Sign-In and Firebase Auth.
class LogInNotifier extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Private field to store the current user
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;
  bool _newUser = true;
  bool _stayedSignedIn = false;

  // Getters
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _user != null;
  bool get newUser => _newUser;
  bool get stayedSignedIn => _stayedSignedIn;

  // Constructor: listen to auth state changes
  LogInNotifier() {
    _initUser();
    // Listen for authentication state changes
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      debugPrint(
        "Auth state changed: User is ${user != null ? 'signed in' : 'signed out'}",
      );
      if (user != null) {
        _newUser = false;
      }
      notifyListeners();
    });
  }

  // Initialize user on startup
  void _initUser() {
    _user = _auth.currentUser;
    debugPrint("Init user: ${_user?.displayName ?? 'No user'}");
    if (user != null) {
      _stayedSignedIn = true;
    }
  }

  /// Sign in with Google account
  Future<User?> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      debugPrint("Starting Google Sign-In process");

      // Begin interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Abort if sign in was unsuccessful or user canceled
      if (googleUser == null) {
        debugPrint("Google Sign-In canceled by user");
        _setLoading(false);
        return null;
      }

      debugPrint("Google Sign-In successful: ${googleUser.email}");

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      debugPrint("Got Google authentication tokens");

      // Create new credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Check if user is new

      try {
        final docSnapshot =
            await FirebaseFirestore.instance
                .collection('Students')
                .doc(googleAuth.idToken)
                .get();

        debugPrint('googleAuth.idToken = ${googleAuth.idToken}');
        debugPrint('docSnapshot = $docSnapshot');

        if (docSnapshot.exists) {
          debugPrint('This is a veteran Student');
          _newUser = false;
        } else {
          debugPrint('Student not found');
          _newUser = true;
        }
      } catch (e) {
        debugPrint('Error fetching student data: $e');
        _newUser = true;
      } finally {
        _isLoading = false;
        notifyListeners();
      }

      // Sign in to Firebase with the Google OAuth credential
      debugPrint("Signing in to Firebase with Google credential");
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Update the user
      _user = userCredential.user;
      debugPrint(
        "Firebase sign-in successful: ${_user?.displayName ?? _user?.email ?? 'Unknown user'}",
      );

      _setLoading(false);
      notifyListeners();

      return _user;
    } catch (e) {
      debugPrint("Error in signInWithGoogle: $e");
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  /// Sign out from both Google and Firebase
  Future<void> signOut() async {
    _setLoading(true);

    try {
      debugPrint("Signing out");
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);

      _user = null;
      debugPrint("Sign out complete");

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint("Error signing out: $e");
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> deleteUser() async{
    _setLoading(true);
    notifyListeners();
    // Delete from Authentication
    try {
      await user?.delete();
    } catch (e) {
      debugPrint("Failed to delete User: $e");
      _errorMessage = e.toString();
    }
    _setLoading(false);
    notifyListeners();
    
  }
}
