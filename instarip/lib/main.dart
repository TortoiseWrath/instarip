import 'package:flutter/material.dart';
import 'package:instarip/login_screen.dart';
import 'package:instarip/authentication.dart';
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
        home: StreamBuilder(
            stream: authService.user,
            builder: (context, snapshot) =>
                (snapshot.hasData) ? GridList() : LoginSignUpPage()));
  }
}
