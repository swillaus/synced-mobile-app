import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:otp_timer_button/otp_timer_button.dart';
import 'package:synced/models/user.dart';
import 'package:synced/screens/auth/change_password.dart';
import 'package:synced/screens/home/home_screen.dart';
import 'package:synced/utils/api_services.dart';
import 'package:synced/utils/constants.dart';
import 'package:synced/utils/database_helper.dart';
import 'package:synced/utils/widgets.dart';

class VerificationCodePage extends StatefulWidget {
  const VerificationCodePage(
      {super.key,
      required this.email,
      required this.password,
      required this.source});

  final String email, password, source;

  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  bool showSpinner = false;
  bool showError = false;
  String errorMessage = '';
  final DatabaseHelper _db = DatabaseHelper();
  OtpTimerButtonController resendController = OtpTimerButtonController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Verify',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black)),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.1),
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/verification.png',
              ),
              const SizedBox(height: 25),
              const Text('Enter OTP',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                      fontSize: 24,
                      color: Colors.black,
                      fontWeight: FontWeight.w600)),
              Text('An 4 digit OTP has been sent to \n ${widget.email}',
                  style: TextStyle(color: headingColor, fontSize: 18)),
              showError
                  ? const SizedBox(height: 10)
                  : const SizedBox(height: 15),
              showError
                  ? showErrorWidget(errorMessage)
                  : const SizedBox(height: 0),
              showError
                  ? const SizedBox(height: 10)
                  : const SizedBox(height: 0),
              OtpTextField(
                fieldWidth: 70.0,
                fieldHeight: 70.0,
                borderWidth: 2,
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                numberOfFields: 4,
                borderColor: showError ? Colors.red : const Color(0xFFDFD8E5),
                showFieldAsBox: true,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ButtonStyle(
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
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
                  final resp = widget.source == 'auth'
                      ? await ApiService.verifyCode(0000, widget.email)
                      : await ApiService.verifyForgotPasswordCode(
                          0000, widget.email);
                  if (resp.isEmpty || resp['code'] != 200) {
                    setState(() {
                      showSpinner = false;
                      errorMessage = resp['reason'];
                      showError = true;
                    });
                    return;
                  }
                  if (widget.source == 'auth') {
                    await _db.deleteUsers();
                    User.email = widget.email;
                    User.password = widget.password;
                    User.name = resp['data']['name'];
                    User.authToken = resp['data']['token'];
                    _db.saveUser();
                  } else {}
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => widget.source == 'auth'
                              ? const HomeScreen()
                              : ChangePasswordPage(email: widget.email)));
                },
                child: const Text(
                  'Verify',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 5),
              Center(
                child: OtpTimerButton(
                  controller: resendController,
                  onPressed: () {
                    // TODO - Call resend verification code API
                  },
                  text: const Text('Resend OTP'),
                  duration: 60,
                  buttonType: ButtonType.text_button,
                  textColor: headingColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
