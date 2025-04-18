import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:is_first_run/is_first_run.dart';
import 'package:synced/models/user.dart';
import 'package:synced/screens/auth/login.dart';
import 'package:synced/screens/home/home_screen.dart';
import 'package:synced/utils/constants.dart';
import 'package:synced/utils/database_helper.dart';
import 'package:synced/utils/dynamic_link_handler.dart';
import 'package:flutter_svg/flutter_svg.dart';  // Add this import

String selectedOrgId = '';
String defaultCurrency = 'USD';
final navigatorKey = GlobalKey<NavigatorState>();
ChromeSafariBrowser? browser;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  DynamicLinkHandler.instance.initialize();

  bool firstCall = await IsFirstRun.isFirstCall();

  var db = DatabaseHelper();
  var isLoggedIn = await db.isLoggedIn();
  String authToken = "";

  if (isLoggedIn) {
    List<Map<String, dynamic>> loggedInUser = await db.getLoggedInUser();
    if (loggedInUser.isNotEmpty) {
      authToken = loggedInUser[0]['authToken'];
      User.authToken = authToken;
      User.email = loggedInUser[0]["email"];
      User.password = loggedInUser[0]["password"];
      User.userId = loggedInUser[0]["userId"];
    }
  }

  runApp(App(firstCall: firstCall, isLoggedIn: isLoggedIn));
}

class App extends StatefulWidget {
  const App({super.key, required this.firstCall, required this.isLoggedIn});

  final bool firstCall, isLoggedIn;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  MaterialColor generateMaterialColor(Color color) {
    return MaterialColor(color.value, {
      50: tintColor(color, 0.9),
      100: tintColor(color, 0.8),
      200: tintColor(color, 0.6),
      300: tintColor(color, 0.4),
      400: tintColor(color, 0.2),
      500: color,
      600: shadeColor(color, 0.1),
      700: shadeColor(color, 0.2),
      800: shadeColor(color, 0.3),
      900: shadeColor(color, 0.4),
    });
  }

  int tintValue(int value, double factor) =>
      max(0, min((value + ((255 - value) * factor)).round(), 255));

  Color tintColor(Color color, double factor) => Color.fromRGBO(
      tintValue(color.red, factor),
      tintValue(color.green, factor),
      tintValue(color.blue, factor),
      1);

  int shadeValue(int value, double factor) =>
      max(0, min(value - (value * factor).round(), 255));

  Color shadeColor(Color color, double factor) => Color.fromRGBO(
      shadeValue(color.red, factor),
      shadeValue(color.green, factor),
      shadeValue(color.blue, factor),
      1);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      routes: {
        '/home': (context) => const HomeScreen(tabIndex: 0, navbarIndex: 0),
      },
      theme: ThemeData(
          fontFamily: 'Inter',
          primaryColor: clickableColor,
          colorScheme: ColorScheme.fromSeed(
              seedColor: clickableColor, brightness: Brightness.light),
          primarySwatch: generateMaterialColor(clickableColor)),
      home: widget.firstCall
          ? OnboardingPage(firstCall: widget.firstCall)
          : widget.isLoggedIn
              ? const HomeScreen(tabIndex: 0)
              : const LoginPage(),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.firstCall});

  final bool firstCall;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  @override
  Widget build(BuildContext context) {
    return OnBoardingSlider(
      imageVerticalOffset: 0,
      centerBackground: true,
      hasSkip: true,
      skipFunctionOverride: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      ),
      skipTextButton: Text(
        'Skip',
        style: TextStyle(
          color: textColor.withOpacity(0.7),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onFinish: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      },
      finishButtonStyle: FinishButtonStyle(
        shape: const CircleBorder(),
        backgroundColor: clickableColor,
      ),
      finishButtonText: '→',
      finishButtonTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w300,
      ),
      controllerColor: clickableColor,
      totalPage: 3,
      headerBackgroundColor: Colors.white,
      pageBackgroundColor: Colors.white,
      background: [
        Container(
          padding: const EdgeInsets.only(bottom: 60),
          child: SvgPicture.asset(
            'assets/onboarding/onboarding_screen_1.svg',
            height: 400,
            placeholderBuilder: (context) => Container(
              height: 400,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(bottom: 60),
          child: SvgPicture.asset(
            'assets/onboarding/onboarding_screen_2.svg',
            height: 400,
            placeholderBuilder: (context) => Container(
              height: 400,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(bottom: 60),
          child: SvgPicture.asset(
            'assets/onboarding/onboarding_screen_3.svg',
            height: 400,
            placeholderBuilder: (context) => Container(
              height: 400,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
      speed: 1.5, // Slightly slower for smoother transitions
      pageBodies: [
        _buildOnboardingPage(
          'Scan Receipts With Ease',
          'Quickly capture and upload your receipts directly from your phone.',
        ),
        _buildOnboardingPage(
          'Organize Your Expenses',
          'Automatically categorize and consolidate receipts into detailed reports.',
        ),
        _buildOnboardingPage(
          'Submit and Get Reimbursed',
          'Generate professional reports and send them for approval or payment in just a few taps.',
        ),
      ],
    );
  }

  Widget _buildOnboardingPage(String title, String description) {
    return Container(
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 28.0,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 16.0,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
