import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Firestore _db = Firestore.instance;

  Observable<FirebaseUser> user; // firebase user
  Observable<Map<String, dynamic>> profile; // custom user data in Firestore
  PublishSubject loading = PublishSubject();

  // constructor
  AuthService() {
    user = Observable(_auth.onAuthStateChanged);

    profile = user.switchMap((FirebaseUser u) {
      if (u != null) {
        return _db
            .collection('users')
            .document(u.uid)
            .snapshots()
            .map((snap) => snap.data);
      } else {
        return Observable.just({});
      }
    });
  }

  // called after successful sign-in
  Future<FirebaseUser> signedIn(FirebaseUser user) async {
    updateUserData(user);
    print("signed in " + user.displayName);

    loading.add(false);
    return user;
  }

  Future<FirebaseUser> signInWithEmail(String email, String password) async {
    FirebaseUser user = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return signedIn(user);
  }

  Future<FirebaseUser> signUp(String email, String password) async {
    FirebaseUser user = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    return signedIn(user);
  }

  Future<FirebaseUser> googleSignIn() async {
    loading.add(true);
    GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    FirebaseUser user = await _auth.signInWithCredential(credential);

    return signedIn(user);
  }

  void updateUserData(FirebaseUser user) async {
    DocumentReference ref = _db.collection('users').document(user.uid);

    return ref.setData({
      'uid': user.uid,
      'email': user.email,
      // 'photoURL': user.photoUrl,
      // 'displayName': user.displayName,
      'lastSeen': DateTime.now()
    }, merge: true);
  }

  void signOut() {
    _auth.signOut();
  }
}

// TODO refactor global to InheritedWidget
final AuthService authService = AuthService();

// import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:rxdart/rxdart.dart';

// abstract class BaseAuth {
//   Future<String> signIn(String email, String password);

//   Future<String> signUp(String email, String password);

//   Future<String> googleSignIn(String email);

//   Future<FirebaseUser> getCurrentUser();

//   Future<void> signOut();
// }

// class Auth implements BaseAuth {
//   final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

//   Future<String> signIn(String email, String password) async {
//     FirebaseUser user = await _firebaseAuth.signInWithEmailAndPassword(
//         email: email, password: password);
//     return user.uid;
//   }

//   Future<String> signUp(String email, String password) async {
//     FirebaseUser user = await _firebaseAuth.createUserWithEmailAndPassword(
//         email: email, password: password);
//     return user.uid;
//   }

//   Future<String> googleSignIn(String email) async {
//     return "TODO";
//   }

//   Future<FirebaseUser> getCurrentUser() async {
//     FirebaseUser user = await _firebaseAuth.currentUser();
//     return user;
//   }

//   Future<void> signOut() async {
//     return _firebaseAuth.signOut();
//   }
// }
