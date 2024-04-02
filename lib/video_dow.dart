import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:io';

var yt = YoutubeExplode();
double statistics = 0.0;
String filename1 = '';

void logCallback(int level, double message) {
  statistics = message;
}

extractAudio(url) async {
  url.trim();

  // Save the video to the download directory.

  String dir = "/storage/emulated/0/Download/YOutubeDow";

  print(
      " <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> <.> $dir");

  Directory(dir).createSync();

  // Get video metadata.

  var video = await yt.videos.get(url);

  // Get the video manifest.

  var manifest = await yt.videos.streamsClient.getManifest(url);
  var streams = manifest.audioOnly;

  // Get the audio track with the highest bitrate.

  var audio = streams.withHighestBitrate();
  var audioStream = yt.videos.streamsClient.get(audio);

  // Compose the file name removing the unAllowed characters in windows.

  var fileName = '${video.title}.${audio.container.name.toString()}'
      .replaceAll(r'\', '')
      .replaceAll('/', '')
      .replaceAll('*', '')
      .replaceAll('?', '')
      .replaceAll('"', '')
      .replaceAll('<', '')
      .replaceAll('>', '')
      .replaceAll('|', '');
  var file = File('/storage/emulated/0/Download/$fileName');

  // Delete the file if exists.

  if (file.existsSync()) {
    file.deleteSync();
  }

  // Open the file in writeAppend.

  var output = file.openWrite(mode: FileMode.writeOnlyAppend);

  // Track the file download status.

  double len = audio.size.totalBytes.toDouble();
  double count = 0;

  filename1 = 'Downloading ${video.title}.${audio.container.name}';

  // Listen for data received.

  await for (var data in audioStream) {
    // Keep track of the current downloaded data.

    count += data.length.toDouble();

    // Calculate the current progress.

    double progress = ((count / len) / 1);

    // Update the progressBar.

    logCallback(100, progress);

    // Write to file.

    output.add(data);
  }
}
