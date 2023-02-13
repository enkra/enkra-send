import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';

part 'qr_code_scanner.g.dart';

class QrCodeScanner extends StatefulWidget {
  const QrCodeScanner({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QrCodeScannerState();
}

class _QrCodeScannerState extends State<QrCodeScanner> {
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR code"),
        backgroundColor: theme.colorScheme.secondary,
        surfaceTintColor: theme.colorScheme.secondary,
      ),
      body: _buildQrView(context),
    );
  }

  Widget _buildQrView(BuildContext context) {
    final theme = Theme.of(context);

    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        QRView(
          key: qrKey,
          onQRViewCreated: (ctrl) => _onQRViewCreated(ctrl, context),
          onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
        ),
        const _ScannerOverlay(),
      ],
    );
  }

  void _onQRViewCreated(QRViewController controller, context) {
    this.controller = controller;

    controller.scannedDataStream
        .distinct((p, n) => p.code == p.code)
        .listen((scanData) {
      if (scanData.code != null) {
        Navigator.pop(context, scanData.code!);
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

@swidget
Widget __scannerOverlay(BuildContext context) {
  final theme = Theme.of(context);

  // Check how width or tall the device is and change the scanArea and overlay accordingly.
  var cutBoxSize = (MediaQuery.of(context).size.width < 400 ||
          MediaQuery.of(context).size.height < 400)
      ? 150.0
      : 300.0;

  if ((MediaQuery.of(context).size.height - cutBoxSize).floor().isOdd) {
    cutBoxSize = cutBoxSize + 1;
  }

  const overlayColor = Color.fromRGBO(0, 0, 0, 80);

  final overlaySize = cutBoxSize * (1 + 20.0 / 256.0);

  final background = Column(
    children: [
      Expanded(
        child: Container(
          color: overlayColor,
        ),
      ),
      SizedBox(
        height: cutBoxSize,
        child: Row(
          children: [
            Expanded(
              child: Container(
                color: overlayColor,
              ),
            ),
            SizedBox(
              width: cutBoxSize,
              height: cutBoxSize,
            ),
            Expanded(
              child: Container(
                color: overlayColor,
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: Container(
          color: overlayColor,
        ),
      ),
    ],
  );

  return Stack(
    alignment: AlignmentDirectional.center,
    children: [
      background,
      SizedBox(
        width: overlaySize,
        height: overlaySize,
        child: SvgPicture.asset(
          'assets/qrcode-scanner.svg',
          semanticsLabel: 'QR code scanner',
          fit: BoxFit.fill,
          color: theme.colorScheme.primary,
        ),
      ),
    ],
  );
}
