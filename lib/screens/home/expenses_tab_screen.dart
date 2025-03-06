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

// Define the DateTime extension for formatDate and isSameDate
extension DateHelper on DateTime {
  String formatDate() {
    final formatter = DateFormat("d MMMM y"); // Format the date as "d MMMM y"
    return formatter.format(this);
  }

  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

class ExpensesTabScreen extends StatefulWidget {
  final TabController tabController;
  final PagingController reviewPagingController, processedPagingController;
  final List reviewExpenses, processedExpenses;
  final bool showSpinner;
  const ExpensesTabScreen(
      {super.key,
        required this.tabController,
        required this.reviewPagingController,
        required this.processedPagingController,
        required this.reviewExpenses,
        required this.processedExpenses,
        required this.showSpinner});

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
                  fontSize: 16, // Font size increased by 20%
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
            child: const Text('Scan now', style: TextStyle(color: Colors.white)),
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
        elevation: 6, // Increased elevation for shadow effect
        shadowColor: Colors.grey,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15), // Increased padding
          child: Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.25, // Adjusted width
                child: item['invoice_path'] != null
                    ? SizedBox(
                    height: MediaQuery.of(context).size.width * 0.25, // Increased image size
                    width: MediaQuery.of(context).size.width * 0.25,  // Increased image size
                    child: getInvoiceWidget(item))
                    : appLoader,
              ),
              const SizedBox(width: 15), // Increased space between image and text
              Expanded(  // Wrap the column in Expanded to prevent overflow
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(  // Use Expanded for the supplier name text to prevent overflow
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: item['supplierName'] != null
                                ? Text(item['supplierName'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 16, // Font size increased by 20%
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0XFF344054)))
                                : SizedBox(width: MediaQuery.of(context).size.width * 0.375),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.25, // Adjusted width for amount
                          child: Align(
                            alignment: Alignment.topRight,
                            child: FittedBox(
                              fit: BoxFit.fitWidth,
                              child: Text(
                                item['amountDue'] != null
                                    ? f.format(item['amountDue'])
                                    : "",
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14, // Font size increased by 20%
                                    color: const Color(0XFF101828)),
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
                          padding: const EdgeInsets.fromLTRB(2, 12, 2, 12), // Adjusted padding
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100)),
                          side: BorderSide(
                            color: clickableColor, // clickableColor should now work
                          ),
                          label: Text(item['accountName'],
                              style: const TextStyle(
                                  fontSize: 12, // Increased font size by 20%
                                  fontWeight: FontWeight.w500)),
                          color: const WidgetStatePropertyAll(Color(0XFFFFFEF4)),
                          labelStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }


    Widget getPageContent() {
      if (showSpinner || widget.showSpinner) {
        return appLoader;
      } else if (widget.reviewExpenses.isEmpty &&
          widget.processedExpenses.isEmpty &&
          !showUploadingInvoice &&
          reviewSearchController.text.isEmpty &&
          processedSearchController.text.isEmpty) {
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
                    height: 50,
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
                              fontSize: 16, // Font size increased by 20%
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
                      onEditingComplete: () async {
                        if (reviewSearchController.text != reviewSearchTerm) {
                          setState(() {
                            reviewSearchTerm = reviewSearchController.text;
                          });
                          widget.reviewPagingController.refresh();
                        }
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      controller: reviewSearchController,
                    )),
                const SizedBox(height: 10),
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
                                                fontSize: 20, // Increased font size
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
                                      height: 120, // Increased height of the card
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
                                      height: 120, // Increased height of the card
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
        ],
      );
    }

    return getPageContent();
  }
}

