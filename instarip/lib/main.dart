import 'package:flutter/material.dart';
import 'package:instarip/login_screen.dart';
import 'package:instarip/authentication.dart';
import 'package:instarip/homepage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';
import 'dart:io';
import 'package:image/image.dart' as Img;
import 'package:firebase_storage/firebase_storage.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: StreamBuilder(
            stream: authService.user,
            builder: (context, snapshot) => (snapshot.hasData)
                ? MainPage(snapshot.data.uid)
                : LoginSignUpPage()));
  }
}

class MainPage extends StatelessWidget {
  final String uid;
  MainPage(this.uid) {
    listener();
  }
  @override
  Widget build(BuildContext context) {
    return GridList(uid: this.uid);
  }

  void uploadImage(String fileName, File uploadFile) {
    final StorageReference firebaseStorageRef =
        FirebaseStorage.instance.ref().child(this.uid).child("Uncategorized").child(fileName);
    final StorageUploadTask task = firebaseStorageRef.putFile(uploadFile);
  }

  void readImage(String filePath) {
    File imageFile = new File(filePath);
    Img.Image image = Img.decodeImage(imageFile.readAsBytesSync());
    String fileName = p.basename(filePath) +
        "-" +
        image.width.toString() +
        "x" +
        image.height.toString();
    uploadImage(fileName, imageFile);
  }

  void listener() async {
    //"/storage/emulated/0/Pictures/Screenshots"
    Directory externalDir = await getExternalStorageDirectory();
    var watcher = DirectoryWatcher(
        p.absolute(externalDir.path + "/Pictures/Screenshots"));
    watcher.events.listen((event) {
      if (event.type.toString() == "add") {
        readImage(event.path.toString());
      }
    });
  }
}
