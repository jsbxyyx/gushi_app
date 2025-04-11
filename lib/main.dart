import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ba.dart';

final __a = String.fromCharCodes(Ba.abtoa("d3gu:j!w:\$!w:\$!x.nh5eg=="));
final base = "https://$__a";

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

  _DetailPageState(this.arg);

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

Future<Map<String, dynamic>> search(String keyword) async {
  var response = await http.get(
    Uri.parse("$base/gushi?q=${Uri.encodeComponent(keyword)}"),
  );
  var result = jsonDecode(utf8.decode(response.bodyBytes));
  return result;
}
