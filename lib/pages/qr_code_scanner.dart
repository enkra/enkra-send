import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

part 'qr_code_scanner.g.dart';

class QrCodeScanner extends StatefulWidget {
  const QrCodeScanner({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QrCodeScannerState();
}

class _QrCodeScannerState extends State<QrCodeScanner> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _didScan = false;
  bool _didShowPermissionError = false;

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
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        MobileScanner(
          controller: controller,
          onDetect: (capture) => _onDetect(capture, context),
          errorBuilder: _onScannerError,
        ),
        const _ScannerOverlay(),
      ],
    );
  }

  void _onDetect(BarcodeCapture capture, BuildContext context) {
    if (_didScan) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        _didScan = true;
        controller.stop();
        Navigator.pop(context, value);
        return;
      }
    }
  }

  Widget _onScannerError(BuildContext context, MobileScannerException error) {
    if (error.errorCode == MobileScannerErrorCode.permissionDenied &&
        !_didShowPermissionError) {
      _didShowPermissionError = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('no Permission')),
        );
      });
    }

    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Icon(
          Icons.error,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
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
