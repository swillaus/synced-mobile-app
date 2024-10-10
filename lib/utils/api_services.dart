import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synced/models/user.dart';
import 'package:synced/utils/constants.dart';

import 'database_helper.dart';

String baseUrl = '$hostUrl/';
var _db = DatabaseHelper();

class ApiService {
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

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      print(res);
      return jsonRes;
    } else {
      print(response.reasonPhrase);
      return {};
    }
  }

  static Future<Map> resetPassword(email) async {
    bool result = await InternetConnectionChecker().hasConnection;
    if (!result) {
      return {'internet': false};
    }

    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'content-type': 'application/json',
    };
    var request = http.Request(
        'POST',
        Uri.parse(
            'https://syncedtestingapi.azurewebsites.net/api/Account/SyncedForgotPassword'));
    request.body = json.encode({"email": email, "id": ""});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      print(res);
      return jsonRes;
    } else {
      print(response.reasonPhrase);
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

  static Future<Map> getOrganisations() async {
    bool result = await InternetConnectionChecker().hasConnection;
    if (!result) {
      return {'internet': false};
    }

    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'en-GB,en-US;q=0.9,en;q=0.8',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };
    var request = http.Request(
        'GET',
        Uri.parse(
            'https://syncedtestingapi.azurewebsites.net/api/Organisation/OrganisationGet'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      print(res);
      return jsonRes;
    } else {
      print(response.reasonPhrase);
      return {};
    }
  }

  static Future<Map> getExpenses(
      bool isProcessed, String orgId, String search) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'en-GB,en-US;q=0.9,en;q=0.8',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };
    var request = http.Request(
        'GET',
        Uri.parse(
            'https://syncedtestingapi.azurewebsites.net/api/Invoices/getInvoicesUploadedByUser?id=$orgId&isProcessed=$isProcessed&page=1&pageSize=1000&searchText=$search'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      print(res);
      return jsonRes;
    } else {
      print(response.reasonPhrase);
      return {};
    }
  }

  static downloadInvoice(invoiceId, orgId) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'en-GB,en-US;q=0.9,en;q=0.8',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };
    var request = http.Request(
        'GET',
        Uri.parse(
            'https://syncedtestingapi.azurewebsites.net/api/Invoices/downloadInvoice?id=$invoiceId&organisationId=$orgId'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;
      File file = File('$tempPath/$invoiceId.pdf');
      await file.writeAsBytes(await response.stream.toBytes());
      return {'path': file.path};
    } else {
      print(response.reasonPhrase);
      return {};
    }
  }
}
