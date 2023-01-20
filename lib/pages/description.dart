import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:flutter_svg/flutter_svg.dart';

part 'description.g.dart';

@swidget
Widget description(
  BuildContext context,
) {
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
          "Our end-to-end encryption technology ensures that your files are protected from prying eyes during transfer. Enkra Send guarantees that your data stays in the right hands.",
          style: TextStyle(
            fontSize: 17,
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
