import 'dart:convert';

import 'package:http/http.dart' as http;

const String ENKRA_API_URL = String.fromEnvironment('ENKRA_API_URL');

Uri convertToWebSocket(Uri uri) {
  String scheme = uri.scheme == "https" ? "wss" : "ws";
  return uri.replace(scheme: scheme, path: "/send-ws");
}

final String apiUrl = '$ENKRA_API_URL/graphql';
final String wsUrl = convertToWebSocket(Uri.parse(ENKRA_API_URL)).toString();

Future<dynamic?> requestChannel() async {
  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'query': '''mutation {
        requestSendChannel {
          channelId
          hostToken
        }
      }
      ''',
    }),
  );

  if (response.statusCode == 200) {
    final res = jsonDecode(response.body);

    return res["data"]["requestSendChannel"];
  }

  return null;
}

Future<dynamic?> joinChannel(channelId, encappedKey) async {
  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'query': '''mutation {
        joinSendChannel(
          channelId: "$channelId",
          encappedKey: "$encappedKey",
        )
      }
      ''',
    }),
  );

  if (response.statusCode == 200) {
    final res = jsonDecode(response.body);

    return res["data"]["joinSendChannel"];
  }

  return null;
}

Future<String?> approvePairing(channelId, deviceToken) async {
  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'query': '''mutation {
        approveSendChannelPairing(
          channelId: "$channelId",
          deviceToken: "$deviceToken",
        )
      }
      ''',
    }),
  );

  if (response.statusCode == 200) {
    final res = jsonDecode(response.body);

    return res["data"]["approveSendChannelPairing"];
  }

  return null;
}
