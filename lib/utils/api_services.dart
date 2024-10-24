import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synced/models/user.dart';
import 'package:synced/utils/constants.dart';

String baseUrl = '$hostUrl/';

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

      final streamData = await response.stream.toBytes();

      File file = File('$tempPath/$invoiceId');
      await file.writeAsBytes(streamData);

      final mimeType = lookupMimeType(file.path, headerBytes: streamData);
      File fileWithExt =
          File('$tempPath/$invoiceId.${mimeType?.split('/')[1]}');
      await fileWithExt.writeAsBytes(streamData);
      return {'path': fileWithExt.path};
    } else {
      print(response.reasonPhrase);
      return {};
    }
  }

  static Future<Map<String, dynamic>> uploadInvoice(
      String invoicePath, orgId, notes) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'en-GB,en-US;q=0.9,en;q=0.8',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };

    final mimeTypeData =
        lookupMimeType(invoicePath, headerBytes: [0xFF, 0xD8])?.split('/');

    var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://syncedtestingapi.azurewebsites.net/api/Invoices/uploadInvoiceByMobileUpload?notes=$notes'));
    request.fields.addAll({
      'organisationId': orgId,
      'recordId': '',
      'isBankTransMode': 'false',
    });
    request.files.add(await http.MultipartFile.fromPath('invoice', invoicePath,
        contentType: MediaType(mimeTypeData![0], mimeTypeData[1])));
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

  static Future<List> getPaymentAccounts(String orgId) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Access-Control-Expose-Headers': 'authorization',
      'Connection': 'keep-alive',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };
    var request = http.Request(
        'GET',
        Uri.parse(
            'https://syncedtestingapi.azurewebsites.net/api/BankAccounts/getPaymentAccounts?organizationId=$orgId'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      print(res);
      return jsonRes;
    } else {
      print(response.reasonPhrase);
      return [];
    }
  }

  static Future<Map> getBankDetails(String orgId) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Access-Control-Expose-Headers': 'authorization',
      'Connection': 'keep-alive',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };
    var request = http.Request(
        'GET',
        Uri.parse(
            'https://syncedtestingapi.azurewebsites.net/api/Organisation/GetBankAccountDetails?organisationId=$orgId'));

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

  static Future<Map> deleteExpense(id) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };
    var request = http.Request(
        'DELETE',
        Uri.parse(
            'https://syncedtestingapi.azurewebsites.net/api/Invoices/deleteInvoice?id=$id'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 204) {
      var jsonRes = {'message': 'Deleted successfully'};
      print(jsonRes.toString());
      return jsonRes;
    } else {
      print(response.reasonPhrase);
      return {};
    }
  }

  static Future<Map> updateExpense(Map expense) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };
    var request = http.Request(
        'PUT',
        Uri.parse(
            'https://syncedtestingapi.azurewebsites.net/api/Invoices/updateInvoice'));
    request.body = json.encode(expense);
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      return {'message': 'Expense updated successfully'};
    } else {
      print('Error - ${response.statusCode}');
      return {};
    }
  }

  static Future<List> getTaxRates(orgId) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };
    var request = http.Request(
        'GET',
        Uri.parse(
            'https://syncedtestingapi.azurewebsites.net/api/TaxRates/getTaxRates?id=$orgId&isSettings=false'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      print(res);
      return jsonRes;
    } else {
      print(response.reasonPhrase);
      return [];
    }
  }

  static Future<Map> publishReceipt(receipt) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };
    var request = http.Request(
        'POST',
        Uri.parse(
            'https://syncedtestingapi.azurewebsites.net/api/Invoices/PublishReceipt'));
    request.body = json.encode(receipt);
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      return {'message': 'Expense published successfully'};
    } else {
      print('Error - ${response.statusCode}');
      return {};
    }
  }

  static Future<List> getSuppliers(orgId) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };
    var request = http.Request(
        'GET',
        Uri.parse(
            'https://syncedtestingapi.azurewebsites.net/api/Suppliers/getSuppliers?organizationId=$orgId'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      print(res);
      return jsonRes;
    } else {
      print(response.reasonPhrase);
      return [];
    }
  }

  static Future<Map> getInvoiceById(id) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };
    var request = http.Request(
        'GET',
        Uri.parse(
            'https://syncedtestingapi.azurewebsites.net/api/Invoices/getInvoiceById?id=$id'));

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
}
