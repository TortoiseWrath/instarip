import 'package:flutter/material.dart';
import 'package:instarip/gallery.dart';

class GridList extends StatefulWidget {
  const GridList({Key key}) : super(key: key);

  // static const String routeName = '/material/grid-list';
  @override
  GridListState createState() => GridListState();
}

class GridListState extends State<GridList> {
  List<Folder> photos = <Folder>[
    Folder(
      preview: 'assets/stefan-stefancik-105587-unsplash.jpg',
      name: 'Test1',
    ),
    Folder(
      preview: 'assets/simon-fitall-530083-unsplash.jpg',
      name: 'Test2',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Scaffold(
      appBar: AppBar(
        title: const Text('InstaRip'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SafeArea(
              top: false,
              bottom: false,
              child: GridView.count(
                crossAxisCount: (orientation == Orientation.portrait) ? 2 : 3,
                mainAxisSpacing: 4.0,
                crossAxisSpacing: 4.0,
                padding: const EdgeInsets.all(4.0),
                childAspectRatio:
                    (orientation == Orientation.portrait) ? 1.0 : 1.3,
                children: photos.map<Widget>((Folder photo) {
                  return GridPhotoItem(
                    folder: photo,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridPhotoItem extends StatelessWidget {
  GridPhotoItem({Key key, @required this.folder})
      : assert(folder != null),
        super(key: key);

  final Folder folder;

  @override
  Widget build(BuildContext context) {
    final Widget image = GestureDetector(
        onTap: () {
          // showPhoto(context);
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => GalleryPage(title: 'InstaRip')));
        },
        child: Hero(
            key: Key(folder.preview),
            tag: folder.preview,
            child: Image.asset(
              folder.preview,
              fit: BoxFit.cover,
            )));

    return GridTile(
      footer: GestureDetector(
        onTap: () {
          // onBannerTap(photo);
        },
        child: GridTileBar(
          backgroundColor: Colors.black45,
          title: _GridTitleText(folder.name),
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
  Folder({this.preview, this.name});

  final String preview;
  final String name;
}
