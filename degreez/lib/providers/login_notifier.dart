import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// A provider class that manages authentication state using Google Sign-In and Firebase Auth.
class LogInNotifier extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Private field to store the current user
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;
  
  // Getters
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _user != null;
  
  // Constructor: listen to auth state changes
  LogInNotifier() {
    _initUser();
    // Listen for authentication state changes
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      print("Auth state changed: User is ${user != null ? 'signed in' : 'signed out'}");
      notifyListeners();
    });
  }
  
  // Initialize user on startup
  void _initUser() {
    _user = _auth.currentUser;
    print("Init user: ${_user?.displayName ?? 'No user'}");
  }
  
  /// Sign in with Google account
  Future<User?> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      print("Starting Google Sign-In process");
      
      // Begin interactive sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // Abort if sign in was unsuccessful or user canceled
      if (googleUser == null) {
        print("Google Sign-In canceled by user");
        _setLoading(false);
        return null;
      }
      
      print("Google Sign-In successful: ${googleUser.email}");
      
      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      print("Got Google authentication tokens");
      
      // Create new credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the Google OAuth credential
      print("Signing in to Firebase with Google credential");
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      
      // Update the user
      _user = userCredential.user;
      print("Firebase sign-in successful: ${_user?.displayName ?? _user?.email ?? 'Unknown user'}");
      
      _setLoading(false);
      notifyListeners();
      
      return _user;
      
    } catch (e) {
      print("Error in signInWithGoogle: $e");
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
      print("Signing out");
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      
      _user = null;
      print("Sign out complete");
      
      _setLoading(false);
      notifyListeners();
      
    } catch (e) {
      print("Error signing out: $e");
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}