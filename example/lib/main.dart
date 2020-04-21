import 'package:app_updater/app_updater.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    AppUpdater.downloadStream.listen((data) {
      print("下載狀態: ${data.status}, 進度: ${data.progress}");
      if (data.error != null) {
        print("錯誤訊息: ${data.error}");
      }
    });
    AppUpdater.update('http://18.162.107.44/apk/Payload_1.apk', openWeb: false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running'),
        ),
      ),
    );
  }
}
