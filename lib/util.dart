import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

bool isMobile() {
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;
}

void copyToClipboardAutoClear(String? content) async {
  if (content == null) {
    return;
  }

  await Clipboard.setData(ClipboardData(text: content));

  // Auto clear clipboard after 30 seconds.
  // Reduce risk of clipboard information leak.
  await Future.delayed(const Duration(seconds: 30));
  await Clipboard.setData(const ClipboardData(text: ""));
}

void downloadBlobFile(String fileName, Uint8List bytes) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement anchorElement = html.AnchorElement(href: url);
  anchorElement.download = fileName;
  anchorElement.click();
}

Future<String?> copyFromClipboard() async {
  final data = await Clipboard.getData("text/plain");

  return data?.text;
}
