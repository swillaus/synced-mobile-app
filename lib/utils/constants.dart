import 'package:flutter/material.dart';

String hostUrl = 'https://syncedtestingapi.azurewebsites.net';

Color headingColor = const Color(0XFF2A2A2A);
Color subHeadingColor = const Color(0XFFD1D1D1);
Color clickableColor = const Color(0XFFF6CA58);
Color textColor = const Color(0XFF2A2A2A);

String xeroClientId = '90244E7404054BA8B0FAB1DA5F949573';
String xeroSignInCallbackUrl = '$hostUrl/api/Account/XeroSignIn';
String xeroRedirectUrlScheme = 'net.azurewebsites.syncedtestingapi';
String xeroState = 'afiGl5r9s2w';

String xeroAuthUrl =
    'https://login.xero.com/identity/connect/authorize?response_type=code&client_id=$xeroClientId&redirect_uri=$xeroSignInCallbackUrl&scope=openid profile email&state=$xeroState';
// String xeroAuthUrl = 'https://login.xero.com/identity/connect/authorize';
String xeroTokenUrl = 'https://identity.xero.com/connect/token';
