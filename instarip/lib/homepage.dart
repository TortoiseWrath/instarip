import 'package:flutter/material.dart';
import 'package:instarip/gallery.dart';
import 'package:instarip/authentication.dart';
import 'package:instarip/imageservice.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GridList extends StatefulWidget {
  final String uid;

  const GridList({Key key, @required this.uid}) : super(key: key);

  // static const String routeName = '/material/grid-list';
  @override
  GridListState createState() => GridListState();
}

class GridListState extends State<GridList> {
  var _folders;
  var _loading = false;

  // requestStoragePermission() async {
  //   final res = await SimplePermissions.requestPermission(Permission.WriteExternalStorage);
  //   print("permission request result is " + res.toString());
  // }

  @override
  void initState() {
    super.initState();
    imageService.loading.listen((state) => setState(() => _loading = state));
    _folders = imageService.getFolders();
    // requestStoragePermission();
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
                  child: FutureBuilder(
                      future: _folders,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          // print(snapshot.data);
                          List<GridPhotoItem> grid = List.from(snapshot.data
                              .map((folder) => GridPhotoItem(folder: folder)));
                          return GridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 4.0,
                              crossAxisSpacing: 4.0,
                              padding: const EdgeInsets.all(12.0),
                              children: grid);
                        } else {
                          return Center(child: CircularProgressIndicator());
                        }
                      })))
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
  Future<String> imageUrl;

  @override
  initState() {
    super.initState();
    imageUrl = imageService.getPhotoUrl(
        widget.folder.uid, widget.folder.name, widget.folder.photos.last);
  }

  @override
  Widget build(BuildContext context) {
    final Widget image = GestureDetector(
        onTap: () {
          // showPhoto(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GalleryPage(
                      title: 'InstaRip', folder: this.widget.folder)));
        },
        child: FutureBuilder(
          future: imageUrl,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return CachedNetworkImage(
                imageUrl: snapshot.data,
                placeholder: Center(child: CircularProgressIndicator()),
                errorWidget: Icon(Icons.error),
                fit: BoxFit.cover
              );
            }
          },
        ));

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
