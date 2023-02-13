import 'package:flutter/material.dart';

import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:flutter_svg/flutter_svg.dart';

part 'app_title.g.dart';

@swidget
Widget appTitle(
  BuildContext context, {
  required String title,
}) {
  return Row(
    children: [
      Container(
        width: 25,
        height: 25,
        padding: const EdgeInsets.all(2),
        child: SvgPicture.asset(
          'assets/logo.svg',
          semanticsLabel: 'Enkra Send logo',
        ),
      ),
      const SizedBox(width: 10),
      Text(title),
    ],
  );
}
