import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:synced/models/user.dart';
import 'package:synced/utils/constants.dart';

import 'database_helper.dart';

String baseUrl = '$hostUrl/';
var _db = DatabaseHelper();

class ApiService {
  static Future<Map> userSignup(email, password) async {
    Uri apiUrl = Uri.parse('${baseUrl}api/signup');
    Map data = {
      'email': email,
      'password': password,
    };

    bool result = await InternetConnectionChecker().hasConnection;
    if (!result) {
      return {'internet': false};
    }

    var responseData = {};
    var response = await http.post(apiUrl,
        headers: {HttpHeaders.acceptHeader: 'application/json'}, body: data);
    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      if (responseData['code'] == 200 || responseData['code'] == "200") {
        return responseData;
      } else {
        print('Something went wrong while authenticating user');
        print(responseData['reason']);
        return responseData;
      }
    }
    return responseData;
  }

  static Future<Map> authenticateUser(email, password) async {
    bool result = await InternetConnectionChecker().hasConnection;
    if (!result) {
      return {'internet': false};
    }

    var headers = {
      'Content-Type': 'application/json',
    };
    var request = http.Request('POST',
        Uri.parse('https://syncedtestingapi.azurewebsites.net/api/token'));
    request.body = json.encode(
        {"email": email, "password": password, "accountRemember": false});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    var responseData;
    if (response.statusCode == 200) {
      responseData = await response.stream.bytesToString();
      responseData = jsonDecode(responseData);
      if (responseData['code'] == 200 || responseData['code'] == "200") {
        return responseData;
      } else {
        print('Something went wrong while authenticating user');
        print(responseData['reason']);
        return responseData;
      }
    } else {
      print(response.reasonPhrase);
      return {};
    }
  }

  static Future<Map> verifyCode(code, email) async {
    Uri apiUrl = Uri.parse('${baseUrl}api/verify');
    Map data = {'otp': code, 'email': email};

    bool result = await InternetConnectionChecker().hasConnection;
    if (!result) {
      return {'internet': false};
    }

    var responseData = {};
    try {
      var response = await http.post(apiUrl, body: data);
      if (response.statusCode == 200) {
        responseData = json.decode(response.body);
        if (responseData['code'] == 200 || responseData['code'] == "200") {
          return responseData;
        } else {
          print('Something went wrong while authenticating user');
          print(responseData['reason']);
          return responseData;
        }
      }
      return {};
    } catch (exc) {
      return {};
    }
  }

  static Future<Map> resendCode(email, source) async {
    Uri apiUrl = Uri.parse('${baseUrl}api/resend-otp');
    Map data = {'email': email, 'source': source};

    bool result = await InternetConnectionChecker().hasConnection;
    if (!result) {
      return {'internet': false};
    }

    var responseData = {};
    try {
      var response = await http.post(apiUrl, body: data);
      if (response.statusCode == 200) {
        responseData = json.decode(response.body);
        if (responseData['code'] == 200 || responseData['code'] == "200") {
          return responseData;
        } else {
          print('Something went wrong while authenticating user');
          print(responseData['reason']);
          return responseData;
        }
      }
      return {};
    } catch (exc) {
      return {};
    }
  }

  static Future<Map> verifyForgotPasswordCode(code, email) async {
    Uri apiUrl = Uri.parse('${baseUrl}api/forgot-password/verify');
    Map data = {'otp': code, 'email': email};

    bool result = await InternetConnectionChecker().hasConnection;
    if (!result) {
      return {'internet': false};
    }

    var responseData = {};
    try {
      var response = await http.post(apiUrl, body: data);
      if (response.statusCode == 200) {
        responseData = json.decode(response.body);
        if (responseData['code'] == 200 || responseData['code'] == "200") {
          return responseData;
        } else {
          print('Something went wrong while authenticating user');
          print(responseData['reason']);
          return responseData;
        }
      }
      return {};
    } catch (exc) {
      return {};
    }
  }

  static Future<Map> resetPassword(email) async {
    Uri apiUrl = Uri.parse('${baseUrl}api/forgot-password');
    var responseData = {};

    bool result = await InternetConnectionChecker().hasConnection;
    if (!result) {
      return {'internet': false};
    }

    var response = await http.post(apiUrl, body: {"email": email});

    if (response.statusCode == 200) {
      responseData = json.decode(response.body);
      if (responseData['code'] == 200 || responseData['code'] == "200") {
        return responseData;
      } else {
        print('Something went wrong while authenticating user');
        print(responseData['reason']);
        return responseData;
      }
    }
    return {};
  }

  static Future<Map<Object, dynamic>> getProfile(context) async {
    Uri apiUrl = Uri.parse('${baseUrl}api/profile');

    bool result = await InternetConnectionChecker().hasConnection;
    if (!result) {
      return {'internet': false};
    }

    try {
      var response = await http.get(apiUrl, headers: {
        "Authorization": "Token ${User.authToken}",
      });

      if ((response.statusCode == 401 || response.statusCode == 403)) {
        await _db.deleteUsers();
        Navigator.of(context).pushNamed('/login');
      }
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print(e);
      return {};
    }
  }

  static Future<Map> changePassword(newPassword, email, context) async {
    Uri apiUrl = Uri.parse('${baseUrl}api/change-password');
    var responseData = {};

    bool result = await InternetConnectionChecker().hasConnection;
    if (!result) {
      return {'internet': false};
    }

    var response = await http.post(apiUrl, headers: {
      HttpHeaders.authorizationHeader: "Token ${User.authToken}",
    }, body: {
      "new_password": newPassword,
      "email": email
    });

    if (response.statusCode == 200) {
      responseData = json.decode(response.body);
      if (responseData['code'] == 200 || responseData['code'] == "200") {
        return responseData;
      } else {
        print('Something went wrong while authenticating user');
        print(responseData['reason']);
        return responseData;
      }
    }
    return {};
  }

  static Future<Map> updateProfile(
      phone,
      street,
      addLine2,
      city,
      state,
      zipCode,
      height,
      weight,
      gender,
      fitnessGoal,
      fitnessLevel,
      context) async {
    Uri apiUrl = Uri.parse('${baseUrl}api/profile');
    var responseData = {};

    bool result = await InternetConnectionChecker().hasConnection;
    if (!result) {
      return {'internet': false};
    }

    var response = await http.put(apiUrl, headers: {
      HttpHeaders.authorizationHeader: "Token ${User.authToken}",
    }, body: {
      "phone": phone,
      "street": street,
      "address_line_2": addLine2,
      "city": city,
      "state": state,
      "zip_code": zipCode,
      "height": height,
      "weight": weight,
      "gender": gender,
      "fitness_goal": fitnessGoal,
      "fitness_level": fitnessLevel
    });

    if (response.statusCode == 200) {
      responseData = json.decode(response.body);
      if (responseData['code'] == 200 || responseData['code'] == "200") {
        return responseData;
      } else {
        print('Something went wrong while authenticating user');
        print(responseData['reason']);
        return responseData;
      }
    }
    return {};
  }

  static Future<Map> logout() async {
    Uri apiUrl = Uri.parse('${baseUrl}api/logout');

    bool result = await InternetConnectionChecker().hasConnection;
    if (!result) {
      return {'internet': false};
    }

    var responseData = {};
    try {
      var response = await http.post(apiUrl, headers: {
        HttpHeaders.authorizationHeader: "Token ${User.authToken}",
      });
      if (response.statusCode == 200) {
        responseData = json.decode(response.body);
        if (responseData['code'] == 200 || responseData['code'] == "200") {
          return responseData;
        } else {
          print('Something went wrong while authenticating user');
          print(responseData['reason']);
          return responseData;
        }
      }
      return {};
    } catch (exc) {
      return {};
    }
  }

  static Future<Map<Object, dynamic>> getRoutines(context) async {
    Uri apiUrl = Uri.parse('${baseUrl}api/routine');

    bool result = await InternetConnectionChecker().hasConnection;
    if (!result) {
      return {'internet': false};
    }

    try {
      var response = await http.get(apiUrl, headers: {
        "Authorization": "Token ${User.authToken}",
      });

      if ((response.statusCode == 401 || response.statusCode == 403)) {
        await _db.deleteUsers();
        Navigator.of(context).pushNamed('/login');
      }
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print(e);
      return {};
    }
  }
}
