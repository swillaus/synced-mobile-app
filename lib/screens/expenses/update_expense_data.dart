import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
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
import 'package:lottie/lottie.dart';

class UpdateExpenseData extends StatefulWidget {
  final Map expense;
  final String? imagePath;
  final bool? isProcessed;
  final String selectedOrgId;

  const UpdateExpenseData({
    super.key,
    required this.expense,
    required this.imagePath,
    this.isProcessed,
    required this.selectedOrgId,
  });

  @override
  State<UpdateExpenseData> createState() => _UpdateExpenseDataState();
}

class _UpdateExpenseDataState extends State<UpdateExpenseData> {
  TextEditingController supplierController = TextEditingController();
  TextEditingController supplierSearchController = TextEditingController();
  TextEditingController refController = TextEditingController();
  TextEditingController totalController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController currencyController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController accountController = TextEditingController();
  TextEditingController accountSearchController = TextEditingController();
  FocusNode keyboardFocusNode = FocusNode();

  String? imagePath;
  Widget? _publishButtonChild;

  final InputDecoration plainInputDecoration = const InputDecoration(
    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    filled: true,
    fillColor: Colors.white,
    alignLabelWithHint: true,
    // Add this to align text to the left
    constraints: BoxConstraints(maxHeight: 40),
  );

  final InputDecoration dropdownInputDecoration = const InputDecoration(
    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    filled: true,
    fillColor: Colors.white,
    alignLabelWithHint: true,
    constraints: BoxConstraints(maxHeight: 40, minWidth: double.infinity),
    suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey),
  );

  Map updatedExpense = {};
  DateTime? selectedDate;
  String? selectedCurrency;
  Map? selectedAccount;
  Map? selectedSupplier;
  Map? selectedCard;
  Map<String, dynamic>? selectedTaxRate;

  List paymentAccounts = [];
  List filteredPaymentAccounts = [];
  List bankDetails = [];
  List taxRates = [];
  List suppliers = [];
  List filteredSuppliers = [];
  List currencies = [];
  Map expense = {};

  bool showSpinner = false;

  @override
  void initState() {
    super.initState();
    preparePage();
  }

  @override
  void didUpdateWidget(covariant UpdateExpenseData oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedOrgId != widget.selectedOrgId) {
      // Organization has changed, load new data
      preparePage();
    }
  }

  Future<void> preparePage() async {
    setState(() {
      showSpinner = true;
    });

    // Fetch the invoice data
    await getInvoiceById();

    // Assuming the pdfUrl is part of the expense data
    String? pdfUrl = widget.expense['pdfUrl'];

    // Construct the imagePath with the pdfUrl
    setState(() {
      if (pdfUrl != null && pdfUrl.isNotEmpty) {
        imagePath = pdfUrl;
      } else {
        imagePath = null; // Handle the case where pdfUrl is null or empty
      }
    });

    // Log the constructed imagePath for debugging
    print('Constructed imagePath: $imagePath');

    // Continue with other initializations
    await getSuppliers();
    getPaymentAccounts();
    getBankDetails();
    getOrgCurrencies();
    getTaxRates();

    setState(() {
      updatedExpense = widget.expense;
      updatedExpense.remove('invoice_path');
      supplierController.text = widget.expense['supplierName'] ?? '';
      selectedDate = DateTime.parse(widget.expense['date']);
      dateController.text = DateFormat('dd MMM, yyyy').format(DateTime.parse(widget.expense['date']));
      refController.text = widget.expense['invoiceNumber'] ?? '';
      descriptionController.text = widget.expense['invoiceLines'][0]['description'] ?? '';
      showSpinner = false;
    });
  }

  Future<void> getInvoiceById() async {
    final resp = await ApiService.getInvoiceById(widget.expense['id']);
    print('API Response: $resp'); // Log the API response
    expense = resp;
  }

  Future<void> getPaymentAccounts() async {
    final resp = await ApiService.getPaymentAccounts(widget.selectedOrgId);
    paymentAccounts = resp;
    filteredPaymentAccounts = resp;
    for (var acc in paymentAccounts) {
      if (acc['id'] == widget.expense['invoiceLines'][0]['accountId']) {
        selectedAccount = acc;
        accountController.text = acc['name'];
        break;
      }
    }
  }

  Future<void> getBankDetails() async {
    final resp = await ApiService.getBankDetails(widget.selectedOrgId);
    if (resp.isNotEmpty && resp['status'] == 0) {
      bankDetails = resp['data'];
      for (var bankDetail in bankDetails) {
        if (widget.expense['paymentAccountNumber'] == bankDetail['accountID']) {
          selectedCard = bankDetail;
        }
      }
    }
  }

  Future<void> getTaxRates() async {
    final resp = await ApiService.getTaxRates(widget.selectedOrgId);
    if (resp.isNotEmpty) {
      taxRates = resp;
      for (var tax in taxRates) {
        if (tax['id'] == widget.expense['invoiceLines'][0]['taxId']) {
          selectedTaxRate = tax;
        }
      }
    }
  }

  Future<void> getOrgCurrencies() async {
    final List resp = await ApiService.getOrgCurrencies(widget.selectedOrgId);
    if (resp.isNotEmpty) {
      currencies = resp;
    }
    selectedCurrency =
    widget.expense['currency'] != null && widget.expense['currency'].runtimeType == String
        ? widget.expense['currency']
        : currencies.isNotEmpty
        ? currencies.first
        : 'USD';
    currencyController.text = selectedCurrency!;
    totalController.text = widget.expense['amountDue'].toString();
  }

  Future<void> getSuppliers() async {
    suppliers.clear();
    filteredSuppliers.clear();
    final resp = await ApiService.getSuppliers(widget.selectedOrgId);
    if (resp.isNotEmpty) {
      suppliers = resp;
      if (suppliers
          .where((element) => element['name'] == widget.expense['supplierName'])
          .isNotEmpty) {
        selectedSupplier = suppliers
            .where((element) => element['name'] == widget.expense['supplierName'])
            .first;
      } else {
        filteredSuppliers.add({'name': "+ Add ${widget.expense['supplierName']}"});
      }
      filteredSuppliers.addAll(resp);
    }
    setState(() {
      showSpinner = false;
    });
  }

  // Generate dropdown items for payment accounts, bank details, etc.
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
      accounts.add(DropdownMenuItem(value: bankDetail, child: Text(bankDetail['name'])));
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
      selectedCurrency = currencies.isNotEmpty ? currencies.first : 'USD';
    }
    return currencyList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: ModalProgressHUD(
        color: const Color(0XFFFBFBFB),
        opacity: 1.0,
        progressIndicator: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            appLoader,
            Lottie.asset('assets/animations/loading.json', width: 300, height: 300),
          ],
        ),
        inAsyncCall: showSpinner,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Table(
                    columnWidths: const {
                      0: FixedColumnWidth(120), // Label column
                      1: FlexColumnWidth(), // Input column
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    children: [
                      _buildTableRow("Supplier", Align(alignment: Alignment.centerLeft, child: _buildSupplierWidget())),
                      _buildTableRow("Date", Align(alignment: Alignment.centerLeft, child: _buildDateWidget())),
                      _buildTableRow("Currency", Align(alignment: Alignment.centerLeft, child: _buildCurrencyWidget())),
                      _buildTableRow("Ref", Align(alignment: Alignment.centerLeft, child: _buildRefWidget())),
                      _buildTableRow("Account", Align(alignment: Alignment.centerLeft, child: _buildAccountWidget())),
                      _buildTableRow("Paid Form", Align(alignment: Alignment.centerLeft, child: _buildPaidFormWidget())),
                      _buildTableRow("Description", Align(alignment: Alignment.centerLeft, child: _buildDescriptionWidget())),
                      _buildTableRow("Total", Align(alignment: Alignment.centerLeft, child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTotalWidget(),
                          const SizedBox(height: 8),
                          _buildTaxChipRow(),
                        ],
                      ))),
                    ],
                  ),
                ),
              ),
            ),
            // Add buttons at the bottom
            if (widget.isProcessed == false) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    _buildPublishButton(),
                    const SizedBox(height: 10),
                    _buildDeleteButton(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// A helper method to build a single row with a label on the left and a widget on the right.
  Widget _buildRow(String label, Widget widgetOnRight) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        // Label with fixed width
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // The input or read-only value on the right
        Expanded(child: widgetOnRight),
      ],
    );
  }

  /// Type field: read-only text, defaulting to "Receipt" if none.
  Widget _buildTypeValue() {
    final String typeVal = updatedExpense['type'] ?? "Receipt";
    return TextField(
      enabled: false,
      controller: TextEditingController(text: typeVal),
      decoration: plainInputDecoration,
      textAlign: TextAlign.left,
    );
  }

  /// Supplier name widget: your existing logic to show a text field or a row with an icon if it exists
  Widget _buildSupplierWidget() {
    // If the supplier is not found in the list
    if (suppliers.where((element) => element['name'] == widget.expense['supplierName']).isEmpty) {
      return TextField(
        enabled: !widget.isProcessed!,
        controller: supplierController,
        keyboardType: TextInputType.none,
        decoration: dropdownInputDecoration,
        onTap: _showSupplierBottomSheet,
        maxLines: 1,
        textAlign: TextAlign.left,
      );
    } else {
      // If found
      return Row(
        children: [
          Expanded(
            child: TextField(
              enabled: !widget.isProcessed!,
              controller: supplierController,
              keyboardType: TextInputType.none,
              decoration: dropdownInputDecoration,
              maxLines: 1,
              onTap: _showSupplierBottomSheet,
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 25),
        ],
      );
    }
  }

  void _showSupplierBottomSheet() {
    // Same logic you had for showing suppliers
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.9,
            width: double.maxFinite,
            child: Column(
              children: [
                TextField(
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                  controller: supplierSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search),
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
                  onChanged: (query) {
                    filteredSuppliers = [];
                    if (supplierSearchController.text.isNotEmpty) {
                      filteredSuppliers.add({'name': '+ Add $query'});
                      for (var acc in suppliers) {
                        if (acc['name']
                            .toString()
                            .toLowerCase()
                            .contains(supplierSearchController.text.toLowerCase())) {
                          filteredSuppliers.add(acc);
                        }
                      }
                    } else {
                      if (suppliers
                          .where((element) => element['name'] == widget.expense['supplierName'])
                          .isEmpty) {
                        filteredSuppliers
                            .add({'name': "+ Add "+widget.expense['supplierName']});
                      }
                      filteredSuppliers.addAll(suppliers);
                    }
                    setState(() {});
                  },
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView.separated(
                    separatorBuilder: (context, index) => const Divider(),
                    shrinkWrap: true,
                    itemCount: filteredSuppliers.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () async {
                          await _handleSupplierSelection(index);
                          Navigator.pop(context);
                          preparePage();
                        },
                        child: _buildSupplierListTile(index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      setState(() {
        supplierSearchController.clear();
        filteredSuppliers = suppliers;
      });
    });
  }

  Future<void> _handleSupplierSelection(int index) async {
    if (filteredSuppliers[index]['name'].startsWith('+ Add ')) {
      if (supplierSearchController.text.isNotEmpty) {
        final resp = await ApiService.createSupplier(supplierSearchController.text);
        selectedSupplier = {
          'id': resp['supplierId'],
          'name': supplierSearchController.text,
        };
        supplierController.text = supplierSearchController.text;
      } else {
        final resp = await ApiService.createSupplier(
          filteredSuppliers[index]['name'].toString().replaceAll('+ Add ', ''),
        );
        selectedSupplier = {
          'id': resp['supplierId'],
          'name': filteredSuppliers[index]['name']
              .toString()
              .replaceAll('+ Add ', ''),
        };
        supplierController.text = filteredSuppliers[index]['name']
            .toString()
            .replaceAll('+ Add ', '');
      }
    } else {
      selectedSupplier = filteredSuppliers[index];
    }

    setState(() {
      supplierSearchController.clear();
      filteredSuppliers = suppliers;
    });

    updatedExpense['supplierName'] = selectedSupplier!['name'];
    updatedExpense['supplierId'] = selectedSupplier!['id'];

    FocusManager.instance.primaryFocus?.unfocus();
    final resp = await ApiService.updateExpense(updatedExpense);
    setState(() {
      showSpinner = false;
    });
    if (resp.isNotEmpty) {
      setState(() {
        updatedExpense = updatedExpense;
      });
      ScaffoldMessenger.of(navigatorKey.currentContext!)
          .showSnackBar(const SnackBar(content: Text('Updated successfully.')));
    } else {
      setState(() {
        updatedExpense = widget.expense;
      });
      ScaffoldMessenger.of(navigatorKey.currentContext!)
          .showSnackBar(const SnackBar(content: Text('Failed to update.')));
    }
  }

  Widget _buildSupplierListTile(int index) {
    bool isSelected =
    (selectedSupplier?['id'] == filteredSuppliers[index]['id'] &&
        !filteredSuppliers[index]['name'].toString().startsWith('+ Add'));
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      height: 50,
      child: isSelected
          ? Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            filteredSuppliers[index]['name'],
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 25),
        ],
      )
          : Text(
        filteredSuppliers[index]['name'],
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// Date field logic
  Widget _buildDateWidget() {
    return TextField(
      enabled: !widget.isProcessed!,
      keyboardType: TextInputType.none,
      controller: dateController,
      decoration: dropdownInputDecoration,
      maxLines: 1,
      onTap: _pickDate,
      textAlign: TextAlign.left,
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: navigatorKey.currentContext!,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: clickableColor,
              onPrimary: Colors.black,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: clickableColor),
            ),
          ),
          child: child!,
        );
      },
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      currentDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dateController.text = DateFormat('dd MMM, yyyy').format(selectedDate!);
      });
      updatedExpense['date'] =
      '${selectedDate?.year}-${selectedDate?.month}-${selectedDate?.day}';
      FocusManager.instance.primaryFocus?.unfocus();
      final resp = await ApiService.updateExpense(updatedExpense);
      setState(() {
        showSpinner = false;
      });
      if (resp.isNotEmpty) {
        setState(() {
          updatedExpense = updatedExpense;
        });
        ScaffoldMessenger.of(navigatorKey.currentContext!)
            .showSnackBar(const SnackBar(content: Text('Updated successfully.')));
      } else {
        setState(() {
          updatedExpense = widget.expense;
        });
        ScaffoldMessenger.of(navigatorKey.currentContext!)
            .showSnackBar(const SnackBar(content: Text('Failed to update.')));
      }
    }
  }

  /// Currency field logic
  Widget _buildCurrencyWidget() {
    return TextField(
      enabled: !widget.isProcessed!,
      keyboardType: TextInputType.none,
      controller: currencyController,
      decoration: dropdownInputDecoration,
      maxLines: 1,
      onTap: _pickCurrency,
      textAlign: TextAlign.left,
    );
  }

  void _pickCurrency() {
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
        final resp = await ApiService.updateExpense(updatedExpense);
        setState(() {
          showSpinner = false;
        });
        if (resp.isNotEmpty) {
          setState(() {
            updatedExpense = updatedExpense;
          });
          ScaffoldMessenger.of(navigatorKey.currentContext!)
              .showSnackBar(const SnackBar(content: Text('Updated successfully.')));
        } else {
          setState(() {
            updatedExpense = widget.expense;
          });
          ScaffoldMessenger.of(navigatorKey.currentContext!)
              .showSnackBar(const SnackBar(content: Text('Failed to update.')));
        }
      },
    );
  }

  /// Ref field logic
  Widget _buildRefWidget() {
    return TextField(
      enabled: !widget.isProcessed!,
      controller: refController,
      decoration: plainInputDecoration.copyWith(
        hintText: refController.text.isEmpty ? 'Add Reference' : null,
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      maxLines: 1,
      onEditingComplete: () async {
        updatedExpense['invoiceNumber'] = refController.text;
        FocusManager.instance.primaryFocus?.unfocus();
        final resp = await ApiService.updateExpense(updatedExpense);
        setState(() {
          showSpinner = false;
        });
        if (resp.isNotEmpty) {
          setState(() {
            updatedExpense = updatedExpense;
          });
          ScaffoldMessenger.of(navigatorKey.currentContext!)
              .showSnackBar(const SnackBar(content: Text('Updated successfully.')));
        } else {
          setState(() {
            updatedExpense = widget.expense;
          });
          ScaffoldMessenger.of(navigatorKey.currentContext!)
              .showSnackBar(const SnackBar(content: Text('Failed to update.')));
        }
      },
      textAlign: TextAlign.left,
    );
  }

  /// Account field logic
  Widget _buildAccountWidget() {
    return TextField(
      enabled: !widget.isProcessed!,
      keyboardType: TextInputType.none,
      controller: accountController,
      decoration: dropdownInputDecoration.copyWith(
        hintText: 'Select Account',
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      maxLines: 1,
      onTap: _showAccountBottomSheet,
      textAlign: TextAlign.left,
    );
  }

  void _showAccountBottomSheet() {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.white,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.9,
            width: double.maxFinite,
            child: Column(
              children: [
                TextField(
                  controller: accountSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search),
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
                  onChanged: (query) {
                    filteredPaymentAccounts = [];
                    if (accountSearchController.text.isNotEmpty) {
                      for (var acc in paymentAccounts) {
                        if (acc['name']
                            .toString()
                            .toLowerCase()
                            .contains(accountSearchController.text.toLowerCase())) {
                          filteredPaymentAccounts.add(acc);
                        }
                      }
                    } else {
                      filteredPaymentAccounts = paymentAccounts;
                    }
                    setState(() {});
                  },
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView.separated(
                    separatorBuilder: (context, index) => const Divider(),
                    shrinkWrap: true,
                    itemCount: filteredPaymentAccounts.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () async {
                          setState(() {
                            selectedAccount = filteredPaymentAccounts[index];
                            accountController.text =
                            filteredPaymentAccounts[index]['name'];
                            accountSearchController.clear();
                            filteredPaymentAccounts = paymentAccounts;
                          });

                          updatedExpense['invoiceLines'][0]['accountId'] =
                          selectedAccount!['id'];
                          updatedExpense['invoiceLines'][0]['accountName'] =
                          selectedAccount!['name'];

                          FocusManager.instance.primaryFocus?.unfocus();
                          final resp = await ApiService.updateExpense(updatedExpense);
                          setState(() {
                            showSpinner = false;
                          });
                          if (resp.isNotEmpty) {
                            setState(() {
                              updatedExpense = updatedExpense;
                            });
                            ScaffoldMessenger.of(navigatorKey.currentContext!)
                                .showSnackBar(const SnackBar(
                                content: Text('Updated successfully.')));
                          } else {
                            setState(() {
                              updatedExpense = widget.expense;
                            });
                            ScaffoldMessenger.of(navigatorKey.currentContext!)
                                .showSnackBar(const SnackBar(
                                content: Text('Failed to update.')));
                          }
                          Navigator.pop(context);
                        },
                        child: _buildAccountListTile(index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountListTile(int index) {
    bool isSelected = (selectedAccount != null &&
        selectedAccount!['id'] == filteredPaymentAccounts[index]['id']);
    if (isSelected) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            filteredPaymentAccounts[index]['name'],
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 25),
        ],
      );
    } else {
      return Text(
        filteredPaymentAccounts[index]['name'],
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      );
    }
  }

  /// Paid form logic
  Widget _buildPaidFormWidget() {
    if (widget.isProcessed == false) {
      return DropdownButtonHideUnderline(
        child: DropdownButton2(
          hint: const Align(
            alignment: Alignment.centerLeft,
            child: Text('Select Payment Account', style: TextStyle(color: Colors.grey)),
          ),
          isExpanded: true,
          value: selectedCard,
          items: getBankDetailsDropdownItems(),
          onChanged: (value) async {
            setState(() {
              selectedCard = value;
              showSpinner = true;
            });
            updatedExpense['paymentAccountNumber'] = selectedCard?['accountID'];
            final resp = await ApiService.updateExpense(updatedExpense);
            setState(() {
              showSpinner = false;
            });
            if (resp.isNotEmpty) {
              setState(() {
                updatedExpense = updatedExpense;
              });
              ScaffoldMessenger.of(navigatorKey.currentContext!)
                  .showSnackBar(const SnackBar(content: Text('Updated successfully.')));
            } else {
              setState(() {
                updatedExpense = widget.expense;
              });
              ScaffoldMessenger.of(navigatorKey.currentContext!)
                  .showSnackBar(const SnackBar(content: Text('Failed to update.')));
            }
          },
          buttonStyleData: ButtonStyleData(
            height: 40, // Reduced height
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
          ),
          dropdownStyleData: const DropdownStyleData(
            decoration: BoxDecoration(color: Colors.white),
          ),
        ),
      );
    } else {
      // If processed, just show read-only text
      return Text(
        selectedCard?['name'] ?? 'Cash',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: headingColor),
      );
    }
  }

  /// Description logic
  Widget _buildDescriptionWidget() {
    return TextField(
      enabled: !widget.isProcessed!,
      textInputAction: TextInputAction.done,
      controller: descriptionController,
      decoration: plainInputDecoration.copyWith(
        hintText: descriptionController.text.isEmpty ? 'Add Description' : null,
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      maxLines: 3,
      onTapOutside: (cb) async {
        updatedExpense['description'] = descriptionController.text;
        updatedExpense['invoiceLines'][0]['description'] = descriptionController.text;
        FocusManager.instance.primaryFocus?.unfocus();
        final resp = await ApiService.updateExpense(updatedExpense);
        setState(() {
          showSpinner = false;
        });
        if (resp.isNotEmpty) {
          setState(() {
            updatedExpense = updatedExpense;
          });
          ScaffoldMessenger.of(navigatorKey.currentContext!)
              .showSnackBar(const SnackBar(content: Text('Updated successfully.')));
        } else {
          setState(() {
            updatedExpense = widget.expense;
          });
          ScaffoldMessenger.of(navigatorKey.currentContext!)
              .showSnackBar(const SnackBar(content: Text('Failed to update.')));
        }
      },
      textAlign: TextAlign.left,
    );
  }

  /// Total logic
  Widget _buildTotalWidget() {
    return KeyboardActions(
      bottomAvoiderScrollPhysics: const NeverScrollableScrollPhysics(),
      disableScroll: true,
      config: KeyboardActionsConfig(
        nextFocus: false,
        keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
        keyboardBarColor: const Color(0xFFCAD1D9),
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
                    updatedExpense['invoiceLines'][0]['amountDue'] =
                        double.parse(totalController.text);
                    updatedExpense['amountDue'] = double.parse(totalController.text);
                    FocusManager.instance.primaryFocus?.unfocus();
                    final resp = await ApiService.updateExpense(updatedExpense);
                    setState(() {
                      showSpinner = false;
                    });
                    if (resp.isNotEmpty) {
                      setState(() {
                        updatedExpense = updatedExpense;
                      });
                      ScaffoldMessenger.of(navigatorKey.currentContext!)
                          .showSnackBar(const SnackBar(content: Text('Updated successfully.')));
                    } else {
                      setState(() {
                        updatedExpense = widget.expense;
                      });
                      ScaffoldMessenger.of(navigatorKey.currentContext!)
                          .showSnackBar(const SnackBar(content: Text('Failed to update.')));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Color(0xFF0978ED),
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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        controller: totalController,
        decoration: plainInputDecoration,
        maxLines: 1,
        textAlign: TextAlign.left,
      ),
    );
  }

  /// Tax chip row
  Widget _buildTaxChipRow() {
    return Row(
      children: [
        Chip(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          side: const BorderSide(color: Color(0XFF009318)),
          backgroundColor: const Color(0XFFF2FFF5),
          label: Text(
            _buildTaxChipLabel(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0XFF009318),
            ),
          ),
        ),
        if (widget.isProcessed == false) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showTaxDialog,
            child: const Chip(
              shape: CircleBorder(side: BorderSide(color: Color(0XFF009318))),
              backgroundColor: Color(0XFFF2FFF5),
              label: Icon(
                Icons.edit_outlined,
                color: Color(0XFF009318),
                size: 22,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _buildTaxChipLabel() {
    if (selectedTaxRate != null && widget.expense['totalTax'] == 0) {
      double potentialTax = widget.expense['amountDue'] * (selectedTaxRate!['rate'] / 100);
      return 'Total tax includes: '
          '${widget.expense['currency'].runtimeType == String ? NumberFormat().simpleCurrencySymbol(widget.expense['currency']) : ''}'
          '$potentialTax';
    } else {
      return 'Total tax includes: '
          '${widget.expense['currency'].runtimeType == String ? NumberFormat().simpleCurrencySymbol(widget.expense['currency']) : ''}'
          '${widget.expense['totalTax']}';
    }
  }

  void _showTaxDialog() {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        insetPadding: const EdgeInsets.all(10),
        backgroundColor: Colors.white,
        title: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: const Color(0XFFF9FAFB),
          ),
          height: MediaQuery.of(context).size.height * 0.075,
          child: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tax Amount',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        titlePadding: const EdgeInsets.all(0),
        contentPadding: const EdgeInsets.all(10),
        content: StatefulBuilder(
          builder: (context, setState) => Container(
            color: Colors.white,
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width * 0.95,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton2(
                    isExpanded: true,
                    value: selectedTaxRate,
                    items: getTaxRateDropdownItems(),
                    onChanged: (value) {
                      setState(() {
                        selectedTaxRate = value;
                      });
                    },
                    buttonStyleData: ButtonStyleData(
                      height: 55,
                      padding: const EdgeInsets.only(left: 14, right: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(strokeAlign: 0, color: Colors.black26),
                      ),
                    ),
                    dropdownStyleData: const DropdownStyleData(
                      decoration: BoxDecoration(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      fixedSize: Size(
                        MediaQuery.of(context).size.width,
                        MediaQuery.of(context).size.height * 0.06,
                      ),
                      backgroundColor: const Color(0XFF009318),
                    ),
                    onPressed: () async {
                      setState(() {
                        showSpinner = true;
                      });
                      updatedExpense['invoiceLines'][0]['taxId'] =
                      selectedTaxRate?['id'];

                      double subTotal = updatedExpense['amountDue'] -
                          (updatedExpense['amountDue'] * (selectedTaxRate?['rate'] / 100));
                      double totalTax = updatedExpense['amountDue'] *
                          (selectedTaxRate?['rate'] / 100);

                      updatedExpense['totalTax'] = totalTax;
                      updatedExpense['subTotal'] = subTotal;
                      updatedExpense['invoiceLines'][0]['subTotal'] = subTotal;
                      updatedExpense['invoiceLines'][0]['totalTax'] = totalTax;

                      final resp = await ApiService.updateExpense(updatedExpense);
                      setState(() {
                        showSpinner = false;
                      });
                      if (resp.isNotEmpty) {
                        setState(() {
                          updatedExpense = updatedExpense;
                        });
                        ScaffoldMessenger.of(navigatorKey.currentContext!)
                            .showSnackBar(const SnackBar(content: Text('Updated successfully.')));
                      } else {
                        setState(() {
                          updatedExpense = widget.expense;
                        });
                        ScaffoldMessenger.of(navigatorKey.currentContext!)
                            .showSnackBar(const SnackBar(content: Text('Failed to update.')));
                      }
                    },
                    child: const Text(
                      'Save',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(navigatorKey.currentContext!);
                  },
                  child: const Text(
                    'Discard',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0XFFFF4E4E)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Publish button
  Widget _buildPublishButton() {
    return ElevatedButton(
      onPressed: _handlePublish,
      child: _publishButtonChild ?? const Text(
        'Publish',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        fixedSize: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height * 0.06),
        backgroundColor: const Color(0XFF009318),
      ),
    );
  }

  Future<void> _handlePublish() async {
    setState(() {
      showSpinner = true;
    });

    // Disable the button and show a loading spinner
    final buttonChild = ElevatedButton(
      onPressed: null, // Disable the button while loading
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        fixedSize: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height * 0.06),
        backgroundColor: const Color(0XFF009318),
      ),
    );

    // Temporarily replace the button with a loading spinner
    setState(() {
      _publishButtonChild = buttonChild;
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
      item.addAll({'organisationId': widget.selectedOrgId});
    }
    Map receipt = {
      "bankAccount": {
        "accountID": selectedCard?['accountID'],
        "bankAccountNumber": selectedCard?['bankAccountNumber'],
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
      'lineAmountTypes': 'Exclusive',
      'lineItems': lineItems,
      'OrganisationId': widget.selectedOrgId,
      'paymentAccountNumber': updatedExpense['paymentAccountNumber'],
      'paymentDate': updatedExpense['paymentDate'],
      'paymentStatus': updatedExpense['type'] == 'Receipt' ? 1 : 0,
      'PdfUrl': updatedExpense['pdfUrl'],
      'status': 'AUTHORISED',
      'subTotal': updatedExpense['subTotal'],
      'total': updatedExpense['amountDue'],
      'totalTax': updatedExpense['totalTax'],
      "unreconciledReportIds": ""
    };
    // Debug log
    print(jsonEncode(receipt));

    final resp = await ApiService.publishReceipt(receipt);
    setState(() {
      showSpinner = false;
      _publishButtonChild = null; // Reset the button to its original state
    });
    if (resp.isNotEmpty) {
      ScaffoldMessenger.of(navigatorKey.currentContext!)
          .showSnackBar(
        const SnackBar(content: Text('Published successfully! 🎉')),
      );
      Navigator.push(
        navigatorKey.currentContext!,
        MaterialPageRoute(builder: (context) => const HomeScreen(tabIndex: 0)),
      );
    } else {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(content: Text('We were unable to publish the expense, please try again.')),
      );
    }
  }

  /// Delete button
  Widget _buildDeleteButton() {
    return TextButton(
      onPressed: () async {
        showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                title: Text(
                  'Are you sure you want to delete the invoice?',
                  style: TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14, color: headingColor),
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      setState(() {
                        showSpinner = true;
                      });
                      final resp = await ApiService.deleteExpense(widget.expense['id']);
                      setState(() {
                        showSpinner = false;
                      });
                      if (resp.isNotEmpty) {
                        Navigator.push(
                          navigatorKey.currentContext!,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(
                              tabIndex: 0,
                              navbarIndex: 0,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'We were unable to delete the expense, please try again.'),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: const Text(
        'Delete',
        style: TextStyle(color: Color(0XFFFF4E4E), fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// AppBar with the image or PDF preview
  PreferredSizeWidget _buildAppBar() {
    print('Image URL: $imagePath');
    return AppBar(
      toolbarHeight: 60, // Reduced from 100
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      backgroundColor: const Color(0XFFECECEC),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.pop(context),
      ),
      title: const SizedBox(height: 10),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(40), // Adjust as needed
        child: imagePath != null && imagePath!.toLowerCase().endsWith('.pdf')
            ? SfPdfViewer.network(
                imagePath!,
                canShowPageLoadingIndicator: false,
                canShowScrollHead: false,
                canShowScrollStatus: false,
                onDocumentLoadFailed: (details) {
                  print('Error loading PDF: ${details.description}');
                },
              )
            : imagePath != null
                ? CachedNetworkImage(
                    imageUrl: imagePath!,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) {
                      print('Error loading image: $error'); // Log the error
                      return const Icon(Icons.error);
                    },
                  )
                : const SizedBox(), // Handle null imagePath
      ),
    );
  }

  TableRow _buildTableRow(String label, Widget widget) {
    return TableRow(
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8), // Reduced from 16
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600, // Increased font weight for boldness
              ),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8), // Reduced from 16
            child: widget,
          ),
        ),
      ],
    );
  }
}

