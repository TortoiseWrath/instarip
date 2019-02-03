// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:photo_view/photo_view.dart';
// import 'package:instarip/homepage.dart';
// import 'package:instarip/authentication.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class GalleryPage extends StatefulWidget {
//   final String title;
//   final Folder folder;
  
//   GalleryPage({Key key, this.title, this.folder}) : super(key: key);

//   @override
//   _GalleryPageState createState() => _GalleryPageState();
// }

// class _GalleryPageState extends State<GalleryPage> {
  
//   var _photos = [];

//   // gets file names for all photos under the folder
//   getPhotos() async {
//     var photos = [];
//     var photoDocs = await Firestore.instance
//         .collection('users/${widget.folder.uid}/folders/${widget.folder.name}/photos')
//         .getDocuments();
//     photoDocs.documents.forEach((snapshot) async {
//       var url = await FirebaseStorage.instance
//         .ref()
//         .child(widget.folder.uid)
//         .child(snapshot.documentID)
//         .getDownloadURL();
//       photos.add(url.toString());
//       setState(() {
//         _photos = photos;
//       });
//     });
//   }

//   @override
//   void initState() {
//     super.initState();
//     getPhotos();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: ImageGrid(_photos),
//     );
//   }
// }

// List<Widget> _tiles = const <Widget>[
//   const _ImageTile('https://picsum.photos/200/300/?random'),
//   const _ImageTile('https://picsum.photos/201/300/?random'),
//   const _ImageTile('https://picsum.photos/202/300/?random'),
//   const _ImageTile('https://picsum.photos/203/300/?random'),
//   const _ImageTile('https://picsum.photos/204/300/?random'),
//   const _ImageTile('https://picsum.photos/205/300/?random'),
//   const _ImageTile('https://picsum.photos/206/300/?random'),
//   const _ImageTile('https://picsum.photos/207/300/?random'),
//   const _ImageTile('https://picsum.photos/208/300/?random'),
//   const _ImageTile('https://picsum.photos/209/300/?random'),
// ];

// class ImageGrid extends StatelessWidget {
//   final photos;

//   const ImageGrid(this.photos);

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//         padding: const EdgeInsets.only(top: 12.0),
//         child: GridView.count(crossAxisCount: 2, children: _tiles//photos.map((photo) => _ImageTile(photo))
//         )
//       );
//   }
// }

// class _ImageTile extends StatelessWidget {
//   const _ImageTile(this.gridImage);

//   final gridImage;

//   void showPhoto(BuildContext context) {
//     Navigator.push(context,
//         MaterialPageRoute<void>(builder: (BuildContext context) {
//       return Container(
//           child: PhotoView(
//         imageProvider: NetworkImage(this.gridImage),
//       ));
//     }));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return new Card(
//       color: const Color(0x00000000),
//       elevation: 3.0,
//       child: new GestureDetector(
//         onTap: () {
//           showPhoto(context);
//         },
//         child: Hero(
//           key: Key(gridImage),
//           tag: gridImage,
//           child: new Container(
//               decoration: new BoxDecoration(
//             image: new DecorationImage(
//               image: new NetworkImage(gridImage),
//               fit: BoxFit.cover,
//             ),
//             borderRadius: new BorderRadius.all(const Radius.circular(10.0)),
//           )),
//         ),
//       ),
//     );
//   }
// }
