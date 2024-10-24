import 'dart:convert';
import 'dart:io';

import 'package:currency_picker/currency_picker.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:pdf_render/pdf_render_widgets.dart';
import 'package:synced/main.dart';
import 'package:synced/screens/home/home_screen.dart';
import 'package:synced/utils/api_services.dart';
import 'package:synced/utils/constants.dart';

class UpdateExpenseData extends StatefulWidget {
  final Map expense;
  final String? imagePath;
  const UpdateExpenseData(
      {super.key, required this.expense, required this.imagePath});

  @override
  State<UpdateExpenseData> createState() => _UpdateExpenseDataState();
}

class _UpdateExpenseDataState extends State<UpdateExpenseData> {
  TextEditingController supplierController = TextEditingController();
  TextEditingController refController = TextEditingController();
  TextEditingController totalController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController currencyController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  Map updatedExpense = {};
  DateTime? selectedDate;
  String? selectedCurrency;
  Map? selectedAccount;
  Map? selectedCard;
  Map<String, dynamic>? selectedTaxRate;
  List paymentAccounts = [];
  List bankDetails = [];
  List taxRates = [];
  List suppliers = [];
  Map expense = {};
  bool showSpinner = false;

  @override
  void initState() {
    preparePage();
    super.initState();
  }

  Future<void> preparePage() async {
    setState(() {
      showSpinner = true;
    });
    await getInvoiceById();
    await getPaymentAccounts();
    await getBankDetails();
    await getTaxRates();
    await getSuppliers();
    setState(() {
      updatedExpense = expense;
      updatedExpense.remove('invoice_path');
      supplierController.text = expense['supplierName'] ?? '';
      selectedDate = DateTime.parse(expense['date']);
      dateController.text =
          DateFormat('dd MMM, yyyy').format(DateTime.parse(expense['date']));
      refController.text = expense['invoiceNumber'] ?? '';
      selectedCurrency = expense['currency'] != null &&
              expense['currency'].runtimeType == String
          ? expense['currency']
          : 'USD';
      currencyController.text = expense['currency'] != null &&
              expense['currency'].runtimeType == String
          ? expense['currency']
          : 'USD';
      totalController.text = expense['subTotal'].toString();
      descriptionController.text = expense['description'] ?? '';
    });
  }

  Future<void> getInvoiceById() async {
    final resp = await ApiService.getInvoiceById(widget.expense['id']);
    expense = resp;
  }

  Future<void> getPaymentAccounts() async {
    final resp = await ApiService.getPaymentAccounts(selectedOrgId);
    paymentAccounts = resp;
    for (var acc in paymentAccounts) {
      if (acc['id'] == expense['invoiceLines'][0]['accountId']) {
        selectedAccount = acc;
      }
    }
  }

  Future<void> getBankDetails() async {
    final resp = await ApiService.getBankDetails(selectedOrgId);
    if (resp.isNotEmpty && resp['status'] == 0) {
      bankDetails = resp['data'];
      for (var bankDetail in bankDetails) {
        if (expense['paymentAccountNumber'] == bankDetail['accountID']) {
          selectedCard = bankDetail;
        }
      }
    }
  }

  Future<void> getTaxRates() async {
    final resp = await ApiService.getTaxRates(selectedOrgId);
    if (resp.isNotEmpty) {
      taxRates = resp;
      for (var tax in taxRates) {
        if (tax['id'] == expense['invoiceLines'][0]['taxId']) {
          selectedTaxRate = tax;
        }
      }
    }
  }

  Future<void> getSuppliers() async {
    final resp = await ApiService.getSuppliers(selectedOrgId);
    if (resp.isNotEmpty) {
      suppliers = resp;
    }
    setState(() {
      showSpinner = false;
    });
  }

  List<DropdownMenuItem> getPaymentAccountDropdownItems() {
    List<DropdownMenuItem> accounts = [];
    for (var acc in paymentAccounts) {
      accounts.add(DropdownMenuItem(value: acc, child: Text(acc['name'])));
    }
    return accounts;
  }

  List<DropdownMenuItem> getBankDetailsDropdownItems() {
    List<DropdownMenuItem> accounts = [];
    for (var bankDetail in bankDetails) {
      accounts.add(
          DropdownMenuItem(value: bankDetail, child: Text(bankDetail['name'])));
    }
    return accounts;
  }

  List<DropdownMenuItem> getTaxRateDropdownItems() {
    List<DropdownMenuItem> rates = [];
    for (var tax in taxRates) {
      rates.add(DropdownMenuItem(value: tax, child: Text(tax['name'])));
    }
    return rates;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            scrolledUnderElevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
                onPressed: () {
                  Navigator.push(
                      navigatorKey.currentContext!,
                      MaterialPageRoute(
                          builder: (context) =>
                              const HomeScreen(pageIndex: 0)));
                },
                icon: const Icon(Icons.arrow_back_ios)),
            bottom: PreferredSize(
              preferredSize: const Size(200, 200),
              child: widget.imagePath != null &&
                      widget.imagePath!
                              .substring(widget.imagePath!.length - 3) ==
                          'pdf'
                  ? SizedBox(
                      height: 200,
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: PdfViewer.openFile(widget.imagePath!),
                    )
                  : widget.imagePath != null
                      ? Image.file(File(widget.imagePath!),
                          height: 200,
                          width: MediaQuery.of(context).size.width * 0.85)
                      : Container(
                          height: 200,
                        ),
            ),
          ),
          body: ModalProgressHUD(
              progressIndicator: CircularProgressIndicator(
                color: clickableColor,
              ),
              inAsyncCall: showSpinner,
              child: Container(
                padding: const EdgeInsets.all(25),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15),
                      Text('Supplier',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: headingColor)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: supplierController,
                        decoration: InputDecoration(
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
                        ),
                        onEditingComplete: () async {
                          updatedExpense['supplierName'] =
                              supplierController.text;
                          FocusManager.instance.primaryFocus?.unfocus();
                          final resp =
                              await ApiService.updateExpense(updatedExpense);
                          setState(() {
                            showSpinner = false;
                          });
                          if (resp.isNotEmpty) {
                            ScaffoldMessenger.of(navigatorKey.currentContext!)
                                .showSnackBar(const SnackBar(
                                    content: Text('Updated successfully.')));
                          } else {
                            ScaffoldMessenger.of(navigatorKey.currentContext!)
                                .showSnackBar(const SnackBar(
                                    content: Text('Failed to update.')));
                          }
                        },
                        maxLines: 1,
                      ),
                      const SizedBox(height: 15),
                      Text('Date',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: headingColor)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: dateController,
                        decoration: InputDecoration(
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
                        ),
                        maxLines: 1,
                        onEditingComplete: () async {
                          updatedExpense['date'] =
                              '${selectedDate?.year}-${selectedDate?.month}-${selectedDate?.day}';
                          FocusManager.instance.primaryFocus?.unfocus();
                          final resp =
                              await ApiService.updateExpense(updatedExpense);
                          setState(() {
                            showSpinner = false;
                          });
                          if (resp.isNotEmpty) {
                            ScaffoldMessenger.of(navigatorKey.currentContext!)
                                .showSnackBar(const SnackBar(
                                    content: Text('Updated successfully.')));
                          } else {
                            ScaffoldMessenger.of(navigatorKey.currentContext!)
                                .showSnackBar(const SnackBar(
                                    content: Text('Failed to update.')));
                          }
                        },
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (context) => Container(
                                    height: double.maxFinite,
                                    width: double.maxFinite,
                                    color: Colors.white,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.6,
                                          width: double.maxFinite,
                                          child: CupertinoDatePicker(
                                            mode: CupertinoDatePickerMode.date,
                                            onDateTimeChanged:
                                                (DateTime newDate) {
                                              setState(() {
                                                selectedDate = newDate;
                                                dateController.text =
                                                    DateFormat('dd MMM, yyyy')
                                                        .format(newDate);
                                              });
                                            },
                                            initialDateTime: selectedDate,
                                            maximumDate: DateTime.now(),
                                            dateOrder: DatePickerDateOrder.dmy,
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text('Select',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: headingColor))),
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text('Cancel',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: headingColor)))
                                          ],
                                        )
                                      ],
                                    ),
                                  ));
                        },
                      ),
                      const SizedBox(height: 15),
                      Text('Currency',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: headingColor)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: currencyController,
                        decoration: InputDecoration(
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
                        ),
                        maxLines: 1,
                        onEditingComplete: () async {
                          updatedExpense['currency'] = currencyController.text;
                          FocusManager.instance.primaryFocus?.unfocus();
                          final resp =
                              await ApiService.updateExpense(updatedExpense);
                          setState(() {
                            showSpinner = false;
                          });
                          if (resp.isNotEmpty) {
                            ScaffoldMessenger.of(navigatorKey.currentContext!)
                                .showSnackBar(const SnackBar(
                                    content: Text('Updated successfully.')));
                          } else {
                            ScaffoldMessenger.of(navigatorKey.currentContext!)
                                .showSnackBar(const SnackBar(
                                    content: Text('Failed to update.')));
                          }
                        },
                        onTap: () {
                          showCurrencyPicker(
                            context: context,
                            showFlag: true,
                            showCurrencyName: true,
                            showCurrencyCode: true,
                            onSelect: (Currency currency) {
                              setState(() {
                                selectedCurrency = currency.code;
                                currencyController.text = currency.code;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      Text('Ref',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: headingColor)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: refController,
                        decoration: InputDecoration(
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
                        ),
                        maxLines: 1,
                        onEditingComplete: () async {
                          updatedExpense['invoiceNumber'] = refController.text;
                          FocusManager.instance.primaryFocus?.unfocus();
                          final resp =
                              await ApiService.updateExpense(updatedExpense);
                          setState(() {
                            showSpinner = false;
                          });
                          if (resp.isNotEmpty) {
                            ScaffoldMessenger.of(navigatorKey.currentContext!)
                                .showSnackBar(const SnackBar(
                                    content: Text('Updated successfully.')));
                          } else {
                            ScaffoldMessenger.of(navigatorKey.currentContext!)
                                .showSnackBar(const SnackBar(
                                    content: Text('Failed to update.')));
                          }
                        },
                      ),
                      const SizedBox(height: 15),
                      Text('Account',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: headingColor)),
                      const SizedBox(height: 10),
                      DropdownButtonHideUnderline(
                          child: DropdownButton2(
                        isExpanded: true,
                        items: getPaymentAccountDropdownItems(),
                        value: selectedAccount,
                        onChanged: (value) async {
                          setState(() {
                            selectedAccount = value;
                            showSpinner = true;
                          });
                          updatedExpense['invoiceLines'][0]['accountId'] =
                              selectedAccount?['id'];
                          final resp =
                              await ApiService.updateExpense(updatedExpense);
                          setState(() {
                            showSpinner = false;
                          });
                          if (resp.isNotEmpty) {
                            ScaffoldMessenger.of(navigatorKey.currentContext!)
                                .showSnackBar(const SnackBar(
                                    content: Text('Updated successfully.')));
                          } else {
                            ScaffoldMessenger.of(navigatorKey.currentContext!)
                                .showSnackBar(const SnackBar(
                                    content: Text('Failed to update.')));
                          }
                        },
                        buttonStyleData: ButtonStyleData(
                          height: 55,
                          padding: const EdgeInsets.only(left: 14, right: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              strokeAlign: 0,
                              color: Colors.black26,
                            ),
                          ),
                        ),
                        dropdownStyleData: const DropdownStyleData(
                            decoration: BoxDecoration(color: Colors.white)),
                      )),
                      const SizedBox(height: 15),
                      Text('Total',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: headingColor)),
                      const SizedBox(height: 10),
                      TextField(
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        controller: totalController,
                        decoration: InputDecoration(
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
                        ),
                        onEditingComplete: () async {
                          setState(() {
                            showSpinner = true;
                          });
                          // call updateInvoice API with new tax data
                          updatedExpense['invoiceLines'][0]['subTotal'] =
                              double.parse(totalController.text);
                          updatedExpense['subTotal'] =
                              double.parse(totalController.text);
                          FocusManager.instance.primaryFocus?.unfocus();
                          final resp =
                              await ApiService.updateExpense(updatedExpense);
                          setState(() {
                            showSpinner = false;
                          });
                          if (resp.isNotEmpty) {
                            ScaffoldMessenger.of(navigatorKey.currentContext!)
                                .showSnackBar(const SnackBar(
                                    content: Text('Updated successfully.')));
                          } else {
                            ScaffoldMessenger.of(navigatorKey.currentContext!)
                                .showSnackBar(const SnackBar(
                                    content: Text('Failed to update.')));
                          }
                        },
                        maxLines: 1,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                            side: const BorderSide(
                              color: Color(0XFF009318),
                            ),
                            backgroundColor: const Color(0XFFF2FFF5),
                            label: Text(
                                'Total tax includes: ${expense['currency'].runtimeType == String ? NumberFormat().simpleCurrencySymbol(expense['currency']) : ''}${expense['totalTax']}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0XFF009318))),
                          ),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                  context: navigatorKey.currentContext!,
                                  builder: (context) => AlertDialog(
                                        insetPadding: const EdgeInsets.all(10),
                                        backgroundColor: Colors.white,
                                        title: Container(
                                          height: 50,
                                          color: const Color(0XFFF9FAFB),
                                          child: Text('Tax Amount',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: headingColor)),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.all(10),
                                        content: StatefulBuilder(
                                            builder:
                                                (context, setState) =>
                                                    Container(
                                                      color: Colors.white,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.3,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.95,
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          DropdownButtonHideUnderline(
                                                              child:
                                                                  DropdownButton2(
                                                            isExpanded: true,
                                                            value:
                                                                selectedTaxRate,
                                                            items:
                                                                getTaxRateDropdownItems(),
                                                            onChanged: (value) {
                                                              setState(() {
                                                                selectedTaxRate =
                                                                    value;
                                                              });
                                                            },
                                                            buttonStyleData:
                                                                ButtonStyleData(
                                                              height: 55,
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      left: 14,
                                                                      right:
                                                                          14),
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            14),
                                                                border:
                                                                    Border.all(
                                                                  strokeAlign:
                                                                      0,
                                                                  color: Colors
                                                                      .black26,
                                                                ),
                                                              ),
                                                            ),
                                                            dropdownStyleData:
                                                                const DropdownStyleData(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                            color:
                                                                                Colors.white)),
                                                          )),
                                                          const SizedBox(
                                                              height: 30),
                                                          Center(
                                                            child:
                                                                ElevatedButton(
                                                                    style: ButtonStyle(
                                                                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                                                                            borderRadius: BorderRadius.circular(
                                                                                12.0))),
                                                                        fixedSize: WidgetStateProperty.all(Size(
                                                                            MediaQuery.of(context)
                                                                                .size
                                                                                .width,
                                                                            MediaQuery.of(context).size.height *
                                                                                0.06)),
                                                                        backgroundColor:
                                                                            WidgetStateProperty.all(const Color(
                                                                                0XFF009318))),
                                                                    onPressed:
                                                                        () async {
                                                                      setState(
                                                                          () {
                                                                        showSpinner =
                                                                            true;
                                                                      });
                                                                      // call updateInvoice API with new tax data
                                                                      updatedExpense['invoiceLines'][0]
                                                                              [
                                                                              'taxId'] =
                                                                          selectedTaxRate?[
                                                                              'id'];
                                                                      double totalAmount = updatedExpense[
                                                                              'subtotal'] +
                                                                          updatedExpense['subtotal'] *
                                                                              selectedTaxRate?['rate'] /
                                                                              100;
                                                                      double
                                                                          totalTax =
                                                                          updatedExpense['subtotal'] *
                                                                              selectedTaxRate?['rate'] /
                                                                              100;
                                                                      updatedExpense['invoiceLines'][0]
                                                                              [
                                                                              'totalTax'] =
                                                                          totalTax;
                                                                      updatedExpense[
                                                                              'amountDue'] =
                                                                          totalAmount;
                                                                      final resp =
                                                                          await ApiService.updateExpense(
                                                                              updatedExpense);
                                                                      setState(
                                                                          () {
                                                                        showSpinner =
                                                                            false;
                                                                      });
                                                                      Navigator.pop(
                                                                          context);
                                                                      if (resp
                                                                          .isNotEmpty) {
                                                                        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(const SnackBar(
                                                                            content:
                                                                                Text('Updated successfully.')));
                                                                      } else {
                                                                        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(const SnackBar(
                                                                            content:
                                                                                Text('Failed to update.')));
                                                                      }
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                      'Save',
                                                                      style: TextStyle(
                                                                          fontWeight: FontWeight
                                                                              .w600,
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              Colors.white),
                                                                    )),
                                                          ),
                                                          TextButton(
                                                              onPressed:
                                                                  () async {
                                                                Navigator.pop(
                                                                    navigatorKey
                                                                        .currentContext!);
                                                              },
                                                              child: const Text(
                                                                  'Discard',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      color: Color(
                                                                          0XFFFF4E4E))))
                                                        ],
                                                      ),
                                                    )),
                                      ));
                            },
                            child: const Chip(
                                shape: CircleBorder(
                                    side: BorderSide(
                                  color: Color(0XFF009318),
                                )),
                                backgroundColor: Color(0XFFF2FFF5),
                                label: Icon(
                                  Icons.edit_outlined,
                                  color: Color(0XFF009318),
                                  size: 22,
                                )),
                          )
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text('Description',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: headingColor)),
                      const SizedBox(height: 10),
                      TextField(
                        textInputAction: TextInputAction.done,
                        controller: descriptionController,
                        decoration: InputDecoration(
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
                        ),
                        maxLines: 3,
                        onEditingComplete: () async {
                          updatedExpense['description'] =
                              descriptionController.text;
                          updatedExpense['invoiceLines'][0]['description'] =
                              descriptionController.text;
                          FocusManager.instance.primaryFocus?.unfocus();
                          final resp =
                              await ApiService.updateExpense(updatedExpense);
                          setState(() {
                            showSpinner = false;
                          });
                          if (resp.isNotEmpty) {
                            ScaffoldMessenger.of(navigatorKey.currentContext!)
                                .showSnackBar(const SnackBar(
                                    content: Text('Updated successfully.')));
                          } else {
                            ScaffoldMessenger.of(navigatorKey.currentContext!)
                                .showSnackBar(const SnackBar(
                                    content: Text('Failed to update.')));
                          }
                        },
                      ),
                      const SizedBox(height: 15),
                      Text('Paid From',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: headingColor)),
                      const SizedBox(height: 10),
                      DropdownButtonHideUnderline(
                          child: DropdownButton2(
                        isExpanded: true,
                        value: selectedCard,
                        items: getBankDetailsDropdownItems(),
                        onChanged: (value) async {
                          setState(() {
                            selectedCard = value;
                            showSpinner = true;
                          });
                          // call updateInvoice API with new tax data
                          updatedExpense['paymentAccountNumber'] =
                              selectedCard?['accountID'];
                          final resp =
                              await ApiService.updateExpense(updatedExpense);
                          setState(() {
                            showSpinner = false;
                          });
                          if (resp.isNotEmpty) {
                            ScaffoldMessenger.of(navigatorKey.currentContext!)
                                .showSnackBar(const SnackBar(
                                    content: Text('Updated successfully.')));
                          } else {
                            ScaffoldMessenger.of(navigatorKey.currentContext!)
                                .showSnackBar(const SnackBar(
                                    content: Text('Failed to update.')));
                          }
                        },
                        buttonStyleData: ButtonStyleData(
                          height: 55,
                          padding: const EdgeInsets.only(left: 14, right: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              strokeAlign: 0,
                              color: Colors.black26,
                            ),
                          ),
                        ),
                        dropdownStyleData: const DropdownStyleData(
                            decoration: BoxDecoration(color: Colors.white)),
                      )),
                      const SizedBox(height: 15),
                      Center(
                        child: ElevatedButton(
                            style: ButtonStyle(
                                shape: WidgetStateProperty.all<
                                        RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0))),
                                fixedSize: WidgetStateProperty.all(Size(
                                    MediaQuery.of(context).size.width,
                                    MediaQuery.of(context).size.height * 0.06)),
                                backgroundColor: WidgetStateProperty.all(
                                    const Color(0XFF009318))),
                            onPressed: () async {
                              setState(() {
                                showSpinner = true;
                              });
                              Map contact = {};
                              for (var supplier in suppliers) {
                                if (supplier['name'] ==
                                    supplierController.text) {
                                  contact = {
                                    "contactID": supplier['id'],
                                    "name": supplier['name'],
                                    "status": "ACTIVE"
                                  };
                                }
                              }
                              List lineItems = updatedExpense['invoiceLines'];
                              for (var item in lineItems) {
                                item.addAll({'organisationId': selectedOrgId});
                              }
                              Map receipt = {
                                "bankAccount": {
                                  "accountID": selectedCard?['accountID'],
                                  "bankAccountNumber":
                                      selectedCard?['bankAccountNumber'],
                                  "currencyCode": selectedCurrency,
                                  "name": selectedCard?['name'],
                                  "type": selectedCard?['type']
                                },
                                'currency': selectedCurrency,
                                'currencyCode': selectedCurrency,
                                'contact': contact,
                                'date': updatedExpense['date'],
                                'invoiceId': updatedExpense['id'],
                                'invoiceNumber':
                                    updatedExpense['invoiceNumber'],
                                "InvoiceOrCreditNote": updatedExpense['type'],
                                'lineAmountTypes': 'Exclusive',
                                'lineItems': lineItems,
                                'OrganisationId': selectedOrgId,
                                'paymentAccountNumber':
                                    updatedExpense['paymentAccountNumber'],
                                'paymentDate': updatedExpense['paymentDate'],
                                'paymentStatus':
                                    updatedExpense['type'] == 'Receipt' ? 1 : 0,
                                'PdfUrl': updatedExpense['pdfUrl'],
                                'status': 'AUTHORISED',
                                'subTotal': updatedExpense['subTotal'],
                                'total': updatedExpense['amountDue'],
                                'totalTax': updatedExpense['totalTax'],
                                'type': updatedExpense['type'],
                                "unreconciledReportIds": ""
                              };
                              print(jsonEncode(receipt));
                              final resp =
                                  await ApiService.publishReceipt(receipt);
                              if (resp.isNotEmpty) {
                                ScaffoldMessenger.of(
                                        navigatorKey.currentContext!)
                                    .showSnackBar(const SnackBar(
                                        content:
                                            Text('Published successfully.')));
                                Navigator.push(
                                    navigatorKey.currentContext!,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const HomeScreen(pageIndex: 0)));
                              } else {
                                setState(() {
                                  showSpinner = false;
                                });
                                ScaffoldMessenger.of(
                                        navigatorKey.currentContext!)
                                    .showSnackBar(const SnackBar(
                                        content: Text(
                                            'We were unable to publish the expense, please try again.')));
                              }
                            },
                            child: const Text(
                              'Publish',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.white),
                            )),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                            onPressed: () async {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return StatefulBuilder(
                                        builder: (context, setState) =>
                                            AlertDialog(
                                              content: Container(
                                                color: Colors.white,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                        'Are you sure you want to delete the invoice?',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: 14,
                                                            color:
                                                                headingColor))
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                    onPressed: () async {
                                                      setState(() {
                                                        showSpinner = true;
                                                      });
                                                      final resp =
                                                          await ApiService
                                                              .deleteExpense(
                                                                  expense[
                                                                      'id']);
                                                      setState(() {
                                                        showSpinner = false;
                                                      });
                                                      if (resp.isNotEmpty) {
                                                        Navigator.push(
                                                            navigatorKey
                                                                .currentContext!,
                                                            MaterialPageRoute(
                                                                builder: (context) =>
                                                                    const HomeScreen(
                                                                        pageIndex:
                                                                            0)));
                                                      } else {
                                                        ScaffoldMessenger.of(
                                                                navigatorKey
                                                                    .currentContext!)
                                                            .showSnackBar(
                                                                const SnackBar(
                                                                    content: Text(
                                                                        'We were unable to delete the expense, please try again.')));
                                                      }
                                                    },
                                                    child: const Text('Delete',
                                                        style: TextStyle(
                                                            color: Colors.red,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500))),
                                                TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text('Cancel',
                                                        style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500)))
                                              ],
                                            ));
                                  });
                            },
                            child: const Text('Delete',
                                style: TextStyle(
                                    color: Color(0XFFFF4E4E),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500))),
                      )
                    ],
                  ),
                ),
              )),
        ),
        onPopInvokedWithResult: (didPop, result) {
          Navigator.push(
              navigatorKey.currentContext!,
              MaterialPageRoute(
                  builder: (context) => const HomeScreen(pageIndex: 0)));
        });
  }
}
