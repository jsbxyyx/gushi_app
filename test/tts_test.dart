import 'dart:io';

import 'package:gushi_app/tts.dart';
import 'package:path/path.dart' as p;

void main() async {
  var data = await TTSClient.tts("hello 我是晓晓");
  var file = p.join("./", "${DateTime.now().millisecondsSinceEpoch}.mp3");
  var sink = File(file).openWrite();
  sink.add(data);
  await sink.close();
}