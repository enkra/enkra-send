import 'package:enkra_send/util.dart';
import 'package:flutter/material.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';

import '../models/device_send_manager.dart';

import 'qr_code_scanner.dart';

part 'login.g.dart';

@swidget
Widget pairing(
  BuildContext context, {
  required WaitToPairState waitToPairState,
}) {
  if (isMobile()) {
    return ScanToPair(waitToPairState: waitToPairState);
  } else {
    return Container(
      padding: const EdgeInsets.only(
        top: 32,
        bottom: 32,
        left: 32,
        right: 32,
      ),
      child: WaitToPair(waitToPairState: waitToPairState),
    );
  }
}

@swidget
Widget waitToPair(
  BuildContext context, {
  required WaitToPairState waitToPairState,
}) {
  final theme = Theme.of(context);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const SizedBox(height: 30),
      Text(
        "Enkra Send",
        style: TextStyle(
          fontSize: 35,
          color: theme.colorScheme.primary,
        ),
      ),
      const Spacer(flex: 2),
      _SendQr(
        size: 150,
        data: waitToPairState.pairingUrl(),
        color: theme.colorScheme.background,
      ),
      const SizedBox(height: 30),
      Text(
        "Scan to pair devices",
        style: TextStyle(
          fontSize: 30,
          color: theme.colorScheme.tertiary,
        ),
      ),
      const SizedBox(height: 30),
      const Text(
        "Use your phone's QR code scanner",
        style: TextStyle(
          fontSize: 20,
        ),
      ),
      const SizedBox(
        width: 330,
        child: _OrDivider(),
      ),
      RichText(
        text: TextSpan(
          text: 'visit ',
          style: TextStyle(
            fontSize: 20,
            color: theme.colorScheme.onSurface,
          ),
          children: <TextSpan>[
            TextSpan(
              text: 'send.enkra.io',
              style: TextStyle(
                color: theme.primaryColor,
              ),
            ),
            const TextSpan(text: ' on mobile browser.'),
          ],
        ),
      ),
      const Spacer(flex: 2),
    ],
  );
}

@swidget
Widget scanToPair(
  BuildContext context, {
  required WaitToPairState waitToPairState,
}) {
  final theme = Theme.of(context);

  return Column(
    children: [
      Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
        ),
        child: Column(
          children: [
            const SizedBox(height: 50),
            Text(
              "Transfer files with ease and privacy",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Easily send personal documents, work files, or sensitive text between your phone and computer with E2EE(End-to-end encryption).",
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
      Expanded(
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Column(
              children: [
                Container(
                  color: Colors.transparent,
                  height: 80,
                  width: double.infinity,
                ),
                Expanded(
                  child: Container(
                    color: theme.colorScheme.background,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
              ),
              child: Column(
                children: [
                  _SendQr(
                    size: 130,
                    data: waitToPairState.pairingUrl(),
                    color: theme.colorScheme.background,
                  ),
                  const Spacer(),
                  Text(
                    "Scan QR code to pair this device",
                    style: TextStyle(
                      fontSize: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(
                    width: 300,
                    child: _OrDivider(),
                  ),
                  SizedBox(
                    width: 320,
                    child: OutlinedButton(
                      onPressed: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QrCodeScanner(),
                          ),
                        );

                        final deviceSendManager =
                            Provider.of<DeviceSendManager>(context,
                                listen: false);

                        deviceSendManager.pairTo(res);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.tertiary),
                        backgroundColor: theme.colorScheme.background,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox.square(
                            dimension: 30,
                            child: Icon(
                              Icons.qr_code_scanner_outlined,
                              color: theme.colorScheme.tertiary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Open Scanner",
                            style: TextStyle(
                              fontSize: 20,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  RichText(
                    text: TextSpan(
                      text: 'visit ',
                      style: TextStyle(
                        fontSize: 18,
                        color: theme.colorScheme.onSurface,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: 'send.enkra.io',
                          style: TextStyle(
                            color: theme.primaryColor,
                          ),
                        ),
                        const TextSpan(text: ' on your PC browser'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

@swidget
Widget __sendQr(
  BuildContext context, {
  required Future<String> data,
  required double size,
  Color color = Colors.white,
}) {
  final theme = Theme.of(context);

  return Container(
    decoration: BoxDecoration(
      border: Border.all(
        color: theme.colorScheme.primary,
      ),
      borderRadius: const BorderRadius.all(Radius.circular(15)),
      color: color,
    ),
    padding: const EdgeInsets.all(15),
    child: FutureBuilder<String>(
        future: data,
        builder: (_, snapshot) {
          if (snapshot.hasData) {
            return PrettyQr(
              size: size,
              data: snapshot.data!,
              roundEdges: true,
            );
          } else {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                color: theme.colorScheme.secondary,
              ),
            );
          }
        }),
  );
}

@swidget
Widget __orDivider(
  BuildContext context,
) {
  return Row(
    children: [
      Expanded(
        child: Divider(
          color: Colors.grey[400]!,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        "or",
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[600]!,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Divider(
          color: Colors.grey[400]!,
        ),
      ),
    ],
  );
}
