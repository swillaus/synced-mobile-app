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
  final PagingController reviewPagingController;
  final PagingController processedPagingController;
  final List reviewExpenses;
  final List processedExpenses;
  final bool showSpinner;
  final String selectedOrgId;
  final bool showUploadingInvoice;
  final Map<String, dynamic> uploadingData;

  const ExpensesTabScreen({
    Key? key,
    required this.tabController,
    required this.reviewPagingController,
    required this.processedPagingController,
    required this.reviewExpenses,
    required this.processedExpenses,
    required this.showSpinner,
    required this.selectedOrgId,
    required this.showUploadingInvoice,
    required this.uploadingData,
  }) : super(key: key);

  @override
  State<ExpensesTabScreen> createState() => _ExpensesTabScreenState();
}

class _ExpensesTabScreenState extends State<ExpensesTabScreen> {
  bool showSpinner = false;
  final Debouncer reviewDebouncer = Debouncer();
  final Debouncer processedDebouncer = Debouncer();
  ScrollController reviewScrollController = ScrollController();
  ScrollController processedScrollController = ScrollController();
  TextEditingController reviewSearchController = TextEditingController();
  TextEditingController processedSearchController = TextEditingController();
  String reviewSearchTerm = '';
  String processedSearchTerm = '';

  // Add noExpenseWidget as a getter
  Widget get noExpenseWidget => Center(
    child: Column(
      children: [
        const SizedBox(height: 30),
        Image.asset(
          'assets/no-expense.png',
          height: MediaQuery.of(navigatorKey.currentContext!).size.height * 0.25,
        ),
        const SizedBox(height: 30),
        const Text(
          'No expenses yet!',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Text(
          'Scan a receipt to add your expense record here',
          style: TextStyle(
            color: Color(0XFF667085),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            final homeScreenState =
                context.findAncestorStateOfType<HomeScreenState>();
            if (homeScreenState != null) {
              homeScreenState.startScan();
            }
          },
          style: ButtonStyle(
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            fixedSize: MaterialStateProperty.all(
              Size(
                MediaQuery.of(navigatorKey.currentContext!).size.width * 0.8,
                MediaQuery.of(navigatorKey.currentContext!).size.height * 0.06,
              ),
            ),
            backgroundColor: MaterialStateProperty.all(clickableColor),
          ),
          child: const Text('Scan now', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

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
      // Clear existing data
      widget.reviewExpenses.clear();
      widget.processedExpenses.clear();
      // Reset search terms and controllers
      reviewSearchController.clear();
      processedSearchController.clear();
      reviewSearchTerm = '';
      processedSearchTerm = '';
    });

    try {
      // Reset both paging controllers completely
      widget.reviewPagingController.itemList?.clear();
      widget.processedPagingController.itemList?.clear();
      
      // Reset the page keys
      widget.reviewPagingController.nextPageKey = 1;
      widget.processedPagingController.nextPageKey = 1;
      
      // Trigger a complete refresh of both controllers
      widget.reviewPagingController.refresh();
      widget.processedPagingController.refresh();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing data: ${e.toString()}')),
      );
    } finally {
      setState(() {
        showSpinner = false;
      });
    }
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: widget.tabController.index == 0 
            ? reviewSearchController 
            : processedSearchController,
        decoration: InputDecoration(
          hintText: 'Search expenses...',
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              if (widget.tabController.index == 0) {
                reviewSearchController.clear();
                reviewSearchTerm = '';
              } else {
                processedSearchController.clear();
                processedSearchTerm = '';
              }
              setState(() {});
            },
          ),
        ),
        onChanged: (value) {
          setState(() {
            if (widget.tabController.index == 0) {
              reviewSearchTerm = value;
            } else {
              processedSearchTerm = value;
            }
          });
        },
      ),
    );
  }

  Widget _buildProcessingCard() {
    if (!widget.showUploadingInvoice) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Lottie.asset(
                    'assets/animations/processing.json',
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Processing Invoice',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (widget.uploadingData['uploadProgress'] != null) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: widget.uploadingData['uploadProgress'],
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(clickableColor),
                ),
                const SizedBox(height: 8),
                Text('${(widget.uploadingData['uploadProgress'] * 100).toInt()}%'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewList() {
    if (widget.reviewExpenses.isEmpty) {
      return Center(
        child: noExpenseWidget,
      );
    }

    return ListView.builder(
      itemCount: widget.reviewExpenses.length,
      itemBuilder: (context, index) {
        final expense = widget.reviewExpenses[index];
        return ExpenseCard(
          expense: expense,
          isProcessed: false,
          selectedOrgId: widget.selectedOrgId,
        );
      },
    );
  }

  Widget _buildProcessedList() {
    return ListView.builder(
      itemCount: widget.processedExpenses.length,
      itemBuilder: (context, index) {
        final expense = widget.processedExpenses[index];
        return ExpenseCard(
          expense: expense,
          isProcessed: true,
          selectedOrgId: widget.selectedOrgId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        elevation: 8,
        shadowColor: Colors.black26,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
              const SizedBox(width: 16),
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
                              fontSize: 18,
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
                              fontSize: 18,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item['accountName'] != null) ...[
                      const SizedBox(height: 8),
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
                              '💼 ',
                              style: TextStyle(fontSize: 16),
                            ),
                            Flexible(
                              child: Text(
                                item['accountName'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
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
      }

      return TabBarView(
        controller: widget.tabController,
        children: [
          // Review Tab
          widget.reviewExpenses.isEmpty && !showUploadingInvoice && reviewSearchController.text.isEmpty
              ? noExpenseWidget  // Show no expense widget when review tab is empty
              : Container(
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
          
          // Processed Tab
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
                        if (processedSearchController.text != processedSearchTerm) {
                          setState(() {
                            processedSearchTerm = processedSearchController.text;
                          });
                          widget.processedPagingController.refresh();
                        }
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      controller: processedSearchController,
                    )),
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
                        DateTime? date;
                        if (index < widget.processedExpenses.length) {
                          final item = widget.processedExpenses[index];
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
                                final prevItem = widget.processedExpenses[index - 1];
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
                            if (widget.processedExpenses[index]['date'] != null) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Expanded(child: Divider()),
                                  Text(' ${date?.formatDate()} ',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 20,  // Change from 12 to 20 to match Review tab
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
                                          isProcessed: true,
                                          selectedOrgId: widget.selectedOrgId,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: SizedBox(
                                height: 120,  // Change from 100 to 120 to match Review tab
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
                                          isProcessed: true,
                                          selectedOrgId: widget.selectedOrgId,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: SizedBox(
                                height: 120,  // Change from 100 to 120 to match Review tab
                                child: getInvoiceCardWidget(item),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ]);
                        }
                      },
                    ),
                  ),
                ),
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

// Add ExpenseCard widget
class ExpenseCard extends StatelessWidget {
  final Map<dynamic, dynamic> expense;
  final bool isProcessed;
  final String selectedOrgId;

  const ExpenseCard({
    Key? key,
    required this.expense,
    required this.isProcessed,
    required this.selectedOrgId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final imagePath = expense['invoice_path'] as String?;
        if (imagePath != null) {
          Navigator.push(
            navigatorKey.currentContext!,
            MaterialPageRoute(
              builder: (context) => UpdateExpenseData(
                expense: expense,
                imagePath: imagePath,
                isProcessed: isProcessed,
                selectedOrgId: selectedOrgId,
              ),
            ),
          );
        }
      },
      child: Card(
        elevation: 8,
        shadowColor: Colors.black26,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.25,
                child: expense['invoice_path'] != null
                    ? SizedBox(
                        height: MediaQuery.of(context).size.width * 0.25,
                        width: MediaQuery.of(context).size.width * 0.25,
                        child: _buildInvoiceWidget(expense),
                      )
                    : const CircularProgressIndicator(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildExpenseDetails(expense),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceWidget(Map matchData) {
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

  Widget _buildExpenseDetails(Map<dynamic, dynamic> expense) {
    var f = NumberFormat("###,###.##", "en_US");
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                expense['supplierName'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0XFF344054),
                ),
              ),
            ),
            Flexible(
              child: Text(
                expense['amountDue'] != null
                    ? f.format(expense['amountDue'])
                    : "",
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        if (expense['accountName'] != null) ...[
          const SizedBox(height: 8),
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
                  '💼 ',
                  style: TextStyle(fontSize: 16),
                ),
                Flexible(
                  child: Text(
                    expense['accountName'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0XFFFFFEF4),
          ),
        ],
      ],
    );
  }
}

