import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';
import 'dart:io';
import 'dart:async';
import 'package:image/image.dart' as Img;
import 'package:background_fetch/background_fetch.dart';

int count = 1;

void writeCounter(int counter) async {
  final file = File("/storage/emulated/0/" + count.toString() + ".txt");
  count++;
  // Write the file
  file.writeAsString('$counter');
}

void backgroundFetchHeadlessTask() async {
  writeCounter(count);
  print('[BackgroundFetch] Headless event received.');
  BackgroundFetch.finish();
}

void main() {
  runApp(new MyApp());
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  bool _enabled = true;
  int _status = 0;
  List<DateTime> _events = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
    listener();
  }

  Future<void> initPlatformState() async {
    // Configure BackgroundFetch.
    BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 15,
            stopOnTerminate: false,
            enableHeadless: true,
            forceReload: true), () async {
      // This is the fetch-event callback.


      print('[BackgroundFetch] Event received');
      setState(() {
        _events.insert(0, new DateTime.now());
      });
      backgroundFetchHeadlessTask();
      // IMPORTANT:  You must signal completion of your fetch task or the OS can punish your app
      // for taking too long in the background.
      BackgroundFetch.finish();
    }).then((int status) {
      print('[BackgroundFetch] SUCCESS: $status');
      setState(() {
        _status = status;
      });
    }).catchError((e) {
      print('[BackgroundFetch] ERROR: $e');
      setState(() {
        _status = e;
      });
    });
    if (!mounted) return;
  }

  void readImage(String filePath) {
    Img.Image image = Img.decodeImage(new File(filePath).readAsBytesSync());
    writeCounter(count);
    print(image);
  }

  void listener() async {
    //"/storage/emulated/0/Pictures/Screenshots"
    Directory externalDir = await getExternalStorageDirectory();
    var watcher = DirectoryWatcher(
        p.absolute(externalDir.path + "/Pictures/Screenshots"));
    watcher.events.listen((event) {
        print(event.type.toString());
        print(event.path.toString());
        if (event.type.toString() == "add") {
          readImage(event.path.toString());
        }
    });
  }

  void _incrementCounter() {
    setState(() {
    
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
      
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
        
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
