import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import './tts.dart';

import './ba.dart';

final __a = String.fromCharCodes(Ba.abtoa("d3gu:j!w:\$!w:\$!x.nh5eg=="));
final base = "https://$__a";

final _tone_json = "tone.json";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '古诗',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: '古诗'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with AutomaticKeepAliveClientMixin {
  var _keywordController = TextEditingController();

  var _searchList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: TextField(
                  controller: _keywordController,
                  decoration: InputDecoration(hintText: "搜索古诗名称，诗人，诗句"),
                ),
              ),
              SizedBox(width: 15),
              ElevatedButton(
                onPressed: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                  var keyword = _keywordController.text;
                  if (keyword == '') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text("请输入关键词"),
                      ),
                    );
                    return;
                  }
                  search(keyword).then((Map<String, dynamic> r) {
                    setState(() {
                      if (int.parse(r['code']) != 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(r['message'].toString()),
                          ),
                        );
                        return;
                      }
                      _searchList.clear();
                      _searchList = r['data'];
                    });
                  });
                },
                child: Text("搜索"),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _searchList.length,
              itemBuilder: (BuildContext context, int index) {
                var item = _searchList[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (BuildContext context) => DetailPage(arg: item),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.all(10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          minRadius: 40,
                          child: Text(
                            item['title'][0],
                            style: TextStyle(fontSize: 32),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.only(left: 5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item["title"]!,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "[${item['dynasty']}]",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      "${item['author']}",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: CircleAvatar(child: Icon(Icons.settings)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => SettingsPage(),
            ),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> arg;

  const DetailPage({super.key, required this.arg});

  @override
  State<StatefulWidget> createState() => _DetailPageState(arg);
}

class _DetailPageState extends State<DetailPage> {
  final Map<String, dynamic> arg;

  late final AudioPlayer _player;
  bool _isInitialized = false;

  bool _playing = false;

  _DetailPageState(this.arg);

  Future<void> _init() async {
    if (!_isInitialized) {
      _player = AudioPlayer();
      _isInitialized = true;
      _player.onPlayerStateChanged.listen((state) {
        setState(() {
          _playing = (state == PlayerState.playing);
        });
      });
    }
  }

  Future<void> tts(String text) async {
    await _init();
    await _player.stop();

    var filename = await generateFilename(
      "${arg['title']}-${arg['dynasty']}-${arg["author"]}.mp3",
    );
    print("filename: $filename");
    var file = File(filename);
    if (await file.exists()) {
      await _player.play(DeviceFileSource(filename));
      return;
    } else {
      var toneConfig = await readFileJson(await generateFilename(_tone_json));
      var voiceName = toneConfig["voiceName"]?? "zh-CN-XiaoxiaoNeural";
      var pitch = toneConfig["pitch"]?? "+0";
      var rate = toneConfig["rate"]?? "+0";
      var volume = toneConfig["volume"]?? "+0";
      var audioData = await TTSClient.tts(text, voiceName: voiceName, pitch: "${pitch}Hz", rate: "$rate%", volume: "$volume%");
      await writeFile(filename, audioData);
      await _player.play(DeviceFileSource(filename));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("诗词")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              children: [
                Text(
                  arg['title'],
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (!_playing)
                  GestureDetector(
                    onTap: () async {
                      var text =
                          "${arg['title']}。${arg['dynasty']}。${arg['author']}。${arg['content'].toString().replaceAll("<.*?>", "")}";
                      await tts(text);
                    },
                    child: Icon(Icons.play_circle, size: 35),
                  ),
                if (_playing)
                  GestureDetector(
                    onTap: () async {
                      await _player.stop();
                    },
                    child: Icon(Icons.stop_circle, size: 35),
                  ),
              ],
            ),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "[${arg['dynasty']}]",
                  style: TextStyle(fontSize: 16, color: Colors.green),
                ),
                SizedBox(width: 5),
                Text(
                  arg['author'],
                  style: TextStyle(fontSize: 16, color: Colors.green),
                ),
              ],
            ),
            SizedBox(height: 5),
            Text(
              arg['content']
                  .toString()
                  .trim()
                  .replaceAll("\n\n", "")
                  .replaceAll("，", "\n")
                  .replaceAll("。", "\n"),
              style: TextStyle(fontSize: 18),
            ),
            if (arg['fanyi'] != "")
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "译文",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // GestureDetector(
                      //   onTap: () {},
                      //   child: Icon(Icons.play_circle, size: 35),
                      // ),
                      // GestureDetector(
                      //   onTap: () {},
                      //   child: Icon(Icons.stop_circle, size: 35),
                      // ),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 18, right: 18),
                    child: Text(
                      arg['fanyi'].toString().trim().replaceAll("\n\n", "\n"),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            if (arg["zhushi"] != "")
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "注释",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // GestureDetector(
                      //   onTap: () {},
                      //   child: Icon(Icons.play_circle, size: 35),
                      // ),
                      // GestureDetector(
                      //   onTap: () {},
                      //   child: Icon(Icons.stop_circle, size: 35),
                      // ),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 18, right: 18),
                    child: Text(
                      arg['zhushi'].toString().trim().replaceAll("\n\n", "\n"),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            if (arg["jianxi"] != "")
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "简析",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Icon(Icons.play_circle, size: 35),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Icon(Icons.pause_circle, size: 35),
                      ),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 18, right: 18),
                    child: Text(
                      arg['jianxi'].toString().trim().replaceAll("\n\n", "\n"),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<Map<String, dynamic>> _voiceItems = [];
  var _voiceName = "zh-CN-XiaoxiaoNeural";
  var _pitch = "0";
  var _rate = "0";
  var _volume = "0";
  var _content = "今天天气真好";

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchVoiceList();
    readToneConfig();
  }

  void readToneConfig() {
    generateFilename(_tone_json).then((filename) {
      if (File(filename).existsSync()) {
        readFileJson(filename).then((data) {
          setState(() {
            _voiceName = data["voiceName"];
            _pitch = data["pitch"];
            _rate = data["rate"];
            _volume = data["volume"];
          });
        });
      }
    });
  }

  void fetchVoiceList() {
    TTSClient.voiceList().then((data) {
      setState(() {
        _voiceItems.clear();
        for (var item in data) {
          _voiceItems.add(item);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("音色设置")),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(15),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                DropdownButtonFormField(
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: '选择发音人',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        fetchVoiceList();
                      },
                      icon: Icon(Icons.refresh_outlined),
                    ),
                  ),
                  items:
                      _voiceItems.map((item) {
                        return DropdownMenuItem(
                          value: item["ShortName"],
                          child: Text("${item["ShortName"]} ${item["Gender"]}"),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _voiceName = value.toString();
                    });
                  },
                  value: _voiceName,
                  validator: (v) {
                    if (v == null || v.toString().trim() == "") {
                      return "请选择发音人";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "请输入音调大小(-100 - 100)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^(-?\d+)')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _pitch = v;
                    });
                  },
                  initialValue: _pitch,
                  validator: (v) {
                    if (v == null || v.toString().trim() == "") {
                      return "请输入音调";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "请输入速度大小(-100 - 100)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^(-?\d+)')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _rate = v;
                    });
                  },
                  initialValue: _rate,
                  validator: (v) {
                    if (v == null || v.toString().trim() == "") {
                      return "请输入速度";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "请输入音量大小(0 - 100)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^(\d+)')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _volume = v;
                    });
                  },
                  initialValue: _volume,
                  validator: (v) {
                    if (v == null || v.toString().trim() == "") {
                      return "请输入音量";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "请输入文本",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  minLines: 2,
                  maxLines: 2,
                  initialValue: _content,
                  onChanged: (v) {
                    setState(() {
                      _content = v;
                    });
                  },
                  validator: (v) {
                    if (v == null || v.toString().trim() == "") {
                      return "请输入文本";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          var player = AudioPlayer();
                          var audioData = await TTSClient.tts(
                            _content,
                            voiceName: _voiceName,
                            pitch: "${_pitch}Hz",
                            rate: "$_rate%",
                            volume: "$_volume%",
                          );
                          var filename = await generateFilename(
                            "${DateTime.now().millisecondsSinceEpoch.toString()}.mp3",
                          );
                          await writeFile(filename, audioData);
                          await player.play(DeviceFileSource(filename));
                        }
                      },
                      child: Text("试听"),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          var filename = await generateFilename(_tone_json);
                          if (!await File(filename).exists()) {
                            await File(filename).create();
                          }
                          await writeFile(
                            filename,
                            utf8.encode(
                              jsonEncode({
                                "voiceName": _voiceName,
                                "pitch": _pitch,
                                "rate": _rate,
                                "volume": _volume,
                              }),
                            ),
                          );
                          print("save tone.json => $_voiceName : $_pitch : $_rate : $_volume");
                        }
                      },
                      child: Text("使用"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>> search(String keyword) async {
  var response = await http.get(
    Uri.parse("$base/gushi?q=${Uri.encodeComponent(keyword)}"),
  );
  var result = jsonDecode(utf8.decode(response.bodyBytes));
  return result;
}

Future<String> generateFilename(String filename) async {
  final Directory dir = await getApplicationDocumentsDirectory();
  return p.join(dir.path, filename);
}

Future<void> writeFile(String filename, List<int> data) async {
  var sink = File(filename).openWrite();
  sink.add(data);
  await sink.close();
}

Future<Map<String, dynamic>> readFileJson(String filename) async {
  if (!await File(filename).exists()) {
    return {};
  }
  String str = await File(filename).readAsString();
  return jsonDecode(str);
}

