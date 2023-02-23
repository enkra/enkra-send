import 'dart:convert';
import 'dart:typed_data';

import 'package:enkra_send/native/bridge_generated.dart';

import 'app_state.dart';
import 'ws_client.dart';

enum MessageType {
  Text,
  Image,
  File,
}

class Message {
  final MessageType type;

  final String? text;
  final Uint8List? content;
  final String? fileName;

  Message(
    this.type, {
    this.text,
    this.content,
    this.fileName,
  });

  static Message? fromJson(String json) {
    final message = jsonDecode(json);

    if (message["type"] == "text") {
      return Message(
        MessageType.Text,
        text: message["text"],
      );
    } else if (message["type"] == "image") {
      final picture = base64.decode(message["image"]);
      return Message(
        MessageType.Image,
        content: picture,
        fileName: message["fileName"],
      );
    } else if (message["type"] == "file") {
      final file = base64.decode(message["content"]);
      return Message(
        MessageType.File,
        content: file,
        fileName: message["fileName"],
      );
    }
    return null;
  }

  String toJson() {
    switch (type) {
      case MessageType.Text:
        {
          return jsonEncode({
            "type": "text",
            "text": text!,
          });
        }
        break;
      case MessageType.Image:
        {
          return jsonEncode({
            "type": "image",
            "image": base64.encode(content!.toList()),
            "fileName": fileName!,
          });
        }
      case MessageType.File:
        {
          return jsonEncode({
            "type": "file",
            "content": base64.encode(content!.toList()),
            "fileName": fileName!,
          });
        }
        break;
    }
  }
}

class PairedState extends AppState {
  final WsClient _channel;

  final List<Message> _messages = [];

  final AeadCipher _aeadCipher;

  PairedState(this._channel, this._aeadCipher) {
    _listenChannel(_channel);
  }

  get messages => _messages;

  void sendText(text) async {
    _sendMessage(Message(
      MessageType.Text,
      text: text,
    ));
  }

  void sendImage(String fileName, Uint8List image) async {
    _sendMessage(Message(
      MessageType.Image,
      content: image,
      fileName: fileName,
    ));
  }

  void sendFile(String fileName, Uint8List content) async {
    _sendMessage(Message(
      MessageType.File,
      content: content,
      fileName: fileName,
    ));
  }

  _sendMessage(Message msg) async {
    final content = await _encryptContent(msg.toJson());

    _channel.sink.add(content);

    _addNewMessage(msg);
  }

  _listenChannel(channel) {
    channel.listen((msg) async {
      final rawMessage = jsonDecode(msg);

      if (rawMessage["event"] != "message") {
        return;
      }

      final content = await _decryptContent(rawMessage["content"]);

      final message = Message.fromJson(content);

      if (message != null) {
        _addNewMessage(message);
      }
    });
  }

  _addNewMessage(Message msg) {
    _messages.add(msg);
    notifyListeners();
  }

  _encryptContent(String plaintext) async {
    final ciphertext = await _aeadCipher.encrypt(
      pt: Uint8List.fromList(utf8.encode(plaintext)),
      aad: Uint8List.fromList(utf8.encode("")),
    );

    return base64Url.encode(ciphertext);
  }

  _decryptContent(String ciphertext) async {
    final plaintext = await _aeadCipher.decrypt(
      ct: base64Url.decode(ciphertext),
      aad: Uint8List.fromList(utf8.encode("")),
    );

    return utf8.decode(plaintext);
  }

  void dispose() {
    _aeadCipher.inner.dispose();
  }
}
