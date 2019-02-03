import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'authentication.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class Folder {
  Folder({this.uid, this.name, this.photos});
  final String uid;
  final String name;
  final List<String> photos;
}

class ImageService {
  final Firestore _db = Firestore.instance;

  // Observable<Folder> folders; // folders for every user
  PublishSubject loading = PublishSubject(); // loading indicator

  Future<List> getFolders() async {
    loading.add(true);

    List<Folder> folders = [];

    FirebaseUser user = await authService.getCurrentUser();
    var folderDocs =
        await _db.collection('users/${user.uid}/folders').getDocuments();

    for (DocumentSnapshot snapshot in folderDocs.documents) {
      var photos = await snapshot.reference.collection('photos').getDocuments();

      List<String> filenames = [];
      photos.documents.forEach((photo) {
        var filename = photo.documentID;
        filenames.add(filename);
      });

      folders.add(
          Folder(uid: user.uid, name: snapshot.documentID, photos: filenames));
    }

    // print(folders[0].name);
    loading.add(false);
    return folders;
  }
}

final ImageService imageService = ImageService();
