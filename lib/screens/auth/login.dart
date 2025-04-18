import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:synced/main.dart';
import 'package:synced/models/user.dart';
import 'package:synced/screens/auth/forgot_password.dart';
import 'package:synced/screens/home/home_screen.dart';
import 'package:synced/utils/api_services.dart';
import 'package:synced/utils/constants.dart';
import 'package:synced/utils/database_helper.dart';
import 'package:synced/utils/widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool rememberMeCheckValue = true;
  bool showPassword = false;
  bool showSpinner = false;
  bool showError = false;
  String errorMessage = '';
  bool validEmail = false;
  final DatabaseHelper _db = DatabaseHelper();
  bool isLoggingIn = false;

  String? validateEmail(String? value) {
    const pattern = r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"
        r'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-'
        r'\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*'
        r'[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4]'
        r'[0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9]'
        r'[0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\'
        r'x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])';
    final regex = RegExp(pattern);

    setState(() {
      value!.isNotEmpty && !regex.hasMatch(value)
          ? validEmail = false
          : validEmail = true;
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: const Text(
          '',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF344054)),
        ),
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.only(
            left: MediaQuery.of(context).size.width * 0.1,
            bottom: MediaQuery.of(context).size.width * 0.1,
            right: MediaQuery.of(context).size.width * 0.1),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Image.asset(
              'assets/logo_black.png',
              height: MediaQuery.of(context).size.height * 0.25,
              width: MediaQuery.of(context).size.width * 0.6,
            )),
            // SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            showError
                ? showErrorWidget(errorMessage)
                : const SizedBox(height: 0),
            Form(
                child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Email',
                      style: TextStyle(
                          color: headingColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 56,
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: TextFormField(
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF344054)),
                    keyboardType: TextInputType.emailAddress,
                    autovalidateMode: AutovalidateMode.onUnfocus,
                    validator: validateEmail,
                    controller: _emailController,
                    decoration: InputDecoration(
                      suffixIcon: _emailController.text.isNotEmpty
                          ? validEmail
                              ? Icon(
                                  Icons.check_circle,
                                  color: clickableColor,
                                )
                              : const Icon(Icons.close, color: Colors.red)
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: subHeadingColor)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: subHeadingColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: subHeadingColor)),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      hintText: 'Enter your email',
                      hintStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF9CA3AF)),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Password',
                      style: TextStyle(
                          color: headingColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: 56,
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: TextFormField(
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: headingColor),
                    controller: _passwordController,
                    decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: Icon(
                            // Based on passwordVisible state choose the icon
                            !showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: subHeadingColor,
                          ),
                          onPressed: () {
                            // Update the state i.e. toogle the state of passwordVisible variable
                            setState(() {
                              showPassword = !showPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: subHeadingColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: subHeadingColor)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: subHeadingColor)),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Enter your password',
                        hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: subHeadingColor)),
                    obscureText: !showPassword,
                  ),
                ),
              ],
            )),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                child: Text('Forgot password?',
                    style: TextStyle(color: clickableColor)),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ForgotPasswordPage())),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ButtonStyle(
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0))),
                  fixedSize: WidgetStateProperty.all(
                      Size(MediaQuery.of(context).size.width * 0.9, 56)),
                  backgroundColor: WidgetStateProperty.all(
                      isLoggingIn ? clickableColor.withOpacity(0.7) : clickableColor)),
              onPressed: isLoggingIn ? null : () async {
                if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                  setState(() {
                    errorMessage = "Please enter valid credentials.";
                    showError = true;
                  });
                  return;
                }

                setState(() {
                  isLoggingIn = true;
                  showError = false;
                });

                try {
                  final resp = await ApiService.authenticateUser(
                    _emailController.text, 
                    _passwordController.text
                  );

                  if (resp.isEmpty || resp['status'] != 0) {
                    setState(() {
                      isLoggingIn = false;
                      errorMessage = resp['message'] ?? "Something went wrong";
                      showError = true;
                    });
                    return;
                  }

                  await _db.deleteUsers();
                  User.userId = resp['data']['user']['userId'];
                  User.email = _emailController.text;
                  User.password = _passwordController.text;
                  User.name = resp['data']['user']['name'];
                  User.authToken = resp['data']['access_token'];
                  await _db.saveUser();

                  // Only navigate on success
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(tabIndex: 0)
                      )
                    );
                  }
                } catch (e) {
                  setState(() {
                    isLoggingIn = false;
                    errorMessage = "An error occurred. Please try again.";
                    showError = true;
                  });
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoggingIn) 
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 10),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  Text(
                    isLoggingIn ? 'Logging in...' : 'Login',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     Text('Don\'t have an account?',
            //         style: TextStyle(color: headingColor)),
            //     TextButton(
            //         onPressed: () => Navigator.push(
            //             context,
            //             MaterialPageRoute(
            //                 builder: (context) => const SignupPage())),
            //         child: Text('Sign up',
            //             style: TextStyle(color: clickableColor)))
            //   ],
            // ),
            const SizedBox(height: 15),
            const Center(
              child: Text(
                'or',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0XFF696969)),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ButtonStyle(
                  side: const WidgetStatePropertyAll(
                      BorderSide(color: Color(0xFF2563EB), width: 1.0)),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0))),
                  fixedSize: WidgetStateProperty.all(
                      Size(MediaQuery.of(context).size.width * 0.9, 56)),
                  backgroundColor: WidgetStateProperty.all(Colors.white)),
              onPressed: () async {
                setState(() {
                  showSpinner = true;
                });
                browser = ChromeSafariBrowser();
                browser?.open(
                    url: WebUri(xeroAuthUrl),
                    settings: ChromeSafariBrowserSettings(noHistory: true));
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/xero_logo.png',
                      height: 30, width: 30),
                  const SizedBox(width: 15),
                  const Text(
                    'Sign in with Xero',
                    style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
