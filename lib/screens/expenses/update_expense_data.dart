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
  // Modern color scheme
  static const primaryColor = Color(0xFF2563EB);  // Modern blue
  static const surfaceColor = Color(0xFFF8FAFC);  // Light grey background
  static const textColor = Color(0xFF1E293B);     // Dark blue-grey text
  static const borderColor = Color(0xFFE2E8F0);   // Subtle border color
  static const successColor = Color(0xFF10B981);  // Modern green

  // Updated input decorations
  final InputDecoration modernInputDecoration = const InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: borderColor, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: borderColor, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: primaryColor, width: 2),
    ),
  );

  TextEditingController supplierController = TextEditingController();
  TextEditingController supplierSearchController = TextEditingController();
  TextEditingController refController = TextEditingController();
  TextEditingController totalController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController currencyController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController accountController = TextEditingController();
  TextEditingController accountSearchController = TextEditingController();
  TextEditingController paidFormController = TextEditingController();
  FocusNode keyboardFocusNode = FocusNode();

  String? imagePath;
  Widget? _publishButtonChild;

  final InputDecoration plainInputDecoration = const InputDecoration(
    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Adjusted padding
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    filled: true,
    fillColor: Colors.white,
    alignLabelWithHint: true,
    // Remove the constraints to allow dynamic height
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
  Map<String, dynamic>? selectedCard;
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

  List reviewExpenses = [];

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
    
    await getInvoiceById();
    await getSuppliers();
    await getPaymentAccounts();
    await getBankDetails();
    await getTaxRates();
    await getOrgCurrencies();

    setState(() {
      updatedExpense = expense;
      updatedExpense.remove('invoice_path');
      supplierController.text = expense['supplierName'] ?? '';
      selectedDate = DateTime.parse(expense['date']);
      dateController.text = DateFormat('dd MMM, yyyy').format(DateTime.parse(expense['date']));
      refController.text = expense['invoiceNumber'] ?? '';
      descriptionController.text = expense['invoiceLines'][0]['description'] ?? '';
      selectedAccount = paymentAccounts.firstWhere(
          (acc) => acc['id'] == expense['invoiceLines'][0]['accountId'],
          orElse: () => null);
      if (selectedAccount != null) {
          accountController.text = selectedAccount!['name'];
      }
      showSpinner = false;
    });
  }

  Future<void> getInvoiceById() async {
    final resp = await ApiService.getInvoiceById(widget.expense['id']);
    expense = resp;
    print('Expense: $expense');
  }

  Future<void> getPaymentAccounts() async {
    final resp = await ApiService.getPaymentAccounts(widget.selectedOrgId);
    if (resp.isNotEmpty) {
        setState(() {
            paymentAccounts = resp;
            filteredPaymentAccounts = resp;
        });
    }
  }

  Future<void> getBankDetails() async {
    final resp = await ApiService.getBankDetails(widget.selectedOrgId);
    if (resp.isNotEmpty && resp['status'] == 0) {
        setState(() {
            bankDetails = resp['data'];
        });

        // Try to find matching bank account based on selectedAccount['name']
        var matchingBank = bankDetails.firstWhere(
            (bankDetail) => bankDetail['name'] == selectedAccount?['name'],
            orElse: () => null,
        );

        if (matchingBank != null) {
            setState(() {
                selectedCard = matchingBank;
                paidFormController.text = matchingBank['name'];
                updatedExpense['paymentAccountNumber'] = matchingBank['accountID'];
            });
            print('Selected Card: $selectedCard');
        } else {
            print('No matching bank account found for selected account name: ${selectedAccount?['name']}');
        }
    }
    print('Bank Details Response: $resp');
  }

  Future<void> getTaxRates() async {
    final resp = await ApiService.getTaxRates(widget.selectedOrgId);
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
    final List resp = await ApiService.getOrgCurrencies(widget.selectedOrgId);
    if (resp.isNotEmpty) {
      currencies = resp;
    }
    selectedCurrency = expense['currency'] != null && expense['currency'].runtimeType == String ? expense['currency'] : currencies.first ?? 'USD';
    currencyController.text = selectedCurrency!;
    totalController.text = expense['amountDue'].toString();
  }

  Future<void> getSuppliers() async {
    suppliers.clear();
    filteredSuppliers.clear();
    final resp = await ApiService.getSuppliers(widget.selectedOrgId);
    if (resp.isNotEmpty) {
      suppliers = resp;
      if (suppliers.where((element) => element['name'] == expense['supplierName']).isNotEmpty) {
        selectedSupplier = suppliers.where((element) => element['name'] == expense['supplierName']).first;
      } else {
        filteredSuppliers.add({'name': "+ Add "+expense['supplierName']});
      }
      filteredSuppliers.addAll(resp);
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

  List<DropdownMenuItem<Map<String, dynamic>>> getBankDetailsDropdownItems() {
    return bankDetails.map((bankDetail) {
      return DropdownMenuItem<Map<String, dynamic>>(
        value: Map<String, dynamic>.from(bankDetail),
        child: Text(
          bankDetail['name']?.toString() ?? '',
          style: const TextStyle(
            fontSize: 14,
            overflow: TextOverflow.ellipsis,
          ),
          maxLines: 1,
        ),
      );
    }).toList();
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
    // print('Review Expenses Count: ${reviewExpenses.length}');
    return ModalProgressHUD(
      inAsyncCall: showSpinner,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          toolbarHeight: 100,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          backgroundColor: const Color(0XFFECECEC),
          leading: Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    navigatorKey.currentContext!,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(tabIndex: 0),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_back_ios),
              ),
            ],
          ),
          title: const SizedBox(height: 10),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(150),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: widget.imagePath != null
                  ? SizedBox(
                      height: 200,
                      child: GestureDetector(
                        onTap: () {
                          showGeneralDialog(
                            barrierDismissible: false,
                            context: context,
                            pageBuilder: (context, animation, secondaryAnimation) =>
                                Container(
                              color: Colors.white,
                              padding: EdgeInsets.zero,
                              width: 100,
                              height: 200,
                              child: Stack(
                                children: [
                                  widget.imagePath!.toLowerCase().endsWith('.pdf')
                                      ? SfPdfViewer.network(widget.imagePath!)
                                      : PhotoView(
                                          imageProvider: CachedNetworkImageProvider(
                                              widget.imagePath!),
                                        ),
                                  Positioned(
                                    top: 50,
                                    left: 10,
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.grey.shade400,
                                        child: IconButton(
                                          icon: const Icon(Icons.close,
                                              color: Colors.white),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: CachedNetworkImage(
                          imageUrl: widget.imagePath!,
                          errorWidget: (context, url, error) {
                            return SfPdfViewer.network(widget.imagePath!);
                          },
                        ),
                      ),
                    )
                  : Container(height: 200),
            ),
          ),
          actions: [
            if (!widget.isProcessed!)
              IconButton(
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
                icon: const Icon(Icons.delete, color: Colors.black),
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Table(
                    columnWidths: const {
                      0: FixedColumnWidth(120),
                      1: FlexColumnWidth(),
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
                      _buildTableRow("Details", Align(alignment: Alignment.centerLeft, child: _buildDescriptionWidget())),
                      _buildTableRow("Total", Align(alignment: Alignment.topLeft, child: Column(
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
              ],
            ),
          ),
        ),
        bottomNavigationBar: widget.isProcessed == false
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: _buildPublishButton(),
              )
            : null,
      ),
    );
  }

  /// A helper method to build a single row with a label on the left and a widget on the right.
  Widget _buildRow(String label, Widget widgetOnRight) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        // Label with fixed width, adjusted to give more space to the right
        SizedBox(
          width: 100, // Adjusted width to move the label left
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10), // Optional: Adjust spacing between label and value
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
        maxLines: null,
        minLines: 1,
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
              maxLines: null,
              minLines: 1,
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
      maxLines: null,
      minLines: 1,
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
      maxLines: null,
      minLines: 1,
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
        maxLines: null,
        minLines: 1,
        onChanged: (value) {
            // Update the invoice number in the updatedExpense map when the text changes
            updatedExpense['invoiceNumber'] = value;
        },
        onEditingComplete: () async {
            FocusManager.instance.primaryFocus?.unfocus();
            final resp = await ApiService.updateExpense(updatedExpense);
            setState(() {
                showSpinner = false;
            });
            if (resp.isNotEmpty) {
                ScaffoldMessenger.of(navigatorKey.currentContext!)
                    .showSnackBar(const SnackBar(content: Text('Updated successfully.')));
            } else {
                ScaffoldMessenger.of(navigatorKey.currentContext!)
                    .showSnackBar(const SnackBar(content: Text('Failed to update.')));
            }
        },
        onTapOutside: (cb) async {
            // Call the update function when the user taps outside
            updatedExpense['invoiceNumber'] = refController.text;
            FocusManager.instance.primaryFocus?.unfocus();
            final resp = await ApiService.updateExpense(updatedExpense);
            setState(() {
                showSpinner = false;
            });
            if (resp.isNotEmpty) {
                ScaffoldMessenger.of(navigatorKey.currentContext!)
                    .showSnackBar(const SnackBar(content: Text('Updated successfully.')));
            } else {
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
        // Add contentPadding to ensure text doesn't overlap with the dropdown icon
        contentPadding: const EdgeInsets.fromLTRB(8, 4, 40, 4),
      ),
      maxLines: 1,
      onTap: _showAccountBottomSheet,
      textAlign: TextAlign.left,
      style: const TextStyle(
        overflow: TextOverflow.ellipsis,
      ),
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
    return SizedBox(
        height: 40,
        child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
                hint: const Text(
                    'Select Payment Account',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        overflow: TextOverflow.ellipsis,
                    ),
                ),
                value: selectedCard?['accountID'], // Use accountID from selectedCard
                isExpanded: true,
                items: bankDetails.map((bankDetail) {
                    return DropdownMenuItem<String>(
                        value: bankDetail['accountID'], // Use accountID as the value
                        child: Text(
                            bankDetail['name']?.toString() ?? '',
                            style: const TextStyle(
                                fontSize: 14,
                                overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                        ),
                    );
                }).toList(),
                onChanged: (String? newValue) async {
                    if (newValue != null) {
                        setState(() {
                            selectedCard = bankDetails.firstWhere((bd) => bd['accountID'] == newValue); // Find the selected card
                            showSpinner = true;
                        });
                        
                        updatedExpense['paymentAccountNumber'] = selectedCard?['accountID'];
                        final resp = await ApiService.updateExpense(updatedExpense);
                        
                        setState(() {
                            showSpinner = false;
                        });
                        
                        if (resp.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Updated successfully.')),
                            );
                        } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to update.')),
                            );
                        }
                    }
                },
                buttonStyleData: const ButtonStyleData(
                    height: 40,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.zero,
                    ),
                ),
                dropdownStyleData: const DropdownStyleData(
                    maxHeight: 200,
                    decoration: BoxDecoration(
                        color: Colors.white,
                    ),
                ),
                menuItemStyleData: const MenuItemStyleData(
                    height: 40,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                ),
            ),
        ),
    );
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
        maxLines: null, // Allow unlimited lines
        minLines: 1, // Start with one line
        onChanged: (text) {
            // Update the description in the updatedExpense map when the text changes
            updatedExpense['description'] = text;
        },
        onEditingComplete: () async {
            FocusManager.instance.primaryFocus?.unfocus();
            print('Updating description with: ${updatedExpense['description']}'); // Log the description being updated
            final resp = await ApiService.updateExpense(updatedExpense);
            setState(() {
                showSpinner = false;
            });
            if (resp.isNotEmpty) {
                print('Description updated successfully: $resp'); // Debug log
                ScaffoldMessenger.of(navigatorKey.currentContext!)
                    .showSnackBar(const SnackBar(content: Text('Updated successfully.')));
            } else {
                print('Failed to update description: $resp'); // Debug log
                ScaffoldMessenger.of(navigatorKey.currentContext!)
                    .showSnackBar(const SnackBar(content: Text('Failed to update.')));
            }
        },
        onTapOutside: (cb) async {
            // Call the update function when the user taps outside
            updatedExpense['description'] = descriptionController.text;
            FocusManager.instance.primaryFocus?.unfocus();
            print('Updating description on tap outside with: ${updatedExpense['description']}'); // Log the description being updated
            final resp = await ApiService.updateExpense(updatedExpense);
            setState(() {
                showSpinner = false;
            });
            if (resp.isNotEmpty) {
                print('Description updated successfully on tap outside: $resp'); // Debug log
                ScaffoldMessenger.of(navigatorKey.currentContext!)
                    .showSnackBar(const SnackBar(content: Text('Updated successfully.')));
            } else {
                print('Failed to update description on tap outside: $resp'); // Debug log
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
                                    // Update the amount due in the updatedExpense map
                                    updatedExpense['invoiceLines'][0]['amountDue'] =
                                        double.parse(totalController.text);
                                    updatedExpense['amountDue'] = double.parse(totalController.text);
                                    
                                    // Call the API to update the expense
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
            maxLines: null,
            minLines: 1,
            textAlign: TextAlign.left,
            onChanged: (value) {
                // Update the amount due in the updatedExpense map when the text changes
                updatedExpense['invoiceLines'][0]['amountDue'] = double.tryParse(value) ?? 0.0;
            },
        ),
    );
  }

  /// Tax chip row
  Widget _buildTaxChipRow() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0XFFF2FFF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0XFF009318), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center, // Align items center vertically
        children: [
          // Left side: Tax Rate information
          Expanded( // Wrap in Expanded to prevent overflow
            child: Text(
              selectedTaxRate?['name'] ?? 'No tax',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis, // Handle overflow
            ),
          ),
          // Right side: Amount and edit icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.expense['currency'] is String ? NumberFormat().simpleCurrencySymbol(widget.expense['currency']) : ''}${_calculateTaxAmount().toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (!widget.isProcessed!) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _showTaxDialog(context), // Use local context
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0XFF009318).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Color(0XFF009318),
                      size: 16,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  double _calculateTaxAmount() {
    if (selectedTaxRate != null && widget.expense['totalTax'] == 0) {
      return widget.expense['amountDue'] * (selectedTaxRate!['rate'] / 100);
    } else {
      return widget.expense['totalTax'].toDouble();
    }
  }

  void _showTaxDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        insetPadding: const EdgeInsets.all(10),
        backgroundColor: Colors.white,
        title: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: const Color(0XFFF9FAFB),
          ),
          height: MediaQuery.of(ctx).size.height * 0.075,
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
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.all(10),
        content: StatefulBuilder(
          builder: (ctx, setState) => Container(
            color: Colors.white,
            height: MediaQuery.of(ctx).size.height * 0.3,
            width: MediaQuery.of(ctx).size.width * 0.95,
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
                        MediaQuery.of(ctx).size.width,
                        MediaQuery.of(ctx).size.height * 0.06,
                      ),
                      backgroundColor: const Color(0XFF009318),
                    ),
                    onPressed: () async {
                      setState(() {
                        showSpinner = true;
                      });
                      updatedExpense['invoiceLines'][0]['taxId'] = selectedTaxRate?['id'];
                      double subTotal = updatedExpense['amountDue'] -
                          (updatedExpense['amountDue'] * ((selectedTaxRate?['rate'] ?? 0) / 100));
                      double totalTax = updatedExpense['amountDue'] * ((selectedTaxRate?['rate'] ?? 0) / 100);
                      updatedExpense['totalTax'] = totalTax;
                      updatedExpense['subTotal'] = subTotal;
                      updatedExpense['invoiceLines'][0]['subTotal'] = subTotal;
                      updatedExpense['invoiceLines'][0]['totalTax'] = totalTax;
                      final resp = await ApiService.updateExpense(updatedExpense);
                      setState(() {
                        showSpinner = false;
                      });
                      if (resp.isNotEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Updated successfully.')),
                        );
                      } else {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Failed to update.')),
                        );
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
                    Navigator.pop(ctx);
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
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        fixedSize: Size(MediaQuery.of(context).size.width, 50),
        backgroundColor: const Color(0XFF009318),
      ),
      child: _publishButtonChild ?? const Text(
        'Publish',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
      ),
    );
  }

  Future<void> _handlePublish() async {
    // Initialize a list to hold the names of empty fields
    List<String> emptyFields = [];

    // Validate required fields
    if (selectedCard == null) {
        emptyFields.add('Payment Account');
    }
    if (selectedSupplier == null) {
        emptyFields.add('Supplier');
    }
    if (updatedExpense['invoiceLines'][0]['amountDue'] == null) {
        emptyFields.add('Total Amount Due');
    }
    if (updatedExpense['date'] == null) {
        emptyFields.add('Date');
    }

    // If there are any empty fields, show a message
    if (emptyFields.isNotEmpty) {
        String fields = emptyFields.join(', ');
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            SnackBar(content: Text('Please fill in the following fields: $fields.')));
        return; // Exit the function if validation fails
    }

    setState(() {
        showSpinner = true;
        _publishButtonChild = const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        );
    });

    // Construct the receipt map
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
        'contact': {
            "contactID": selectedSupplier?['id'],
            "name": selectedSupplier?['name'],
            "status": "ACTIVE"
        },
        'date': updatedExpense['date'],
        'invoiceId': updatedExpense['id'],
        'invoiceNumber': updatedExpense['invoiceNumber'],
        "InvoiceOrCreditNote": updatedExpense['type'],
        'lineAmountTypes': 'Exclusive',
        'lineItems': updatedExpense['invoiceLines'],
        'OrganisationId': widget.selectedOrgId,
        'paymentAccountNumber': updatedExpense['paymentAccountNumber'],
        'paymentDate': updatedExpense['paymentDate'],
        'paymentStatus': updatedExpense['type'] == 'Receipt' ? 1 : 0,
        'PdfUrl': updatedExpense['pdfUrl'],
        'status': 'AUTHORISED',
        'subTotal': updatedExpense['subTotal'],
        'total': updatedExpense['amountDue'],
        'totalTax': updatedExpense['totalTax'],
        'type': updatedExpense['type'],
        "unreconciledReportIds": ""
    };

    // Your existing logic to publish the receipt
    final resp = await ApiService.publishReceipt(receipt);

    if (resp.isNotEmpty) {
        setState(() {
            _publishButtonChild = Lottie.asset(
                'assets/animations/success.json', // Ensure you have a success animation JSON file
                width: 50,
                height: 50,
                repeat: false,
            );
        });

        // Delay to show the success animation
        await Future.delayed(const Duration(seconds: 2));

        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            const SnackBar(content: Text('Published successfully.')),
        );
        Navigator.push(
            navigatorKey.currentContext!,
            MaterialPageRoute(builder: (context) => const HomeScreen(tabIndex: 0)),
        );
    } else {
        setState(() {
            _publishButtonChild = const Text(
                'Publish',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
            );
            showSpinner = false;
        });
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            const SnackBar(content: Text('We were unable to publish the expense, please try again.')),
        );
    }
  }

  TableRow _buildTableRow(String label, Widget widgetOnRight) {
    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle, // Change to middle
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle, // Change to middle
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: widgetOnRight,
          ),
        ),
      ],
    );
  }
}
