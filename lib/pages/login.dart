import 'package:enkra_send/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:simple_barcode_scanner/enum.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:provider/provider.dart';

import '../models/device_send_manager.dart';
import '../util.dart';

part 'login.g.dart';

@swidget
Widget pairing(
  BuildContext context, {
  required WaitToPairState waitToPairState,
}) {
  if (isMobile()) {
    return ScanToPair(waitToPairState: waitToPairState);
  } else {
    return WaitToPair(waitToPairState: waitToPairState);
  }
}

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

@swidget
Widget scanToPair(
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
              ElevatedButton(
                onPressed: () async {
                  var res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SimpleBarcodeScannerPage(
                        scanType: ScanType.qr,
                      ),
                    ),
                  );

                  final deviceSendManager =
                      Provider.of<DeviceSendManager>(context, listen: false);

                  if (res is String) {
                    deviceSendManager.pairTo(res);
                  }
                },
                child: const Text('Open Scanner'),
              )
            ],
          ),
        ),
      ),
    ],
  );
}
