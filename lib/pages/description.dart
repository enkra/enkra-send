import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

part 'description.g.dart';

@swidget
Widget description(
  BuildContext context,
) {
  final theme = Theme.of(context);

  return Container(
    padding: const EdgeInsets.only(
      top: 32,
      bottom: 32,
      left: 32,
      right: 32,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transfer files with ease and privacy',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Easily send personal documents, work files, or sensitive text between your phone and computer.",
          style: TextStyle(
            fontSize: 17,
          ),
        ),
        const Spacer(),
        const Text(
          'End-to-end encryption',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Our E2EE(end-to-end encryption) technology ensures that your files are protected from prying eyes during transfer. Enkra Send guarantees that your data stays in the right hands.",
          style: TextStyle(
            fontSize: 17,
          ),
        ),
        const Spacer(),
        const Text(
          "Don't trust, just verify",
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 17,
            ),
            children: [
              const TextSpan(text: "Source code is avaliable on "),
              TextSpan(
                text: "Github",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                ),
                recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  const url = 'https://github.com/enkra/enkra-send';
                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    throw 'Could not launch $url';
                  }
                },
              ),
              const TextSpan(text: ". Feel free to review and verify our E2EE claims."),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: SvgPicture.asset(
            'assets/device-transfer.svg',
            semanticsLabel: 'Enkra Send transfer picture',
            fit: BoxFit.fill,
          ),
        ),
      ],
    ),
  );
}
