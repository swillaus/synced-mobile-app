import 'package:flutter/material.dart';

String hostUrl = 'https://syncedapi.azurewebsites.net';

Color headingColor = const Color(0XFF2A2A2A);
Color subHeadingColor = const Color(0XFFD1D1D1);
Color clickableColor = const Color(0XFFF6CA58);
Color textColor = const Color(0XFF2A2A2A);

CircularProgressIndicator appLoader = CircularProgressIndicator(
  strokeWidth: 2.0,
  color: clickableColor,
);

// String xeroClientId = '90244E7404054BA8B0FAB1DA5F949573';
String xeroClientId = 'B1FBCF253E474AE29998C451E960B0CE';
String xeroSignInCallbackUrl = '$hostUrl/api/Account/XeroSignIn';
String xeroRedirectUrlScheme = 'net.azurewebsites.syncedapi';
String xeroState = 'afiGl5r9s2w';

String xeroAuthUrl =
    'https://login.xero.com/identity/connect/authorize?response_type=code&client_id=$xeroClientId&redirect_uri=$xeroSignInCallbackUrl&scope=openid profile email&state=$xeroState';
String xeroTokenUrl = 'https://identity.xero.com/connect/token';
