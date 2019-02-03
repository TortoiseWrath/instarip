import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class GalleryPage extends StatefulWidget {
  GalleryPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ImageGrid(),
    );
  }
}

List<Widget> _tiles = const <Widget>[
  const _ImageTile('https://picsum.photos/200/300/?random'),
  const _ImageTile('https://picsum.photos/201/300/?random'),
  const _ImageTile('https://picsum.photos/202/300/?random'),
  const _ImageTile('https://picsum.photos/203/300/?random'),
  const _ImageTile('https://picsum.photos/204/300/?random'),
  const _ImageTile('https://picsum.photos/205/300/?random'),
  const _ImageTile('https://picsum.photos/206/300/?random'),
  const _ImageTile('https://picsum.photos/207/300/?random'),
  const _ImageTile('https://picsum.photos/208/300/?random'),
  const _ImageTile('https://picsum.photos/209/300/?random'),
];

class ImageGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: GridView.count(crossAxisCount: 2, children: _tiles));
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile(this.gridImage);

  final gridImage;

  void showPhoto(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute<void>(builder: (BuildContext context) {
      return Container(
          child: PhotoView(
        imageProvider: NetworkImage(this.gridImage),
      ));
    }));
  }

  @override
  Widget build(BuildContext context) {
    return new Card(
      color: const Color(0x00000000),
      elevation: 3.0,
      child: new GestureDetector(
        onTap: () {
          showPhoto(context);
        },
        child: Hero(
          key: Key(gridImage),
          tag: gridImage,
          child: new Container(
              decoration: new BoxDecoration(
            image: new DecorationImage(
              image: new NetworkImage(gridImage),
              fit: BoxFit.cover,
            ),
            borderRadius: new BorderRadius.all(const Radius.circular(10.0)),
          )),
        ),
      ),
    );
  }
}