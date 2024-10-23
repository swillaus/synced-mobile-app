import 'package:flutter/material.dart';
import 'package:synced/models/user.dart';
import 'package:synced/screens/auth/forgot_password.dart';
import 'package:synced/screens/auth/signup.dart';
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

    return value!.isNotEmpty && !regex.hasMatch(value)
        ? 'Enter a valid email address'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new)),
        backgroundColor: Colors.white,
        title: const Text(
          'Login',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                  child: Text('Enter your email',
                      style: TextStyle(
                          color: headingColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  validator: validateEmail,
                  controller: _emailController,
                  decoration: InputDecoration(
                      suffixIcon: Icon(
                        validEmail ? Icons.check_circle : null,
                        color: validEmail ? clickableColor : null,
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide(color: subHeadingColor)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide(color: subHeadingColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide(color: subHeadingColor)),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Enter your email',
                      hintStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: subHeadingColor)),
                ),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Enter your password',
                      style: TextStyle(
                          color: headingColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 5),
                TextFormField(
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
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide(color: subHeadingColor)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide(color: subHeadingColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide(color: subHeadingColor)),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Enter your password',
                      hintStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: subHeadingColor)),
                  obscureText: !showPassword,
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
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.0))),
                  fixedSize: WidgetStateProperty.all(Size(
                      MediaQuery.of(context).size.width * 0.8,
                      MediaQuery.of(context).size.height * 0.075)),
                  backgroundColor: WidgetStateProperty.all(clickableColor)),
              onPressed: () async {
                setState(() {
                  showSpinner = true;
                  showError = false;
                });
                if (_emailController.text == '' ||
                    _passwordController.text == '') {
                  setState(() {
                    errorMessage = "Incorrect email or password. Try again.";
                    showError = true;
                    showSpinner = false;
                  });
                  return;
                }
                final resp = await ApiService.authenticateUser(
                    _emailController.text, _passwordController.text);
                if (resp.isEmpty || resp['status'] != 0) {
                  setState(() {
                    showSpinner = false;
                    errorMessage = resp['message'] ?? "Something went wrong";
                    showError = true;
                  });
                  return;
                }
                await _db.deleteUsers();
                User.email = _emailController.text;
                User.password = _passwordController.text;
                User.name = resp['data']['user']['name'];
                User.authToken = resp['data']['access_token'];
                _db.saveUser();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HomeScreen(pageIndex: 0)));
              },
              child: const Text(
                'Log in',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Don\'t have an account?',
                    style: TextStyle(color: headingColor)),
                TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignupPage())),
                    child: Text('Sign up',
                        style: TextStyle(color: clickableColor)))
              ],
            ),
          ],
        ),
      ),
    );
  }
}
