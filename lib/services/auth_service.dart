import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;

    // Send verification email
    await user.sendEmailVerification();

    // Update display name
    await user.updateDisplayName(name);

    // Create Firestore profile
    final userModel = UserModel(
      userId: user.uid,
      email: email,
      name: name,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(userModel.toMap());

    return userModel;
  }

  // Sign in — blocks access if email is not yet verified
  Future<UserCredential> signIn({
    required String email,
    required String password,
    }) async {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!credential.user!.emailVerified) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Please verify your email before signing in. Check your inbox.',
        );
      }
      return credential;
    }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // Stream user profile
  Stream<UserModel?> userProfileStream(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Update user name
  Future<void> updateName(String name) async {
    final uid = currentUser!.uid;
    await currentUser!.updateDisplayName(name);
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'name': name});
  }

  // Toggle bookmark
  Future<void> toggleBookmark(String listingId) async {
    final uid = currentUser!.uid;
    final userDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    final bookmarks = List<String>.from(userDoc['bookmarks'] ?? []);
    if (bookmarks.contains(listingId)) {
      bookmarks.remove(listingId);
    } else {
      bookmarks.add(listingId);
    }
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'bookmarks': bookmarks});
  }

  // Password reset
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
  Future<void> ensureProfileExists(User user) async {
  try {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();
    if (!doc.exists) {
      final userModel = UserModel(
        userId: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? user.email ?? 'User',
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(userModel.toMap());
    }
  } catch (e) {
    // silently fail — profile will retry on next load
  }
}
}
