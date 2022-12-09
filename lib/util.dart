import 'package:flutter/foundation.dart';

bool isMobile() {
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;
}
