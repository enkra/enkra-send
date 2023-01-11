import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

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

  final String _cipherKey;

  final AesGcm aes = AesGcm.with128bits();

  PairedState(this._channel, this._cipherKey) {
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
        _messages.add(message);
        notifyListeners();
      }
    });
  }

  _encryptContent(plaintext) async {
    final secretKey = SecretKey(base64Url.decode(_cipherKey));

    final nonce = aes.newNonce();

    final secretBox = await aes.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );

    return base64Url.encode(secretBox.concatenation());
  }

  _decryptContent(ciphertext) async {
    final secretKey = SecretKey(base64Url.decode(_cipherKey));

    final secretBox = SecretBox.fromConcatenation(
      base64Url.decode(ciphertext),
      nonceLength: 12,
      macLength: 16,
    );

    final plaintext = await aes.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(plaintext);
  }
}
