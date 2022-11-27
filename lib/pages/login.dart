import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/send.dart';

part 'login.g.dart';

@swidget
Widget waitToPair(
  BuildContext context, {
  required WaitToPairState waitToPairState,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImage(
                data: waitToPairState.pairingUrl(),
                version: QrVersions.auto,
                size: 200.0,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
