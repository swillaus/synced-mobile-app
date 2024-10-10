import 'package:flutter/material.dart';
import 'package:synced/screens/auth/login.dart';
import 'package:synced/utils/api_services.dart';
import 'package:synced/utils/constants.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
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
        title: const Text('Forgot',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
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
                  'assets/forgot_pass_img.png',
                )),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                const Center(
                  child: Text('Forgot Password?',
                      style: TextStyle(
                          fontSize: 24,
                          color: Colors.black,
                          fontWeight: FontWeight.w600)),
                ),
                const Center(
                  child: Text(
                      'Don’t worry! it happens. Please enter phone number associated with your account',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w500)),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                Text('Enter your email',
                    style: TextStyle(
                        color: headingColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
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
                ElevatedButton(
                  style: ButtonStyle(
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.0))),
                      fixedSize: WidgetStateProperty.all(Size(
                          MediaQuery.of(context).size.width * 0.8,
                          MediaQuery.of(context).size.height * 0.075)),
                      backgroundColor: WidgetStateProperty.all(clickableColor)),
                  onPressed: () async {
                    // TODO - call verify OTP API
                    final resp =
                        await ApiService.resetPassword(_emailController.text);
                    if (resp['status'] != 0) {
                      print('Something went wrong');
                      return;
                    }
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              backgroundColor: Colors.white,
                              content: Center(
                                child: Container(
                                  color: Colors.white,
                                  height:
                                      MediaQuery.of(context).size.height * 0.35,
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  child: Text(resp['message']),
                                ),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const LoginPage()),
                                            (Route<dynamic> route) => false),
                                    child: const Text('Ok'))
                              ],
                            ));
                  },
                  child: const Text(
                    'Send OTP code',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ])),
    );
  }
}
