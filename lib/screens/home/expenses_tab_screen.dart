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
import 'package:lottie/lottie.dart';

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
  final String selectedOrgId;
  const ExpensesTabScreen(
      {super.key,
        required this.tabController,
        required this.reviewPagingController,
        required this.processedPagingController,
        required this.reviewExpenses,
        required this.processedExpenses,
        required this.showSpinner,
        required this.selectedOrgId});

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
  void didUpdateWidget(covariant ExpensesTabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedOrgId != widget.selectedOrgId) {
      // Organization has changed, load new data
      _loadDataForNewOrg();
    }
  }

  Future<void> _loadDataForNewOrg() async {
    setState(() {
      showSpinner = true;
    });

    // Add your data loading logic here
    // For example, refresh the paging controllers or fetch new data
    widget.reviewPagingController.refresh();
    widget.processedPagingController.refresh();

    setState(() {
      showSpinner = false;
    });
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
      return CachedNetworkImage(
        imageUrl: matchData['invoice_path'],
        placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context, url, error) {
          return SfPdfViewer.network(
            matchData['invoice_path'],
            canShowPageLoadingIndicator: false,
            canShowScrollHead: false,
            canShowScrollStatus: false,
          );
        },
      );
    }

    Widget getInvoiceCardWidget(item) {
      var f = NumberFormat("###,###.##", "en_US");

      return Card(
        elevation: 8, // Increased elevation for a more pronounced shadow
        shadowColor: Colors.black26, // Softer shadow color
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // More rounded corners
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200), // Subtle border
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Consistent padding
          child: Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.25,
                child: item['invoice_path'] != null
                    ? SizedBox(
                        height: MediaQuery.of(context).size.width * 0.25,
                        width: MediaQuery.of(context).size.width * 0.25,
                        child: getInvoiceWidget(item))
                    : appLoader,
              ),
              const SizedBox(width: 16), // Consistent spacing
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['supplierName'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18, // Larger font size
                              fontWeight: FontWeight.bold,
                              color: Color(0XFF344054),
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            item['amountDue'] != null ? f.format(item['amountDue']) : "",
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18, // Larger font size for clarity
                              color: Colors.green, // Change color to green for better visibility
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item['accountName'] != null) ...[
                      const SizedBox(height: 8), // Consistent spacing
                      Chip(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        side: BorderSide(color: clickableColor),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '💼 ', // Adding a briefcase emoji for account label
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              item['accountName'],
                              style: const TextStyle(
                                fontSize: 14, // Larger font size
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0XFFFFFEF4),
                      ),
                    ],
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
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/loading.json',
                width: 300,
                height: 300,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Error loading animation');
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading expenses...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0XFF667085),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
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
                      onChanged: (value) {
                        setState(() {
                          updateDetails(value);
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
                              if (index < widget.reviewExpenses.length) {
                                final item = widget.reviewExpenses[index];
                                if (item is Map<dynamic, dynamic>) {
                                  if (index == 0) {
                                    isSameDate = false;
                                  }
                                  final dateString = item['date'] as String?;
                                  if (dateString != null) {
                                    date = DateTime.parse(dateString);
                                    if (index == 0) {
                                      isSameDate = false;
                                    } else {
                                      final prevItem = widget.reviewExpenses[index - 1];
                                      if (prevItem is Map<dynamic, dynamic>) {
                                        final prevDateString = prevItem['date'] as String?;
                                        if (prevDateString != null) {
                                          final DateTime prevDate = DateTime.parse(prevDateString);
                                          isSameDate = date.isSameDate(prevDate);
                                        }
                                      }
                                    }
                                  }
                                }
                              } else {
                                // Handle the case where index is out of bounds
                                return Container(); // or any other placeholder widget
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
                                      if (item is Map<dynamic, dynamic>) {
                                        final imagePath = item['invoice_path'] as String?;
                                        if (imagePath != null) {
                                          Navigator.push(
                                            navigatorKey.currentContext!,
                                            MaterialPageRoute(
                                              builder: (context) => UpdateExpenseData(
                                                expense: item,
                                                imagePath: imagePath,
                                                isProcessed: false,
                                                selectedOrgId: widget.selectedOrgId,
                                              ),
                                            ),
                                          );
                                        }
                                      }
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
                                      if (item is Map<dynamic, dynamic>) {
                                        final imagePath = item['invoice_path'] as String?;
                                        if (imagePath != null) {
                                          Navigator.push(
                                            navigatorKey.currentContext!,
                                            MaterialPageRoute(
                                              builder: (context) => UpdateExpenseData(
                                                expense: item,
                                                imagePath: imagePath,
                                                isProcessed: false,
                                                selectedOrgId: widget.selectedOrgId,
                                              ),
                                            ),
                                          );
                                        }
                                      }
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
          Container(
            color: const Color(0xfffbfbfb),
            padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
            height: MediaQuery.of(context).size.height * 0.8,
            width: double.maxFinite,
            child: Column(
              children: [
                // Add content for the second tab here
                Center(child: Text('Processed Expenses')), // Placeholder content
              ],
            ),
          ),
        ],
      );
    }

    return getPageContent();
  }

  void updateDetails(String value) {
    // Implement the logic to update the details
    // This could involve updating the local state or sending the data to a backend
    print('Details updated: $value');
    // Example: update the local state or call an API
    // setState(() {
    //   // Update the relevant state variable
    // });
  }
}

