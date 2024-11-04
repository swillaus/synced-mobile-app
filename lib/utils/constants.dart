import 'package:flutter/material.dart';

String hostUrl = 'https://syncedtestingapi.azurewebsites.net';
// String hostUrl = 'https://syncedapi.azurewebsites.net';

Color headingColor = const Color(0XFF2A2A2A);
Color subHeadingColor = const Color(0XFFD1D1D1);
Color clickableColor = const Color(0XFFF6CA58);
Color textColor = const Color(0XFF2A2A2A);

CircularProgressIndicator appLoader = CircularProgressIndicator(
  strokeWidth: 2.0,
  color: clickableColor,
);
