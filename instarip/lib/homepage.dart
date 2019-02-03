import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:instarip/gallery.dart';
import 'package:instarip/authentication.dart';

class GridList extends StatefulWidget {
  final String uid;

  const GridList({Key key, @required this.uid}) : super(key: key);

  // static const String routeName = '/material/grid-list';
  @override
  GridListState createState() => GridListState();
}

class GridListState extends State<GridList> {
  var _folders = [];

  @override
  void initState() {
    super.initState();
    getFolders();
  }

  // gets all the folder data asynchronously
  Future<List> getFolders() async {
    var folders = [];
    var folderDocs = await Firestore.instance
        .collection('users/${widget.uid}/folders')
        .getDocuments();
    folderDocs.documents.forEach((snapshot) async {
      var photos = await snapshot.reference.collection('photos').getDocuments();

      var preview = photos.documents[0].documentID;
      
      folders.add(Folder(uid: this.widget.uid, name: snapshot.documentID, preview: preview));
    });
    setState(() {
      _folders = folders;
    });
    return folders;
  }

  @override
  Widget build(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Scaffold(
        appBar: AppBar(
          title: const Text('InstaRip'),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.exit_to_app), onPressed: authService.signOut)
          ],
        ),
        body: Column(children: <Widget>[
          Expanded(
              child: SafeArea(
                  top: false,
                  bottom: false,
                  child: FutureBuilder<List>(
                    future: getFolders(),
                    builder: (context, snapshot) {
                      return GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 4.0,
                          crossAxisSpacing: 4.0,
                          padding: const EdgeInsets.all(4.0),
                          children: snapshot.data
                              .map((folder) => GridPhotoItem(folder: folder))
                              .toList());
                    }
                  )))
        ]));
  }
}

class GridPhotoItem extends StatefulWidget {
  final Folder folder;

  GridPhotoItem({Key key, @required this.folder}) : super(key: key);

  @override
  GridPhotoItemState createState() {
    return new GridPhotoItemState();
  }
}

class GridPhotoItemState extends State<GridPhotoItem> {
  String imageUrl;

  @override
  initState() {
    super.initState();
    fetchImageUrl();
  }

  void fetchImageUrl() async {
    var url = await FirebaseStorage.instance
        .ref()
        .child(this.widget.folder.uid)
        .child(this.widget.folder.preview)
        .getDownloadURL();
    print(url);
    setState(() {
      this.imageUrl = url.toString();
    });
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final Widget image = GestureDetector(
        onTap: () {
          // showPhoto(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GalleryPage(title: 'InstaRip', folder: this.widget.folder)));
        },
        child: Hero(
            key: Key(widget.folder.preview),
            tag: widget.folder.preview,
            child: Image.network(
              this.imageUrl,
              fit: BoxFit.cover,
            )));

    return GridTile(
      footer: GestureDetector(
        onTap: () {
          // onBannerTap(photo);
        },
        child: GridTileBar(
          backgroundColor: Colors.black45,
          title: _GridTitleText(this.widget.folder.name),
        ),
      ),
      child: image,
    );
  }
}

class _GridTitleText extends StatelessWidget {
  const _GridTitleText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text),
    );
  }
}

class Folder {
  Folder({this.uid, this.preview, this.name});
  final String uid;
  final String preview;
  final String name;
}
