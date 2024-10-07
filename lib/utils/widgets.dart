import 'package:flutter/material.dart';

Widget showErrorWidget(message) {
  return Container(
    width: double.maxFinite,
    height: 50,
    color: Colors.red.shade50,
    child: Center(
        child: Text(message, style: const TextStyle(color: Color(0XFFD62334)))),
  );
}
