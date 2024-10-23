import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:is_first_run/is_first_run.dart';
import 'package:synced/models/user.dart';
import 'package:synced/screens/auth/signup.dart';
import 'package:synced/screens/home/home_screen.dart';
import 'package:synced/utils/constants.dart';
import 'package:synced/utils/database_helper.dart';

String selectedOrgId = '';
final navigatorKey = GlobalKey<NavigatorState>();

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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(
        fontFamily: 'Inter',
        primaryColor: clickableColor,
      ),
      home: widget.firstCall
          ? OnboardingPage(firstCall: widget.firstCall)
          : widget.isLoggedIn
              ? const HomeScreen(pageIndex: 0)
              : const SignupPage(),
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
          builder: (context) => const SignupPage(),
        ),
      ),
      skipTextButton: Text('Skip',
          style: TextStyle(
              color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
      onFinish: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SignupPage(),
          ),
        );
      },
      finishButtonText: 'Get Started!',
      finishButtonStyle: FinishButtonStyle(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24))),
        backgroundColor: clickableColor,
      ),
      finishButtonTextStyle: const TextStyle(color: Colors.white),
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
