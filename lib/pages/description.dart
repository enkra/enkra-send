import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';

part 'description.g.dart';

@swidget
Widget description(
  BuildContext context,
) {
  return const Text(
      'Use Enkra Send - send your fils between your phone and PC privately.');
}
