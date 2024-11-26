import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:photo_view/photo_view.dart';
import 'package:synced/main.dart';
import 'package:synced/screens/home/home_screen.dart';
import 'package:synced/utils/api_services.dart';
import 'package:synced/utils/constants.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class UpdateExpenseData extends StatefulWidget {
  final Map expense;
  final String? imagePath;
  final bool? isProcessed;
  const UpdateExpenseData(
      {super.key,
      required this.expense,
      required this.imagePath,
      this.isProcessed});

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
  TextEditingController accountController = TextEditingController();
  TextEditingController accountSearchController = TextEditingController();
  FocusNode keyboardFocusNode = FocusNode();
  Map updatedExpense = {};
  DateTime? selectedDate;
  String? selectedCurrency;
  Map? selectedAccount;
  Map? selectedCard;
  Map<String, dynamic>? selectedTaxRate;
  List paymentAccounts = [];
  List filteredPaymentAccounts = [];
  List bankDetails = [];
  List taxRates = [];
  List suppliers = [];
  List currencies = [];
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
    await getOrgCurrencies();
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
          : currencies.first ?? 'USD';
      currencyController.text = selectedCurrency!;
      totalController.text = expense['subTotal'].toString();
      for (var acc in paymentAccounts) {
        if (acc['id'] == expense['invoiceLines'][0]['accountId']) {
          selectedAccount = acc;
          accountController.text = acc['name'];
          break;
        }
      }
      descriptionController.text =
          expense['invoiceLines'][0]['description'] ?? '';
    });
  }

  Future<void> getInvoiceById() async {
    final resp = await ApiService.getInvoiceById(widget.expense['id']);
    expense = resp;
  }

  Future<void> getPaymentAccounts() async {
    final resp = await ApiService.getPaymentAccounts(selectedOrgId);
    paymentAccounts = resp;
    filteredPaymentAccounts = resp;
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

  Future<void> getOrgCurrencies() async {
    final List resp = await ApiService.getOrgCurrencies(selectedOrgId);
    if (resp.isNotEmpty) {
      currencies = resp;
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
    for (var acc in filteredPaymentAccounts) {
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

  List<DropdownMenuItem> getOrgCurrenciesDropdownItems() {
    List<DropdownMenuItem> currencyList = [];
    for (var cur in currencies) {
      currencyList.add(DropdownMenuItem(value: cur, child: Text(cur)));
    }
    if (!currencies.contains(selectedCurrency)) {
      selectedCurrency = currencies.first;
    }

    return currencyList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 100,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0XFFECECEC),
        leading: IconButton(
            onPressed: () {
              Navigator.push(
                  navigatorKey.currentContext!,
                  MaterialPageRoute(
                      builder: (context) => const HomeScreen(tabIndex: 0)));
            },
            icon: const Icon(Icons.arrow_back_ios)),
        title: const SizedBox(height: 10),
        bottom: PreferredSize(
            preferredSize: const Size(200, 150),
            child: widget.imagePath != null
                ? SizedBox(
                    height: 200,
                    child: GestureDetector(
                      onTap: () {
                        showGeneralDialog(
                            barrierDismissible: false,
                            context: context,
                            pageBuilder: (context, animation,
                                    secondaryAnimation) =>
                                Container(
                                  color: Colors.white,
                                  padding: EdgeInsets.zero,
                                  width: 100,
                                  height: 200,
                                  child: Stack(
                                    children: [
                                      PhotoView(
                                        imageProvider:
                                            CachedNetworkImageProvider(
                                                widget.imagePath!),
                                      ),
                                      Positioned(
                                          top: 50,
                                          left: 10,
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: CircleAvatar(
                                              backgroundColor:
                                                  Colors.grey.shade400,
                                              child: IconButton(
                                                icon: const Icon(Icons.close,
                                                    color: Colors.white),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            ),
                                          )),
                                    ],
                                  ),
                                ));
                      },
                      child: CachedNetworkImage(
                        imageUrl: widget.imagePath!,
                        errorWidget: (context, url, error) {
                          return SfPdfViewer.network(widget.imagePath!,
                              onTap: (details) {
                            showGeneralDialog(
                                barrierDismissible: false,
                                context: context,
                                pageBuilder: (context, animation,
                                        secondaryAnimation) =>
                                    Container(
                                      color: Colors.white,
                                      padding: EdgeInsets.zero,
                                      width: MediaQuery.of(context).size.width -
                                          10,
                                      height:
                                          MediaQuery.of(context).size.height -
                                              10,
                                      child: Stack(
                                        children: [
                                          SfPdfViewer.network(widget.imagePath!,
                                              canShowPageLoadingIndicator:
                                                  false,
                                              canShowScrollHead: false,
                                              canShowScrollStatus: false),
                                          Positioned(
                                              top: 50,
                                              left: 10,
                                              child: Align(
                                                alignment: Alignment.topLeft,
                                                child: CircleAvatar(
                                                  backgroundColor:
                                                      Colors.grey.shade400,
                                                  child: IconButton(
                                                    icon: const Icon(
                                                        Icons.close,
                                                        color: Colors.white),
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                ),
                                              )),
                                        ],
                                      ),
                                    ));
                          },
                              enableDoubleTapZooming: false,
                              enableTextSelection: false,
                              enableDocumentLinkAnnotation: false,
                              enableHyperlinkNavigation: false,
                              canShowPageLoadingIndicator: false,
                              canShowScrollHead: false,
                              canShowScrollStatus: false);
                        },
                      ),
                    ),
                  )
                : Container(height: 200)),
      ),
      body: ModalProgressHUD(
          color: const Color(0XFFFBFBFB),
          opacity: 1.0,
          progressIndicator: appLoader,
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
                    enabled: !widget.isProcessed!,
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
                      updatedExpense['supplierName'] = supplierController.text;
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
                    enabled: !widget.isProcessed!,
                    keyboardType: TextInputType.none,
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.6,
                                      width: double.maxFinite,
                                      child: CupertinoDatePicker(
                                        mode: CupertinoDatePickerMode.date,
                                        onDateTimeChanged: (DateTime newDate) {
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
                                                    fontWeight: FontWeight.w500,
                                                    color: headingColor))),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text('Cancel',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
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
                    enabled: !widget.isProcessed!,
                    keyboardType: TextInputType.none,
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
                    onTap: () {
                      showCurrencyPicker(
                        context: context,
                        showFlag: true,
                        showCurrencyName: true,
                        showCurrencyCode: true,
                        currencyFilter: currencies.cast<String>(),
                        onSelect: (Currency currency) async {
                          setState(() {
                            selectedCurrency = currency.code;
                            currencyController.text = currency.code;
                          });
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
                    enabled: !widget.isProcessed!,
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
                  TextField(
                    enabled: !widget.isProcessed!,
                    keyboardType: TextInputType.none,
                    controller: accountController,
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
                    onTap: () {
                      showModalBottomSheet(
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          context: context,
                          builder: (context) {
                            return StatefulBuilder(
                                builder: (context, setState) => Container(
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      padding: const EdgeInsets.all(20),
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.9,
                                      width: double.maxFinite,
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller: accountSearchController,
                                            decoration: InputDecoration(
                                              hintText: 'Search',
                                              prefixIcon:
                                                  const Icon(Icons.search),
                                              border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                  borderSide: BorderSide(
                                                      color: subHeadingColor)),
                                              enabledBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                  borderSide: BorderSide(
                                                      color: subHeadingColor)),
                                              focusedBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                  borderSide: BorderSide(
                                                      color: subHeadingColor)),
                                              filled: true,
                                              fillColor: Colors.white,
                                            ),
                                            maxLines: 1,
                                            onChanged: (query) {
                                              filteredPaymentAccounts = [];
                                              if (accountSearchController
                                                  .text.isNotEmpty) {
                                                for (var acc
                                                    in paymentAccounts) {
                                                  if (acc['name']
                                                      .toString()
                                                      .toLowerCase()
                                                      .contains(
                                                          accountSearchController
                                                              .text
                                                              .toLowerCase())) {
                                                    filteredPaymentAccounts
                                                        .add(acc);
                                                  }
                                                }
                                              } else {
                                                filteredPaymentAccounts =
                                                    paymentAccounts;
                                              }
                                              setState(() {});
                                            },
                                          ),
                                          const SizedBox(height: 30),
                                          Expanded(
                                              child: ListView.separated(
                                                  separatorBuilder:
                                                      (context, index) =>
                                                          const Divider(),
                                                  shrinkWrap: true,
                                                  itemCount:
                                                      filteredPaymentAccounts
                                                          .length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    return GestureDetector(
                                                      onTap: () async {
                                                        setState(() {
                                                          selectedAccount =
                                                              filteredPaymentAccounts[
                                                                  index];
                                                          accountController
                                                                  .text =
                                                              filteredPaymentAccounts[
                                                                      index]
                                                                  ['name'];
                                                          accountSearchController
                                                              .clear();
                                                          filteredPaymentAccounts =
                                                              paymentAccounts;
                                                        });

                                                        updatedExpense[
                                                                    'invoiceLines']
                                                                [
                                                                0]['accountId'] =
                                                            selectedAccount![
                                                                'id'];
                                                        updatedExpense['invoiceLines']
                                                                    [0][
                                                                'accountName'] =
                                                            selectedAccount![
                                                                'name'];

                                                        FocusManager.instance
                                                            .primaryFocus
                                                            ?.unfocus();
                                                        final resp =
                                                            await ApiService
                                                                .updateExpense(
                                                                    updatedExpense);
                                                        setState(() {
                                                          showSpinner = false;
                                                        });
                                                        if (resp.isNotEmpty) {
                                                          ScaffoldMessenger.of(
                                                                  navigatorKey
                                                                      .currentContext!)
                                                              .showSnackBar(
                                                                  const SnackBar(
                                                                      content: Text(
                                                                          'Updated successfully.')));
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                                  navigatorKey
                                                                      .currentContext!)
                                                              .showSnackBar(
                                                                  const SnackBar(
                                                                      content: Text(
                                                                          'Failed to update.')));
                                                        }

                                                        Navigator.pop(context);
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .fromLTRB(
                                                                10, 10, 10, 0),
                                                        height: 50,
                                                        child: selectedAccount?[
                                                                    'id'] ==
                                                                filteredPaymentAccounts[
                                                                    index]['id']
                                                            ? Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Text(
                                                                    filteredPaymentAccounts[
                                                                            index]
                                                                        [
                                                                        'name'],
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        fontWeight:
                                                                            FontWeight.w500),
                                                                  ),
                                                                  const Icon(
                                                                      Icons
                                                                          .check_circle_outline,
                                                                      color: Colors
                                                                          .green,
                                                                      size: 25)
                                                                ],
                                                              )
                                                            : Text(
                                                                filteredPaymentAccounts[
                                                                        index]
                                                                    ['name'],
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500),
                                                              ),
                                                      ),
                                                    );
                                                  }))
                                        ],
                                      ),
                                    ));
                          });
                    },
                  ),
                  const SizedBox(height: 15),
                  Text('Total',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: headingColor)),
                  const SizedBox(height: 10),
                  KeyboardActions(
                    bottomAvoiderScrollPhysics:
                        const NeverScrollableScrollPhysics(),
                    disableScroll: true,
                    config: KeyboardActionsConfig(
                      nextFocus: false,
                      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
                      keyboardBarColor:
                          const Color(0xFFCAD1D9), //Apple keyboard color
                      actions: [
                        KeyboardActionsItem(
                          focusNode: keyboardFocusNode,
                          toolbarButtons: [
                            (node) {
                              return GestureDetector(
                                onTap: () async {
                                  node.unfocus();
                                  setState(() {
                                    showSpinner = true;
                                  });
                                  // call updateInvoice API with new tax data
                                  updatedExpense['invoiceLines'][0]
                                          ['subTotal'] =
                                      double.parse(totalController.text);
                                  updatedExpense['subTotal'] =
                                      double.parse(totalController.text);
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  final resp = await ApiService.updateExpense(
                                      updatedExpense);
                                  setState(() {
                                    showSpinner = false;
                                  });
                                  if (resp.isNotEmpty) {
                                    ScaffoldMessenger.of(
                                            navigatorKey.currentContext!)
                                        .showSnackBar(const SnackBar(
                                            content:
                                                Text('Updated successfully.')));
                                  } else {
                                    ScaffoldMessenger.of(
                                            navigatorKey.currentContext!)
                                        .showSnackBar(const SnackBar(
                                            content:
                                                Text('Failed to update.')));
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12.0),
                                  child: const Text(
                                    'Done',
                                    style: TextStyle(
                                      color:
                                          Color(0xFF0978ED), //Done button color
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }
                          ],
                        ),
                      ],
                    ),
                    child: TextField(
                      focusNode: keyboardFocusNode,
                      enabled: !widget.isProcessed!,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
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
                      maxLines: 1,
                    ),
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
                      if (widget.isProcessed == false) ...[
                        GestureDetector(
                          onTap: () {
                            showDialog(
                                context: navigatorKey.currentContext!,
                                builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0)),
                                      insetPadding: const EdgeInsets.all(10),
                                      backgroundColor: Colors.white,
                                      title: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          color: const Color(0XFFF9FAFB),
                                        ),
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.075,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text('  Tax Amount',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: headingColor)),
                                        ),
                                      ),
                                      titlePadding: const EdgeInsets.all(0),
                                      contentPadding: const EdgeInsets.all(10),
                                      content: StatefulBuilder(
                                          builder: (context, setState) =>
                                              Container(
                                                color: Colors.white,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.3,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.95,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    DropdownButtonHideUnderline(
                                                        child: DropdownButton2(
                                                      isExpanded: true,
                                                      value: selectedTaxRate,
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
                                                                right: 14),
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(14),
                                                          border: Border.all(
                                                            strokeAlign: 0,
                                                            color:
                                                                Colors.black26,
                                                          ),
                                                        ),
                                                      ),
                                                      dropdownStyleData:
                                                          const DropdownStyleData(
                                                              decoration:
                                                                  BoxDecoration(
                                                                      color: Colors
                                                                          .white)),
                                                    )),
                                                    const SizedBox(height: 30),
                                                    Center(
                                                      child: ElevatedButton(
                                                          style: ButtonStyle(
                                                              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                                                                  RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12.0))),
                                                              fixedSize: WidgetStateProperty.all(Size(
                                                                  MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width,
                                                                  MediaQuery.of(context)
                                                                          .size
                                                                          .height *
                                                                      0.06)),
                                                              backgroundColor:
                                                                  WidgetStateProperty.all(
                                                                      const Color(0XFF009318))),
                                                          onPressed: () async {
                                                            setState(() {
                                                              showSpinner =
                                                                  true;
                                                            });
                                                            // call updateInvoice API with new tax data
                                                            updatedExpense[
                                                                        'invoiceLines']
                                                                    [
                                                                    0]['taxId'] =
                                                                selectedTaxRate?[
                                                                    'id'];
                                                            double totalAmount = updatedExpense[
                                                                    'subTotal'] +
                                                                updatedExpense[
                                                                        'subTotal'] *
                                                                    selectedTaxRate?[
                                                                        'rate'] /
                                                                    100;
                                                            double totalTax =
                                                                updatedExpense[
                                                                        'subTotal'] *
                                                                    selectedTaxRate?[
                                                                        'rate'] /
                                                                    100;
                                                            updatedExpense['invoiceLines']
                                                                        [0][
                                                                    'totalTax'] =
                                                                totalTax;
                                                            updatedExpense[
                                                                    'amountDue'] =
                                                                totalAmount;
                                                            final resp =
                                                                await ApiService
                                                                    .updateExpense(
                                                                        updatedExpense);
                                                            setState(() {
                                                              showSpinner =
                                                                  false;
                                                            });
                                                            Navigator.pop(
                                                                context);
                                                            if (resp
                                                                .isNotEmpty) {
                                                              ScaffoldMessenger.of(
                                                                      navigatorKey
                                                                          .currentContext!)
                                                                  .showSnackBar(
                                                                      const SnackBar(
                                                                          content:
                                                                              Text('Updated successfully.')));
                                                            } else {
                                                              ScaffoldMessenger.of(
                                                                      navigatorKey
                                                                          .currentContext!)
                                                                  .showSnackBar(
                                                                      const SnackBar(
                                                                          content:
                                                                              Text('Failed to update.')));
                                                            }
                                                          },
                                                          child: const Text(
                                                            'Save',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 14,
                                                                color: Colors
                                                                    .white),
                                                          )),
                                                    ),
                                                    TextButton(
                                                        onPressed: () async {
                                                          Navigator.pop(navigatorKey
                                                              .currentContext!);
                                                        },
                                                        child: const Text(
                                                            'Discard',
                                                            style: TextStyle(
                                                                fontSize: 14,
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
                      ]
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
                    enabled: !widget.isProcessed!,
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
                    onTapOutside: (cb) async {
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
                  if (widget.isProcessed == false) ...[
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
                    ))
                  ] else ...[
                    Text(selectedCard?['name'] ?? '',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: headingColor)),
                  ],
                  const SizedBox(height: 15),
                  if (widget.isProcessed == false) ...[
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
                              if (supplier['name'] == supplierController.text) {
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
                              'invoiceNumber': updatedExpense['invoiceNumber'],
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
                              ScaffoldMessenger.of(navigatorKey.currentContext!)
                                  .showSnackBar(const SnackBar(
                                      content:
                                          Text('Published successfully.')));
                              Navigator.push(
                                  navigatorKey.currentContext!,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const HomeScreen(tabIndex: 0)));
                            } else {
                              setState(() {
                                showSpinner = false;
                              });
                              ScaffoldMessenger.of(navigatorKey.currentContext!)
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
                                            title: Text(
                                                'Are you sure you want to delete the invoice?',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                    color: headingColor)),
                                            actions: [
                                              TextButton(
                                                  onPressed: () async {
                                                    setState(() {
                                                      showSpinner = true;
                                                    });
                                                    final resp =
                                                        await ApiService
                                                            .deleteExpense(
                                                                expense['id']);
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
                                                                      tabIndex:
                                                                          0,
                                                                      navbarIndex:
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
                                                          fontWeight: FontWeight
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
                                                              FontWeight.w500)))
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
                  ]
                ],
              ),
            ),
          )),
    );
  }
}
