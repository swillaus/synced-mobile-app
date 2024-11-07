import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:go_router/go_router.dart';
import 'package:is_first_run/is_first_run.dart';
import 'package:synced/models/user.dart';
import 'package:synced/screens/auth/login.dart';
import 'package:synced/screens/home/home_screen.dart';
import 'package:synced/utils/constants.dart';
import 'package:synced/utils/database_helper.dart';

String selectedOrgId = '';
final navigatorKey = GlobalKey<NavigatorState>();
final appLinks = AppLinks();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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
    GoRouter(
      routes: [
        GoRoute(
          path: '/auth/xero-sign-in',
          builder: (context, state) =>
              const HomeScreen(tabIndex: 0, navbarIndex: 0),
        )
      ],
    );

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
      imageVerticalOffset: 50,
      centerBackground: true,
      hasSkip: true,
      skipFunctionOverride: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      ),
      skipTextButton: Text('Skip',
          style: TextStyle(
              color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
      onFinish: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
      },
      finishButtonText: '➔',
      finishButtonStyle: FinishButtonStyle(
        shape: const CircleBorder(),
        backgroundColor: clickableColor,
      ),
      finishButtonTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
      controllerColor: clickableColor,
      totalPage: 3,
      headerBackgroundColor: Colors.white,
      pageBackgroundColor: Colors.white,
      background: [
        Image.asset(
          'assets/onboarding/onboarding_screen_1.png',
          height: 400,
        ),
        Image.asset(
          'assets/onboarding/onboarding_screen_2.png',
          height: 400,
        ),
        Image.asset(
          'assets/onboarding/onboarding_screen_3.png',
          height: 400,
        ),
      ],
      speed: 1.8,
      pageBodies: [
        Container(
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                height: 480,
              ),
              Text(
                'Scan Receipts With Ease',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 24.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                'Quickly capture and upload your receipts directly from your phone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                height: 480,
              ),
              Text(
                'Organize Your Expenses',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 24.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                'Automatically categorize and consolidate receipts into detailed reports.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                height: 480,
              ),
              Text(
                'Submit and Get Reimbursed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 24.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                'Generate professional reports and send them for approval or payment in just a few taps.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
