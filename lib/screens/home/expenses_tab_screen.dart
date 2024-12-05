import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_debouncer/flutter_debouncer.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:synced/main.dart';
import 'package:synced/screens/expenses/update_expense_data.dart';
import 'package:synced/screens/home/home_screen.dart';
import 'package:synced/utils/constants.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ExpensesTabScreen extends StatefulWidget {
  final TabController tabController;
  final PagingController reviewPagingController, processedPagingController;
  final List reviewExpenses, processedExpenses;
  const ExpensesTabScreen(
      {super.key,
      required this.tabController,
      required this.reviewPagingController,
      required this.processedPagingController,
      required this.reviewExpenses,
      required this.processedExpenses});

  @override
  State<ExpensesTabScreen> createState() => _ExpensesTabScreenState();
}

class _ExpensesTabScreenState extends State<ExpensesTabScreen>
    with SingleTickerProviderStateMixin {
  bool showSpinner = false;
  final Debouncer reviewDebouncer = Debouncer();
  final Debouncer processedDebouncer = Debouncer();
  ScrollController reviewScrollController = ScrollController();
  ScrollController processedScrollController = ScrollController();

  @override
  void dispose() {
    reviewScrollController.dispose();
    processedScrollController.dispose();
    reviewDebouncer.cancel();
    processedDebouncer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget noExpenseWidget = Center(
      child: Column(
        children: [
          const SizedBox(height: 30),
          Image.asset('assets/no-expense.png',
              height: MediaQuery.of(navigatorKey.currentContext!).size.height *
                  0.25),
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
            onPressed: () => Navigator.pushReplacement(
                navigatorKey.currentContext!,
                MaterialPageRoute(
                    builder: (context) => const HomeScreen(tabIndex: 0))),
            style: ButtonStyle(
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0))),
                fixedSize: WidgetStateProperty.all(Size(
                    MediaQuery.of(navigatorKey.currentContext!).size.width *
                        0.8,
                    MediaQuery.of(navigatorKey.currentContext!).size.height *
                        0.06)),
                backgroundColor: WidgetStateProperty.all(clickableColor)),
            child:
                const Text('Scan now', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );

    Widget getInvoiceWidget(Map matchData) {
      late Widget invoiceImage;
      invoiceImage = CachedNetworkImage(
        imageUrl: matchData['invoice_path'],
        errorWidget: (context, url, error) {
          return SfPdfViewer.network(matchData['invoice_path'],
              canShowPageLoadingIndicator: false,
              canShowScrollHead: false,
              canShowScrollStatus: false);
        },
      );
      return invoiceImage;
    }

    Widget getInvoiceCardWidget(item) {
      var f = NumberFormat("###,###.##", "en_US");

      return Card(
        elevation: 4,
        shadowColor: Colors.grey,
        color: Colors.white,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.all(5),
          child: Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.2,
                child: item['invoice_path'] != null
                    ? SizedBox(
                        height: MediaQuery.of(context).size.width * 0.2,
                        width: MediaQuery.of(context).size.width * 0.2,
                        child: getInvoiceWidget(item))
                    : appLoader,
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.45,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: item['supplierName'] != null
                              ? Text(item['supplierName'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0XFF344054)))
                              : SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.375),
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.2,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: FittedBox(
                            fit: BoxFit.fitWidth,
                            child: Text(
                              item['amountDue'] != null
                                  ? f.format(item['amountDue'])
                                  : "",
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0XFF101828)),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  if (item['accountName'] != null) ...[
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Chip(
                        padding: const EdgeInsets.fromLTRB(2, 10, 2, 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100)),
                        side: BorderSide(
                          color: clickableColor,
                        ),
                        label: Text(item['accountName']),
                        color: const WidgetStatePropertyAll(Color(0XFFFFFEF4)),
                        labelStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0XFF667085)),
                      ),
                    )
                  ]
                ],
              ),
            ],
          ),
        ),
      );
    }

    Widget getPageContent() {
      if (widget.reviewExpenses.isEmpty &&
          widget.processedExpenses.isEmpty &&
          !showUploadingInvoice) {
        return noExpenseWidget;
      }

      return TabBarView(
        controller: widget.tabController,
        children: [
          Container(
            color: const Color(0xfffbfbfb),
            padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
            height: MediaQuery.of(context).size.height * 0.8,
            width: double.maxFinite,
            child: Column(
              children: [
                SizedBox(
                    height: 48,
                    child: TextFormField(
                      decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xfff3f3f3),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                              borderSide:
                                  const BorderSide(color: Colors.transparent)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                              borderSide:
                                  const BorderSide(color: Colors.transparent)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                              borderSide:
                                  const BorderSide(color: Colors.transparent)),
                          focusColor: const Color(0XFF8E8E8E),
                          hintText: 'Search',
                          hintStyle: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Color(0XFF8E8E8E)),
                          prefixIcon: const Icon(Icons.search),
                          prefixIconColor: const Color(0XFF8E8E8E)),
                      onChanged: (value) async {
                        reviewDebouncer.debounce(
                            duration: const Duration(milliseconds: 250),
                            onDebounce: () {
                              setState(() {
                                reviewSearchTerm = value;
                              });
                              widget.reviewPagingController.refresh();
                            });
                      },
                      controller: reviewSearchController,
                    )),
                const SizedBox(height: 10),
                if (showUploadingInvoice) ...[
                  SizedBox(
                    height: 100,
                    child: Card(
                      color: Colors.white,
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.only(
                            top: 5, left: 10, right: 5, bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(
                                height: 75,
                                width: 75,
                                child: uploadingData['path'] != null
                                    ? Image.file(File(uploadingData['path']))
                                    : appLoader),
                            const SizedBox(width: 20),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Chip(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(100)),
                                        side: const BorderSide(
                                          color: Color(0XFFF6CA58),
                                        ),
                                        backgroundColor:
                                            const Color(0XFFFFFEF4),
                                        label: const Text('Processing',
                                            style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0XFF667085))),
                                      ),
                                    ),
                                    SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.25),
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: Text(
                                          uploadingData['size'] ?? '0.77Mb',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontSize: 10,
                                              color: Color(0XFF667085))),
                                    )
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  child: Center(
                                    child: LinearProgressIndicator(
                                        minHeight: 6,
                                        value: uploadingData['uploadProgress'],
                                        valueColor: AlwaysStoppedAnimation(
                                            clickableColor)),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Expanded(
                    flex: showUploadingInvoice ? 5 : 8,
                    child: PagedListView(
                        shrinkWrap: true,
                        pagingController: widget.reviewPagingController,
                        scrollController: reviewScrollController,
                        physics: widget.tabController.index == 0
                            ? const AlwaysScrollableScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        builderDelegate: PagedChildBuilderDelegate(
                            itemBuilder: (context, item, index) {
                          bool isSameDate = true;
                          DateTime? date;
                          final item = widget.reviewExpenses[index];
                          if (index == 0) {
                            isSameDate = false;
                          }
                          if (widget.reviewExpenses[index]['date'] != null) {
                            final String dateString =
                                widget.reviewExpenses[index]['date'];
                            date = DateTime.parse(dateString);
                            if (index == 0) {
                              isSameDate = false;
                            } else if (widget.reviewExpenses[index - 1]
                                    ['date'] !=
                                null) {
                              final String prevDateString =
                                  widget.reviewExpenses[index - 1]['date'];
                              final DateTime prevDate =
                                  DateTime.parse(prevDateString);
                              isSameDate = date.isSameDate(prevDate);
                            }
                          }
                          if (index == 0 || !(isSameDate)) {
                            return Column(children: [
                              if (widget.reviewExpenses[index]['date'] !=
                                  null) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Expanded(child: Divider()),
                                    Text(' ${date?.formatDate()} ',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 12,
                                            color: Color(0XFF667085))),
                                    const Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: 10)
                              ],
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      navigatorKey.currentContext!,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              UpdateExpenseData(
                                                  expense: item,
                                                  imagePath:
                                                      item['invoice_path'],
                                                  isProcessed: false)));
                                },
                                child: SizedBox(
                                  height: 100,
                                  child: getInvoiceCardWidget(item),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ]);
                          } else {
                            return Column(children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      navigatorKey.currentContext!,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              UpdateExpenseData(
                                                  expense: item,
                                                  imagePath:
                                                      item['invoice_path'],
                                                  isProcessed: false)));
                                },
                                child: SizedBox(
                                  height: 100,
                                  child: getInvoiceCardWidget(item),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ]);
                          }
                        })))
              ],
            ),
          ),
          Container(
            color: const Color(0xfffbfbfb),
            padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
            height: MediaQuery.of(context).size.height * 0.8,
            width: double.maxFinite,
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: TextField(
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xfff3f3f3),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                            borderSide:
                                const BorderSide(color: Colors.transparent)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                            borderSide:
                                const BorderSide(color: Colors.transparent)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                            borderSide:
                                const BorderSide(color: Colors.transparent)),
                        focusColor: const Color(0XFF8E8E8E),
                        hintText: 'Search',
                        hintStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Color(0XFF8E8E8E)),
                        prefixIcon: const Icon(Icons.search),
                        prefixIconColor: const Color(0XFF8E8E8E)),
                    onChanged: (value) async {
                      processedDebouncer.debounce(
                          duration: const Duration(milliseconds: 250),
                          onDebounce: () {
                            setState(() {
                              processedSearchTerm = value;
                            });
                            widget.processedPagingController.refresh();
                          });
                    },
                    onEditingComplete: () async {
                      if (processedSearchController.text !=
                          processedSearchTerm) {
                        setState(() {
                          processedSearchTerm = processedSearchController.text;
                        });
                        widget.processedPagingController.refresh();
                      }
                    },
                    controller: processedSearchController,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                    child: PagedListView(
                        shrinkWrap: true,
                        pagingController: widget.processedPagingController,
                        scrollController: processedScrollController,
                        physics: widget.tabController.index == 1
                            ? const AlwaysScrollableScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        builderDelegate: PagedChildBuilderDelegate(
                            itemBuilder: (context, item, index) {
                          bool isSameDate = true;
                          final String dateString =
                              widget.processedExpenses[index]['date'];
                          final DateTime date = DateTime.parse(dateString);
                          final item = widget.processedExpenses[index];
                          if (index == 0) {
                            isSameDate = false;
                          } else {
                            final String prevDateString =
                                widget.processedExpenses[index - 1]['date'];
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
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      navigatorKey.currentContext!,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              UpdateExpenseData(
                                                  expense: item,
                                                  imagePath:
                                                      item['invoice_path'],
                                                  isProcessed: true)));
                                },
                                child: SizedBox(
                                  height: 100,
                                  child: getInvoiceCardWidget(item),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ]);
                          } else {
                            return Column(children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      navigatorKey.currentContext!,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              UpdateExpenseData(
                                                  expense: item,
                                                  imagePath:
                                                      item['invoice_path'],
                                                  isProcessed: true)));
                                },
                                child: SizedBox(
                                  height: 100,
                                  child: getInvoiceCardWidget(item),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ]);
                          }
                        })))
              ],
            ),
          )
        ],
      );
    }

    return getPageContent();
  }
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
