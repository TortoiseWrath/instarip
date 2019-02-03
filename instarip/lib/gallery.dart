import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:instarip/imageservice.dart';
import 'package:share/share.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GalleryPage extends StatefulWidget {
  final String title;
  final Folder folder;

  GalleryPage({Key key, this.title, this.folder}) : super(key: key);

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  var _photos;

  @override
  void initState() {
    super.initState();
    _photos = imageService.getPhotoUrls(widget.folder);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder(
          future: _photos,
          builder: (context, snapshot) {
            return snapshot.hasData
                ? ImageGrid(snapshot.data)
                : Center(child: CircularProgressIndicator());
          }),
    );
  }
}

class ImageGrid extends StatelessWidget {
  final List<String> photos;

  const ImageGrid(this.photos);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 4.0,
            crossAxisSpacing: 4.0,
            children: List.from(photos.map((photo) => _ImageTile(photo)))));
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile(this.imagePath);

  final String imagePath;

  void showPhoto(BuildContext context) {
    var networkImage = CachedNetworkImage(
      imageUrl: imagePath,
      placeholder: Center(child: CircularProgressIndicator()),
      errorWidget: Icon(Icons.error),
    );
    Navigator.push(context,
        MaterialPageRoute<void>(builder: (BuildContext context) {
      return Scaffold(
        appBar: AppBar(actions: <Widget>[
          IconButton(
              icon: Icon(Icons.share),
              onPressed: () async {
                // final cache = await CacheManager.getInstance();
                // final file = await cache.getFile(imagePath);
                await Share.share(imagePath);
              })
        ]),
        body: Container(child: networkImage),
      );
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
          key: Key(imagePath),
          tag: imagePath,
          child: Container(
              child: CachedNetworkImage(
                imageUrl: imagePath,
                placeholder: Center(child: CircularProgressIndicator()),
                errorWidget: Icon(Icons.error),
                fit: BoxFit.cover),
          )),
        ),
    );
  }
}
