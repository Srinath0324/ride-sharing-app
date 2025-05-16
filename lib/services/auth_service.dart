import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Check if email exists in Firebase
  Future<bool> emailExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String phoneNumber,
    String? aadhaarNumber,
    String? gender,
  ) async {
    try {
      // Check if email already exists
      final emailExists = await this.emailExists(email);
      if (emailExists) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The email address is already in use by another account.',
        );
      }

      // Create user in Firebase Auth
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Create user in Firestore
      if (userCredential.user != null) {
        final now = DateTime.now();

        final UserModel user = UserModel(
          id: userCredential.user!.uid,
          name: name,
          email: email,
          phoneNumber: phoneNumber,
          aadhaarNumber: aadhaarNumber,
          gender: gender,
          isVerified: false,
          createdAt: now,
          updatedAt: now,
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .set(user.toJson());

        // Save user ID to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userIdKey, userCredential.user!.uid);
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Directly try to sign in instead of checking email existence first
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      // Save user ID to shared preferences
      if (userCredential.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.userIdKey, userCredential.user!.uid);
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Start the Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in flow
        return null;
      }

      // Get the authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Check if this is a new user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser && userCredential.user != null) {
        // Create a new user profile in Firestore
        final now = DateTime.now();
        final user = UserModel(
          id: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'User',
          email: userCredential.user!.email ?? '',
          phoneNumber: userCredential.user!.phoneNumber ?? '',
          profileImageUrl: userCredential.user!.photoURL,
          isVerified: userCredential.user!.emailVerified,
          createdAt: now,
          updatedAt: now,
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .set(user.toJson());
      }

      // Save user ID to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userIdKey, userCredential.user!.uid);

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // Sign out from Google
      await _auth.signOut(); // Sign out from Firebase

      // Clear user ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userIdKey);
    } catch (e) {
      rethrow;
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile() async {
    try {
      if (currentUser == null) return null;

      final DocumentSnapshot userDoc =
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(currentUser!.uid)
              .get();

      if (userDoc.exists) {
        return UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .update(user.toJson());
    } catch (e) {
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }
}
