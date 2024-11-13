import 'package:flutter/material.dart';
import 'package:synced/screens/auth/login.dart';
import 'package:synced/utils/api_services.dart';
import 'package:synced/utils/constants.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, required this.email});

  final String email;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool showSpinner = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool showError = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black)),
      ),
      body: Container(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.1),
          color: Colors.white,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Image.asset(
                  'assets/reset_password.png',
                )),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                const Center(
                    child: Text('Reset Your Password',
                        style: TextStyle(
                            fontSize: 24,
                            color: Colors.black,
                            fontWeight: FontWeight.w600))),
                const Center(
                    child: Text('Now you can reset your old password',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.w500))),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Text('Enter a new password',
                    style: TextStyle(color: headingColor, fontSize: 18)),
                const SizedBox(height: 5),
                TextField(
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
                const SizedBox(height: 15),
                Text('Confirm new password',
                    style: TextStyle(color: headingColor, fontSize: 18)),
                const SizedBox(height: 5),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(
                          // Based on passwordVisible state choose the icon
                          !showConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: subHeadingColor,
                        ),
                        onPressed: () {
                          setState(() {
                            showConfirmPassword = !showConfirmPassword;
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
                      hintText: 'Confirm your password',
                      hintStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: subHeadingColor)),
                  obscureText: !showConfirmPassword,
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0))),
                      fixedSize: WidgetStateProperty.all(Size(
                          MediaQuery.of(context).size.width * 0.8,
                          MediaQuery.of(context).size.height * 0.06)),
                      backgroundColor: WidgetStateProperty.all(clickableColor)),
                  onPressed: () async {
                    setState(() {
                      showSpinner = true;
                      showError = false;
                    });
                    if (_passwordController.text == '' ||
                        _confirmPasswordController.text == '' ||
                        _passwordController.text !=
                            _confirmPasswordController.text) {
                      setState(() {
                        errorMessage =
                            "Passwords do not match, please try again.";
                        showError = true;
                        showSpinner = false;
                      });
                      return;
                    }
                    final resp = await ApiService.changePassword(
                        _passwordController.text, widget.email, context);
                    if (resp['code'] != 200) {
                      setState(() {
                        showSpinner = false;
                        errorMessage = resp['reason'];
                        showError = true;
                      });
                      return;
                    }
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PasswordChanged()));
                  },
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ])),
    );
  }
}

class PasswordChanged extends StatefulWidget {
  const PasswordChanged({super.key});

  @override
  State<PasswordChanged> createState() => _PasswordChangedState();
}

class _PasswordChangedState extends State<PasswordChanged> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.1),
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
                child: Image.asset(
              'assets/success_tick.png',
            )),
            const SizedBox(height: 25),
            const Text('Password Updated!',
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.black,
                    fontWeight: FontWeight.w800)),
            Text('Your password has been changed successfully.',
                style: TextStyle(color: headingColor, fontSize: 18)),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ButtonStyle(
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0))),
                  fixedSize: WidgetStateProperty.all(Size(
                      MediaQuery.of(context).size.width * 0.8,
                      MediaQuery.of(context).size.height * 0.06)),
                  backgroundColor: WidgetStateProperty.all(clickableColor)),
              onPressed: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const LoginPage())),
              child: Text(
                'Login',
                style: TextStyle(color: headingColor, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
