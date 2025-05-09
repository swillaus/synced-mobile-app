import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synced/main.dart';
import 'package:synced/models/user.dart';
import 'package:synced/utils/constants.dart';

class ApiService {
  static Future<Map> authenticateUser(email, password) async {
    bool result = await InternetConnectionChecker().hasConnection;
    if (!result) {
      return {'internet': false};
    }

    var headers = {
      'Content-Type': 'application/json',
    };
    var request = http.Request('POST', Uri.parse('$hostUrl/api/token'));
    request.body = json.encode(
        {"email": email, "password": password, "accountRemember": false});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      return jsonRes;
    } else {
      print('Login API - ${response.reasonPhrase}');
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
        'POST', Uri.parse('$hostUrl/api/Account/SyncedForgotPassword'));
    request.body = json.encode({"email": email, "id": ""});
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      return jsonRes;
    } else {
      print('Reset pass API - ${response.reasonPhrase}');
      return {};
    }
  }

  static Future<Map> changePassword(newPassword, email, context) async {
    Uri apiUrl = Uri.parse('$hostUrl/api/change-password');
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
        'GET', Uri.parse('$hostUrl/api/Organisation/OrganisationGet'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      return jsonRes;
    } else {
      print('GET Org API - ${response.reasonPhrase}');
      return {};
    }
  }

  static Future<Map> getExpenses(bool isProcessed, String orgId, String search,
      int page, int pageSize) async {
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
            '$hostUrl/api/Invoices/getInvoicesUploadedByUser?id=$orgId&isProcessed=$isProcessed&searchText=$search&page=$page&pageSize=$pageSize'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      return jsonRes;
    } else {
      print('GET Expenses API - ${response.reasonPhrase}');
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
            '$hostUrl/api/Invoices/downloadInvoice?id=$invoiceId&organisationId=$orgId'));

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
      print('Download invoice API - ${response.reasonPhrase}');
      return {};
    }
  }

  static Future<Map<String, dynamic>> uploadInvoice(
      String invoicePath, orgId, notes, onUploadProgress) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'en-GB,en-US;q=0.9,en;q=0.8',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };

    final mimeTypeData =
        lookupMimeType(invoicePath, headerBytes: [0xFF, 0xD8])?.split('/');

    FormData formData = FormData.fromMap({
      "invoice": await MultipartFile.fromFile(invoicePath,
          contentType: MediaType(mimeTypeData![0], mimeTypeData[1])),
      'organisationId': orgId,
      'recordId': '',
      'isBankTransMode': 'false',
    });

    final dio = Dio();

    Response response = await dio.request(
      '$hostUrl/api/Invoices/uploadInvoiceByMobileUpload?notes=$notes',
      data: formData,
      options: Options(method: 'POST', headers: headers),
      onSendProgress: (int sent, int total) {
        onUploadProgress(sent, total);
      },
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      print(
          'Upload invoice API - ${response.statusCode} ${response.statusMessage}');
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
            '$hostUrl/api/BankAccounts/getPaymentAccounts?organizationId=$orgId'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      return jsonRes;
    } else {
      print('GET payment accounts API - ${response.reasonPhrase}');
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
            '$hostUrl/api/Organisation/GetBankAccountDetails?organisationId=$orgId'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      return jsonRes;
    } else {
      print('GET bank accounts API - ${response.reasonPhrase}');
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
        'DELETE', Uri.parse('$hostUrl/api/Invoices/deleteInvoice?id=$id'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 204) {
      var jsonRes = {'message': 'Deleted successfully'};
      return jsonRes;
    } else {
      print('DELETE expense API - ${response.reasonPhrase}');
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
    var request =
        http.Request('PUT', Uri.parse('$hostUrl/api/Invoices/updateInvoice'));
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
            '$hostUrl/api/TaxRates/getTaxRates?id=$orgId&isSettings=false'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      return jsonRes;
    } else {
      print('GET Tax rates API - ${response.reasonPhrase}');
      return [];
    }
  }

  static Future<dynamic> publishReceipt(Map<String, dynamic> receipt) async {
    try {
        var headers = {
            'Accept': 'application/json, text/plain, */*',
            'Access-Control-Expose-Headers': 'authorization',
            'authorization': 'Bearer ${User.authToken}',
            'content-type': 'application/json',
        };

        var request = http.Request(
            'POST', 
            Uri.parse('$hostUrl/api/Invoices/publishReceipt')
        );
        
        request.body = jsonEncode(receipt);
        request.headers.addAll(headers);

        // Print the request body
        JsonEncoder encoder = new JsonEncoder.withIndent('  ');
        String prettyPrint = encoder.convert(jsonDecode(request.body));
        print('Request body: $prettyPrint');

        http.StreamedResponse response = await request.send();
        var responseBody = await response.stream.bytesToString();
        
        print('Server response code: ${response.statusCode}');
        print('Server response body: $responseBody');

        if (response.statusCode == 200) {
            // If response is a valid UUID string, return it directly
            if (responseBody.startsWith('"') && responseBody.endsWith('"')) {
                return responseBody.substring(1, responseBody.length - 1);
            }
            // Otherwise try to parse as JSON
            try {
                return jsonDecode(responseBody);
            } catch (e) {
                return responseBody;
            }
        } 

        // Parse error response
        try {
            var errorResponse = jsonDecode(responseBody);
            throw Exception(errorResponse['Message'] ?? 'Failed to publish receipt');
        } catch (e) {
            throw Exception('Failed to publish receipt: $responseBody');
        }

    } catch (e) {
        print('API error: $e');
        rethrow;
    }
  }

  static Future<List> getSuppliers(orgId) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };
    var request = http.Request('GET',
        Uri.parse('$hostUrl/api/Suppliers/getSuppliers?organizationId=$orgId'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      return jsonRes;
    } else {
      print('GET suppliers API - ${response.reasonPhrase}');
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
        'GET', Uri.parse('$hostUrl/api/Invoices/getInvoiceById?id=$id'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      print('SUCCESS CODE BY ID - ${jsonRes['paymentAccountName']}');
      return jsonRes;
    } else {
      print('Get invoice by id API - ${response.reasonPhrase}');
      return {};
    }
  }

  static Future<List> getOrgCurrencies(orgId) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };

    var request = http.Request(
        'GET',
        Uri.parse(
            '$hostUrl/api/Organisation/GetOrganizationCurrencies?organisationId=$orgId'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      return jsonRes;
    } else {
      print('GET org currencies API - ${response.reasonPhrase}');
      return [];
    }
  }

  static Future<Map> getReportsList(reportId, orgId) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };
    var request = http.Request(
        'POST', Uri.parse('$hostUrl/api/Reporting/GetUnreconciledReportList'));
    request.body = json.encode({
      "Account": "",
      "Source": "Report",
      "organizationId": orgId,
      "userid": User.userId,
      "reportId": reportId,
      "isSavedReport": true,
      "isSavedReportData": false,
      "isOutstandingReport": false,
      "startDate": "1900-01-01",
      "endDate": "2048-01-01",
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      return jsonRes;
    } else {
      print('GET transactions list API - ${response.reasonPhrase}');
      return {};
    }
  }

  static Future<List> getUnreconciledReports(orgId) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };
    var request = http.Request(
        'GET',
        Uri.parse(
            '$hostUrl/api/Reporting/getUnreconciledReportMatrics?organizationId=$orgId'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      return jsonRes;
    } else {
      print('GET reports list API - ${response.reasonPhrase}');
      return [];
    }
  }

  static Future<Map> getRelatedData(relatedId, orgId) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };
    var request = http.Request(
        'GET',
        Uri.parse(
            '$hostUrl/api/Invoices/getRelatedData?organizationId=$orgId&relatedId=$relatedId'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      if (jsonRes.isNotEmpty) {
        return jsonRes[0];
      } else {
        return {};
      }
    } else {
      print('GET related data API - ${response.reasonPhrase}');
      return {};
    }
  }

  static Future<Map> getMatchData(relatedId, orgId) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };
    var request = http.Request(
        'GET',
        Uri.parse(
            '$hostUrl/api/Invoices/getMatchData?organizationId=$orgId&relatedId=$relatedId'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      if (jsonRes.isNotEmpty) {
        return jsonRes[0];
      } else {
        return {};
      }
    } else {
      print('GET match data API - ${response.reasonPhrase}');
      return {};
    }
  }

  static Future<bool> updateSuggestedMatches(
      String unreconciledReportId, String invoiceId, String orgId) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };
    var request = http.Request(
        'POST', Uri.parse('$hostUrl/api/Invoices/UpdateSuggestedMatches'));
    request.body = json.encode({
      "unreconciledReportIds": unreconciledReportId,
      "invoiceId": invoiceId,
      "organizationId": orgId
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Update suggested match API - ${response.reasonPhrase}');
      return false;
    }
  }

  static Future<Map> getDefaultCurrency(String orgId) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };
    var request = http.Request(
        'GET',
        Uri.parse(
            '$hostUrl/api/Organisation/getOrganizationDefaultCurrency?id=$orgId'));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      return jsonRes;
    } else {
      print('GET transactions list API - ${response.reasonPhrase}');
      return {};
    }
  }

  static Future<Map> createSupplier(String supplierName) async {
    var headers = {
      'Accept': 'application/json, text/plain, */*',
      'Access-Control-Expose-Headers': 'authorization',
      'authorization': 'Bearer ${User.authToken}',
      'content-type': 'application/json',
    };
    var request = http.Request(
        'POST', Uri.parse('$hostUrl/api/Suppliers/createSupplier'));
    request.body = json.encode({
      "organizationId": selectedOrgId,
      "name": supplierName,
      "taxNumber": "",
      "groupId": "",
      "defaultAccount": {
        "id": "00000000-0000-0000-0000-000000000000",
        "name": "",
        "code": ""
      },
      "firstName": "",
      "lastName": "",
      "email": "",
      "currency": defaultCurrency,
      "accountName": "",
      "bsb": "",
      "accountNumber": "",
      "bankAccountRequestModel": null,
      "aliases": null,
      "hexColorClass": "sup_img_box_1",
      "accountsPayableTaxType": "",
      "accountsPayableTaxName": "",
      "routingNumber": "",
      "accountNumberUS": "",
      "IsSupplier": true,
      "OrganizationId": selectedOrgId
    });
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      var res = await response.stream.bytesToString();
      var jsonRes = jsonDecode(res);
      return jsonRes;
    } else {
      print('POST create supplier API - ${response.reasonPhrase}');
      return {};
    }
  }
}
