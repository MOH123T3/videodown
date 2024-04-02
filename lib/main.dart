// ignore_for_file: avoid_print, prefer_const_constructors, use_build_context_synchronously, prefer_const_constructors_in_immutables, library_private_types_in_public_api

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtubereeldownloder/insta_dow.dart';
import 'package:youtubereeldownloder/video_dow.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  initTimeInform();
  runApp(MyApp());
}

//Todo for firebase notification
initTimeInform() async {
  var fireBaseMessage = FirebaseMessaging.instance;
  await fireBaseMessage.requestPermission();
  final token = await fireBaseMessage.getToken();
  print("token- { $token }");
  FirebaseMessaging.onBackgroundMessage(handleMessage);
}

Future handleMessage(RemoteMessage message) async {
  print("message - $message");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
          ),
          canvasColor: Colors.black,
          primarySwatch: Colors.deepPurple,
          visualDensity: VisualDensity.adaptivePlatformDensity),
      home: MyHomePage(title: 'Video Downloader'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final textController = TextEditingController();

  String progress = "";

  bool downloading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return InstagramReel();
                  },
                ));
              },
              child: const Text("Reel Downloader"),
            ),
            SizedBox(
              height: 30,
            ),
            const Text(
              'Insert the video id or url',
            ),
            SizedBox(
              height: 30,
            ),
            SizedBox(
              width: 500,
              child: TextFormField(
                controller: textController,
                decoration: InputDecoration(
                    filled: true,
                    suffixIcon: ElevatedButton(
                        onPressed: _past, child: Text('Past url')),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(3))),
              ),
            ),
            SizedBox(
              height: 30,
            ),
            Row(
              mainAxisAlignment: downloading
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceAround,
              children: [
                downloading
                    ? Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(9)),
                        height: 40,
                        width: 140,
                        child: Text(
                          "Downloading : $progress",
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          if (textController.text.isNotEmpty) {
                            extractVideo(textController.text);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content:
                                    Text("Please past or enter video link")));
                          }
                        },
                        child: Text('Download Video')),
                downloading
                    ? SizedBox()
                    : ElevatedButton(
                        onPressed: () {
                          setState(() {
                            textController.clear();
                          });
                        },
                        child: Text('Reset')),
              ],
            )
          ],
        ),
      ),
    );
  }

  _past() async {
    final data = await Clipboard.getData('text/plain');

    if (data != null) {
      setState(() {
        textController.text = data.text ?? "";
      });
      print('data - ${data.text}');
    }

    if (textController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Empty text")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Past to clipboard")));
    }
  }

  extractVideo(String url) async {
    String dir = "/storage/emulated/0/Download/YouTubReelDownload";

    try {
      if (Platform.isAndroid) {
        final plugin = DeviceInfoPlugin();
        final android = await plugin.androidInfo;

        final storageStatus = android.version.sdkInt < 33
            ? await Permission.storage.request()
            : PermissionStatus.granted;

        url.trim();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Please wait a second ")));

        if (storageStatus == PermissionStatus.granted) {
          Directory(dir).createSync();
          var video = await yt.videos.get(url);
          var manifest = await yt.videos.streamsClient.getManifest(url);
          var streams = manifest.muxed;
          var videoS = streams.withHighestBitrate();
          var videoStream = yt.videos.streamsClient.get(videoS);
          var fileName = '${video.title}.${videoS.container.name.toString()}'
              .replaceAll(r'\', '')
              .replaceAll('/', '')
              .replaceAll('*', '')
              .replaceAll('?', '')
              .replaceAll('"', '')
              .replaceAll('<', '')
              .replaceAll('>', '')
              .replaceAll('|', '');
          var file =
              File('/storage/emulated/0/Download/YouTubReelDownload/$fileName');

          if (file.existsSync()) {
            file.deleteSync();
          }

          var output = file.openWrite(mode: FileMode.writeOnlyAppend);
          double len = videoS.size.totalBytes.toDouble();
          double count = 0;

          await for (var data in videoStream) {
            count += data.length.toDouble();

            output.add(data);

            setState(() {
              downloading = true;
              progress = "${((count / len) * 100).toStringAsFixed(0)}%";
            });
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));

      print('catch - ${e.toString()}');
    }

    setState(() {
      downloading = false;
      progress = "Download completed and saved to $dir";

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(progress)));
    });
  }
}
