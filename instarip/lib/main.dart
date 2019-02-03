import 'package:flutter/material.dart';
import 'package:instarip/gallery.dart';
import 'package:instarip/homepage.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GridList(),
    );
  }
}
