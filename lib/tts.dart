import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_client/web_socket_client.dart';

class TTSClient {
  static String _base_url =
      "speech.platform.bing.com/consumer/speech/synthesize/readaloud";
  static String _trusted_client_token = "6A5AA1D4EAFF4E9FB37E23D68491D6F4";

  static String _wss_url =
      "wss://${_base_url}/edge/v1?TrustedClientToken=${_trusted_client_token}";
  static String _voice_list_url =
      "https://${_base_url}/voices/list?trustedclienttoken=${_trusted_client_token}";

  static String default_voice = "zh-CN-XiaoxiaoNeural";

  static String _chromium_full_version = "130.0.2849.68";
  static String _chromium_major_version = _chromium_full_version.split(".")[0];
  static String _sec_ms_gec_version = "1-${_chromium_full_version}";

  static Map<String, String> _base_headers = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/$_chromium_major_version.0.0.0 Safari/537.36 Edg/$_chromium_major_version.0.0.0",
    "Accept-Encoding": "gzip, deflate, br",
    "Accept-Language": "en-US,en;q=0.9",
  };

  static Map<String, String> _wss_headers = {
    "Pragma": "no-cache",
    "Cache-Control": "no-cache",
    "Origin": "chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold",
    //
    ..._base_headers,
  };

  static Map<String, String> _voice_headers = {
    "Authority": "speech.platform.bing.com",
    "Sec-CH-UA":
        "\" Not;A Brand\";v=\"99\", \"Microsoft Edge\";v=\"$_chromium_major_version\", \"Chromium\";v=\"$_chromium_major_version\"",
    "Sec-CH-UA-Mobile": "?0",
    "Accept": "*/*",
    "Sec-Fetch-Site": "none",
    "Sec-Fetch-Mode": "cors",
    "Sec-Fetch-Dest": "empty",
    //
    ..._base_headers,
  };

  static String _sec_ms_gec() {
    int ticks =
        (((DateTime.now().millisecondsSinceEpoch / 1000.0) + 11644473600) *
                10000000)
            .round();
    int roundedTicks = ticks - (ticks % 3000000000);
    String str = roundedTicks.toString() + _trusted_client_token;
    return _sha256x(utf8.encode(str)).toUpperCase();
  }

  static String _connect_url() {
    return "$_wss_url&Sec-MS-GEC=${_sec_ms_gec()}&Sec-MS-GEC-Version=$_sec_ms_gec_version&ConnectionId=${_uuid()}";
  }

  static String _mkssml(
    String text, {
    String lang = "en-US",
    String voiceName = "zh-CN-XiaoxiaoNeural",
    String pitch = "0Hz",
    String rate = "0%",
    String volume = "0%",
  }) {
    return "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='$lang'>"
        "<voice name='$voiceName'>"
        "<prosody pitch='$pitch' rate='$rate' volume='$volume'>"
        "$text"
        "</prosody>"
        "</voice>"
        "</speak>";
  }

  static String _date() {
    var format = DateFormat("E MMM dd yyyy HH:mm:ss");
    return "${format.format(DateTime.now())} GMT+0000 (Coordinated Universal Time)";
  }

  static String _uuid() {
    return Uuid().v1();
  }

  static int _indexOf(List<int> array, List<int> target) {
    if (target.isEmpty) {
      return 0;
    }
    outer:
    for (int i = 0; i < array.length - target.length + 1; i++) {
      for (int j = 0; j < target.length; j++) {
        if (array[i + j] != target[j]) {
          continue outer;
        }
      }
      return i;
    }
    return -1;
  }

  static String _sha256x(List<int> data) {
    return sha256.convert(data).toString();
  }

  static Future<List<int>> tts(
    String text, {
    String voiceName = "zh-CN-XiaoxiaoNeural",
    String pitch = "0Hz",
    String rate = "0%",
    String volume = "0%",
  }) async {
    var url = _connect_url();
    var socket = WebSocket(Uri.parse(url), headers: _wss_headers);
    print("ws url : $url");
    print("ws headers : $_wss_headers");

    Completer<List<int>> completer = Completer();
    List<int> result = [];

    socket.connection.listen((state) {
      if (state is Connected) {
        print('connected');

        var commandData =
            "X-Timestamp:${_date()}\r\n"
            "Content-Type:application/json; charset=utf-8\r\n"
            "Path:speech.config\r\n\r\n"
            "{\"context\":{\"synthesis\":{\"audio\":{\"metadataoptions\":{\"sentenceBoundaryEnabled\":\"false\",\"wordBoundaryEnabled\":\"true\"},\"outputFormat\":\"audio-24khz-48kbitrate-mono-mp3\"}}}}";
        socket.send(commandData);

        var ssml_data =
            "X-RequestId:${_uuid()}\r\n"
            "Content-Type:application/ssml+xml\r\n"
            "X-Timestamp:${_date()}Z\r\n"
            "Path:ssml\r\n\r\n"
            "${_mkssml(text, voiceName: voiceName,pitch: pitch, rate: rate, volume: volume)}";
        socket.send(ssml_data);
      } else if (state is Disconnected) {
        print("state.code : ${state.code}");
      }
    });

    final sep = utf8.encode("Path:audio\r\n");

    socket.messages.listen((data) {
      if (data is Uint8List) {
        Uint8List view = data;
        int index = _indexOf(data, sep);
        var audioData = view.sublist(index + sep.length);
        result.addAll(audioData);
      } else if (data is String) {
        if (data.contains("turn.end")) {
          completer.complete(result);
          socket.close(1000);
        }
      }
    }, onError: (error) => print(error));

    return completer.future;
  }

  static Future<List<dynamic>> voiceList() async {
    var response = await http.get(
      Uri.parse(_voice_list_url),
      headers: _voice_headers,
    );
    var result = jsonDecode(utf8.decode(response.bodyBytes));
    return result;
  }
}
