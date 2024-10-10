import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf_render/pdf_render_widgets.dart';
import 'package:synced/main.dart';
import 'package:synced/screens/expenses/create_expense.dart';
import 'package:synced/utils/api_services.dart';
import 'package:synced/utils/constants.dart';

Widget getExpensesWidget(BuildContext context, List reviewExpenses,
    List processedExpenses, showSpinner, setState, tabController) {
  Widget noExpenseWidget = Center(
    child: Column(
      children: [
        const SizedBox(height: 30),
        Image.asset('assets/no-expense.png',
            height: MediaQuery.of(context).size.height * 0.25),
        const SizedBox(height: 30),
        const Text('No expenses yet!',
            style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const Text('Scan receipt to add your expense record here',
            style: TextStyle(
                color: Color(0XFF667085),
                fontSize: 14,
                fontWeight: FontWeight.w400)),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const CreateExpense())),
          style: ButtonStyle(
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0))),
              fixedSize: WidgetStateProperty.all(Size(
                  MediaQuery.of(context).size.width * 0.8,
                  MediaQuery.of(context).size.height * 0.05)),
              backgroundColor: WidgetStateProperty.all(clickableColor)),
          child: const Text('Scan now', style: TextStyle(color: Colors.white)),
        )
      ],
    ),
  );

  Widget getPageContent() {
    TextEditingController reviewSearchController = TextEditingController();
    TextEditingController processedSearchController = TextEditingController();

    if (reviewExpenses.isEmpty && processedExpenses.isEmpty) {
      return noExpenseWidget;
    }
    if (tabController.index == 0) {
      return Container(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xfff3f3f3),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide:
                          BorderSide(color: Colors.transparent, width: 0)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide:
                          BorderSide(color: Colors.transparent, width: 0)),
                  focusColor: Color(0XFF8E8E8E),
                  hintText: 'Search here',
                  prefixIcon: Icon(Icons.search),
                  prefixIconColor: Color(0XFF8E8E8E)),
              onEditingComplete: () async {
                setState(() {
                  showSpinner = true;
                });
                final resp = await ApiService.getExpenses(
                    false, selectedOrgId, reviewSearchController.text);
                if (resp.isNotEmpty) {
                  reviewExpenses = resp['invoices'];
                }

                for (var exp in reviewExpenses) {
                  final invoiceResp = await ApiService.downloadInvoice(
                      exp['invoicePdfUrl'], selectedOrgId);
                  setState(() {
                    exp['invoice_path'] = invoiceResp['path'];
                  });
                  if (kDebugMode) {
                    print(invoiceResp);
                  }
                }
                setState(() {
                  showSpinner = false;
                });
              },
              controller: reviewSearchController,
            ),
            const SizedBox(height: 10),
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: reviewExpenses.length,
                    itemBuilder: (context, index) {
                      bool isSameDate = true;
                      final String dateString = reviewExpenses[index]['date'];
                      final DateTime date = DateTime.parse(dateString);
                      final item = reviewExpenses[index];
                      if (index == 0) {
                        isSameDate = false;
                      } else {
                        final String prevDateString =
                            reviewExpenses[index - 1]['date'];
                        final DateTime prevDate =
                            DateTime.parse(prevDateString);
                        isSameDate = date.isSameDate(prevDate);
                      }
                      if (index == 0 || !(isSameDate)) {
                        return Column(children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Expanded(child: Divider()),
                              Text(' ${date.formatDate()} ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12,
                                      color: Color(0XFF667085))),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Card(
                            color: Colors.white,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  item['invoice_path'] != null
                                      ? SizedBox(
                                          height: 75,
                                          width: 75,
                                          child: PdfViewer.openFile(
                                              item['invoice_path']))
                                      : CircularProgressIndicator(
                                          color: clickableColor,
                                        ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item['supplierName'],
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0XFF344054))),
                                      Align(
                                        alignment: Alignment.topCenter,
                                        child: Text(
                                            'Due: ${DateFormat('d MMM, y').format(DateTime.parse(item['dueDate'])).toString()}'),
                                      ),
                                      if (item['accountName'] != null) ...[
                                        Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Chip(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(24)),
                                            side: BorderSide(
                                              color: clickableColor,
                                            ),
                                            label: Text(item['accountName']),
                                            color: const WidgetStatePropertyAll(
                                                Color(0XFFFFFEF4)),
                                            labelStyle: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0XFF667085)),
                                          ),
                                        )
                                      ]
                                    ],
                                  ),
                                  Text(
                                    '${NumberFormat().simpleCurrencySymbol(item['currency'])}${item['amountDue']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: Color(0XFF101828)),
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ]);
                      } else {
                        return Column(children: [
                          Card(
                            color: Colors.white,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  item['invoice_path'] != null
                                      ? SizedBox(
                                          height: 75,
                                          width: 75,
                                          child: PdfViewer.openFile(
                                              item['invoice_path']))
                                      : CircularProgressIndicator(
                                          color: clickableColor,
                                        ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item['supplierName'],
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0XFF344054))),
                                      Align(
                                        alignment: Alignment.topCenter,
                                        child: Text(
                                            'Due: ${DateFormat('d MMM, y').format(DateTime.parse(item['dueDate'])).toString()}'),
                                      ),
                                      if (item['accountName'] != null) ...[
                                        Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Chip(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(24)),
                                            side: BorderSide(
                                              color: clickableColor,
                                            ),
                                            label: Text(item['accountName']),
                                            color: const WidgetStatePropertyAll(
                                                Color(0XFFFFFEF4)),
                                            labelStyle: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0XFF667085)),
                                          ),
                                        )
                                      ]
                                    ],
                                  ),
                                  Text(
                                    '${NumberFormat().simpleCurrencySymbol(item['currency'])}${item['amountDue']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: Color(0XFF101828)),
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ]);
                      }
                    }))
          ],
        ),
      );
    } else if (tabController.index == 1) {
      return Container(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xfff3f3f3),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide:
                          BorderSide(color: Colors.transparent, width: 0)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide:
                          BorderSide(color: Colors.transparent, width: 0)),
                  focusColor: Color(0XFF8E8E8E),
                  hintText: 'Search here',
                  prefixIcon: Icon(Icons.search),
                  prefixIconColor: Color(0XFF8E8E8E)),
              onEditingComplete: () async {
                setState(() {
                  showSpinner = true;
                });
                final resp = await ApiService.getExpenses(
                    true, selectedOrgId, processedSearchController.text);
                if (resp.isNotEmpty) {
                  processedExpenses = resp['invoices'];
                }

                for (var exp in processedExpenses) {
                  final invoiceResp = await ApiService.downloadInvoice(
                      exp['invoicePdfUrl'], selectedOrgId);
                  setState(() {
                    exp['invoice_path'] = invoiceResp['path'];
                  });
                  if (kDebugMode) {
                    print(invoiceResp);
                  }
                }

                setState(() {
                  showSpinner = false;
                });
              },
              controller: processedSearchController,
            ),
            const SizedBox(height: 10),
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: processedExpenses.length,
                    itemBuilder: (context, index) {
                      bool isSameDate = true;
                      final String dateString =
                          processedExpenses[index]['date'];
                      final DateTime date = DateTime.parse(dateString);
                      final item = processedExpenses[index];
                      if (index == 0) {
                        isSameDate = false;
                      } else {
                        final String prevDateString =
                            processedExpenses[index - 1]['date'];
                        final DateTime prevDate =
                            DateTime.parse(prevDateString);
                        isSameDate = date.isSameDate(prevDate);
                      }
                      if (index == 0 || !(isSameDate)) {
                        return Column(children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Expanded(child: Divider()),
                              Text(' ${date.formatDate()} ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12,
                                      color: Color(0XFF667085))),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Card(
                            color: Colors.white,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  item['invoice_path'] != null
                                      ? SizedBox(
                                          height: 75,
                                          width: 75,
                                          child: PdfViewer.openFile(
                                              item['invoice_path']))
                                      : CircularProgressIndicator(
                                          color: clickableColor,
                                        ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item['supplierName'],
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0XFF344054))),
                                      Align(
                                        alignment: Alignment.topCenter,
                                        child: Text(
                                            'Due: ${DateFormat('d MMM, y').format(DateTime.parse(item['dueDate'])).toString()}'),
                                      ),
                                      if (item['accountName'] != null) ...[
                                        Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Chip(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(24)),
                                            side: BorderSide(
                                              color: clickableColor,
                                            ),
                                            label: Text(item['accountName']),
                                            color: const WidgetStatePropertyAll(
                                                Color(0XFFFFFEF4)),
                                            labelStyle: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0XFF667085)),
                                          ),
                                        )
                                      ]
                                    ],
                                  ),
                                  Text(
                                    '${NumberFormat().simpleCurrencySymbol(item['currency'])}${item['amountDue']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: Color(0XFF101828)),
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ]);
                      } else {
                        return Column(children: [
                          Card(
                            color: Colors.white,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  item['invoice_path'] != null
                                      ? SizedBox(
                                          height: 75,
                                          width: 75,
                                          child: PdfViewer.openFile(
                                              item['invoice_path']))
                                      : CircularProgressIndicator(
                                          color: clickableColor,
                                        ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item['supplierName'],
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0XFF344054))),
                                      Align(
                                        alignment: Alignment.topCenter,
                                        child: Text(
                                            'Due: ${DateFormat('d MMM, y').format(DateTime.parse(item['dueDate'])).toString()}'),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${NumberFormat().simpleCurrencySymbol(item['currency'])}${item['amountDue']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: Color(0XFF101828)),
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ]);
                      }
                    }))
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  return Center(
      child: Container(
    color: const Color(0xfffbfbfb),
    child: getPageContent(),
  ));
}

const String dateFormatter = "d MMMM y";

extension DateHelper on DateTime {
  String formatDate() {
    final formatter = DateFormat(dateFormatter);
    return formatter.format(this);
  }

  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  int getDifferenceInDaysWithNow() {
    final now = DateTime.now();
    return now.difference(this).inDays;
  }
}
