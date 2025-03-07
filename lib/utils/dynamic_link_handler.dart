import 'dart:convert';
import 'dart:developer';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:synced/main.dart';
import 'package:synced/models/user.dart';
import 'package:synced/screens/home/home_screen.dart';

import 'database_helper.dart';

/// Provides methods to manage dynamic links.
final class DynamicLinkHandler {
  DynamicLinkHandler._();

  static final instance = DynamicLinkHandler._();

  final _appLinks = AppLinks();

  /// Initializes the [DynamicLinkHandler].
  Future<void> initialize() async {
    // * Listens to the dynamic links and manages navigation.
    _appLinks.uriLinkStream.listen(_handleLinkData).onError((error) {
      log('$error', name: 'Dynamic Link Handler');
    });
    _checkInitialLink();
  }

  /// Handle navigation if initial link is found on app start.
  Future<void> _checkInitialLink() async {
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleLinkData(initialLink);
    }
  }

  /// Handles the link navigation Dynamic Links.
  void _handleLinkData(Uri data) async {
    final queryParams = data.queryParameters;
    log(data.toString(), name: 'Dynamic Link Handler');
    if (queryParams.isNotEmpty) {
      print(json.decode(queryParams['data']!));
      final DatabaseHelper db = DatabaseHelper();
      await db.deleteUsers();
      ChromeSafariBrowser.clearWebsiteData();
      await browser?.close();
      User.userId = json.decode(queryParams['data']!)['Data']['user']['UserId'];
      User.email = json.decode(queryParams['data']!)['Data']['user']['Email'];
      User.name = json.decode(queryParams['data']!)['Data']['user']['Name'];
      User.authToken =
          json.decode(queryParams['data']!)['Data']['access_token'];
      db.saveUser();
      Navigator.push(
          navigatorKey.currentContext!,
          MaterialPageRoute(
              builder: (context) => const HomeScreen(tabIndex: 0)));
    }
  }
}
