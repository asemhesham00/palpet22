import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  final String _defaultUserProfileImage =
      'https://cdn-icons-png.flaticon.com/512/847/847969.png';

  Future<bool> isUsernameUnique(String username) async {
    final result = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .get();
    return result.docs.isEmpty;
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
    required String location,
    File? imageFile,
  }) async {
    try {
      bool unique = await isUsernameUnique(username);
      if (!unique) throw 'Username is already taken. Please choose another.';

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String photoUrl = _defaultUserProfileImage;

      if (imageFile != null) {
        try {
          String fileName = '${userCredential.user!.uid}_profile.jpg';
          Reference ref = _storage.ref().child('profile_images/$fileName');
          UploadTask uploadTask = ref.putFile(imageFile);
          TaskSnapshot snapshot = await uploadTask;
          photoUrl = await snapshot.ref.getDownloadURL();
        } catch (e) {
          print("Error uploading profile image: $e");
        }
      }

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'username': username.toLowerCase(),
        'location': location,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'For security, please log out and log in again to delete your account.';
      }
      throw _handleAuthError(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'No user logged in';
    if (user.email == null) throw 'User email not found';

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw 'Current password is incorrect';
      }
      throw _handleAuthError(e);
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'network-request-failed':
        return 'Check your internet connection.';
      case 'requires-recent-login':
        return 'Please log out and log in again to perform this action.';
      default:
        return 'Error: ${e.message}';
    }
  }
}
