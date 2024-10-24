import 'package:flutter/material.dart';
import 'package:synced/screens/auth/login.dart';
import 'package:synced/screens/auth/verification_code.dart';
import 'package:synced/utils/constants.dart';
import 'package:synced/utils/widgets.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool showPassword = false;
  bool showSpinner = false;
  bool showError = false;
  String errorMessage = '';
  bool validEmail = false;

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
        backgroundColor: Colors.white,
        title: const Text(
          'Sign Up',
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
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: subHeadingColor)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: subHeadingColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
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
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: subHeadingColor)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: subHeadingColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
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
            const SizedBox(height: 15),
            ElevatedButton(
              style: ButtonStyle(
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0))),
                  fixedSize: WidgetStateProperty.all(Size(
                      MediaQuery.of(context).size.width * 0.8,
                      MediaQuery.of(context).size.height * 0.06)),
                  backgroundColor: WidgetStateProperty.all(clickableColor)),
              onPressed: () async {
                // setState(() {
                //   showSpinner = true;
                //   showError = false;
                // });
                // if (_emailController.text == '' ||
                //     _passwordController.text == '') {
                //   setState(() {
                //     errorMessage = "Please fill all the fields.";
                //     showError = true;
                //     showSpinner = false;
                //   });
                // }
                //
                // final resp = await ApiService.userSignup(
                //     _emailController.text, _passwordController.text);
                // if (resp == null || resp['code'] != 200) {
                //   setState(() {
                //     showSpinner = false;
                //     errorMessage = resp['reason'];
                //     showError = true;
                //   });
                //   return;
                // }
                // Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //         builder: (context) => VerificationCodePage(
                //             email: _emailController.text,
                //             password: _passwordController.text,
                //             source: 'auth')));
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => VerificationCodePage(
                            email: _emailController.text,
                            password: _passwordController.text,
                            source: 'auth')));
              },
              child: const Text(
                'Send OTP code',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account?',
                    style: TextStyle(color: headingColor)),
                TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage())),
                    child:
                        Text('Login', style: TextStyle(color: clickableColor)))
              ],
            )
          ],
        ),
      ),
    );
  }
}
