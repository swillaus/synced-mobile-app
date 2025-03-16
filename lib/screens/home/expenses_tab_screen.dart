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

    // Calculate progress with slower rate
    double progress = (widget.uploadingData['uploadProgress'] ?? 0) * 0.7;
    bool isNearlyComplete = progress >= 0.69;
    bool hasDetails = widget.uploadingData['details'] != null;

    // Handle refresh when details are received
    if (hasDetails) {
      // Use Future.microtask to avoid setState during build
      Future.microtask(() {
        if (mounted && widget.uploadingData['details'] != null) {
          // Add the new expense to the list immediately
          setState(() {
            widget.reviewExpenses.insert(0, widget.uploadingData['details']);
          });
          
          // Trigger list refresh
          widget.reviewPagingController.refresh();
          
          // Clear uploading state
          widget.uploadingData.clear();
        }
      });
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.grey,
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            // Left side - Image/File preview
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.2,
              child: widget.uploadingData['path'] != null
                  ? SizedBox(
                      height: 75,
                      width: 75,
                      child: Image.file(File(widget.uploadingData['path'])),
                    )
                  : const CircularProgressIndicator(),
            ),
            const SizedBox(width: 20),
            // Right side - Progress info
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Chip(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100)
                      ),
                      side: const BorderSide(color: Color(0XFFF6CA58)),
                      backgroundColor: const Color(0XFFFFFEF4),
                      label: Row(
                        children: [
                          const SizedBox(
                            height: 10,
                            width: 10,
                            child: CircularProgressIndicator(
                              color: Color(0XFF667085),
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isNearlyComplete ? 'Finalizing...' : 'Processing',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0XFF667085),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.25),
                    Text(
                      widget.uploadingData['size'] ?? '0.77Mb',
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 10,
                        color: Color(0XFF667085),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (!hasDetails) ...[
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: Center(
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: progress,
                        valueColor: AlwaysStoppedAnimation(clickableColor),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
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
          onUpdate: (updatedExpense) {
            setState(() {
              widget.reviewExpenses[index] = updatedExpense;
            });
            widget.reviewPagingController.refresh();
          },
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
          onUpdate: (updatedExpense) {
            setState(() {
              widget.processedExpenses[index] = updatedExpense;
            });
            widget.processedPagingController.refresh();
          },
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
          Container(
            color: const Color(0xfffbfbfb),
            padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
            child: Column(
              children: [
                // Search Bar
                SizedBox(
                  height: 48,
                  child: TextFormField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xfff3f3f3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        borderSide: const BorderSide(color: Colors.transparent)
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        borderSide: const BorderSide(color: Colors.transparent)
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        borderSide: const BorderSide(color: Colors.transparent)
                      ),
                      focusColor: const Color(0XFF8E8E8E),
                      hintText: 'Search',
                      hintStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0XFF8E8E8E)
                      ),
                      prefixIcon: const Icon(Icons.search),
                      prefixIconColor: const Color(0XFF8E8E8E)
                    ),
                    controller: reviewSearchController,
                    onChanged: (value) {
                      reviewDebouncer.debounce(
                        duration: const Duration(milliseconds: 250),
                        onDebounce: () {
                          setState(() {
                            reviewSearchTerm = value;
                          });
                          widget.reviewPagingController.refresh();
                        }
                      );
                    },
                    onEditingComplete: () {
                      if (reviewSearchController.text != reviewSearchTerm) {
                        setState(() {
                          reviewSearchTerm = reviewSearchController.text;
                        });
                        widget.reviewPagingController.refresh();
                      }
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Processing Card
                if (widget.showUploadingInvoice) _buildProcessingCard(),

                // Expense List
                Expanded(
                  child: PagedListView(
                    shrinkWrap: true,
                    pagingController: widget.reviewPagingController,
                    scrollController: reviewScrollController,
                    physics: widget.tabController.index == 0
                        ? const AlwaysScrollableScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    builderDelegate: PagedChildBuilderDelegate<dynamic>(
                      firstPageErrorIndicatorBuilder: (context) => noExpenseWidget,
                      noItemsFoundIndicatorBuilder: (context) => reviewSearchTerm.isEmpty 
                        ? noExpenseWidget
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Text(
                                'No expenses found matching "${reviewSearchTerm}"',
                                style: const TextStyle(
                                  color: Color(0XFF667085),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                      itemBuilder: (context, item, index) {
                        // Filter items based on search term
                        final filteredExpenses = widget.reviewExpenses.where((expense) {
                          if (reviewSearchTerm.isEmpty) return true;
                          
                          final searchLower = reviewSearchTerm.toLowerCase();
                          final supplierName = (expense['supplierName'] ?? '').toString().toLowerCase();
                          final accountName = (expense['accountName'] ?? '').toString().toLowerCase();
                          final amount = (expense['amountDue'] ?? '').toString();
                          
                          return supplierName.contains(searchLower) ||
                                 accountName.contains(searchLower) ||
                                 amount.contains(searchLower);
                        }).toList();

                        // Check if current index is within filtered results
                        if (filteredExpenses.isEmpty || index >= filteredExpenses.length) {
                          return const SizedBox.shrink();
                        }

                        final currentItem = filteredExpenses[index];
                        bool isSameDate = true;
                        DateTime? date;

                        if (currentItem['date'] != null) {
                          final String dateString = currentItem['date'];
                          date = DateTime.parse(dateString);
                          if (index == 0) {
                            isSameDate = false;
                          } else if (index > 0 && filteredExpenses[index - 1]['date'] != null) {
                            final String prevDateString = filteredExpenses[index - 1]['date'];
                            final DateTime prevDate = DateTime.parse(prevDateString);
                            isSameDate = date.isSameDate(prevDate);
                          }
                        }

                        return Column(
                          children: [
                            if (index == 0 || !isSameDate) ...[
                              if (currentItem['date'] != null) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Expanded(child: Divider()),
                                    Text(
                                      ' ${date?.formatDate()} ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12,
                                        color: Color(0XFF667085),
                                      ),
                                    ),
                                    const Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: 10),
                              ],
                            ],
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  navigatorKey.currentContext!,
                                  MaterialPageRoute(
                                    builder: (context) => UpdateExpenseData(
                                      expense: currentItem,
                                      imagePath: currentItem['invoice_path'],
                                      isProcessed: false,
                                      selectedOrgId: widget.selectedOrgId,
                                    ),
                                  ),
                                );
                              },
                              child: SizedBox(
                                height: 120, // Changed from 100 to 120 to match processed tab
                                child: getInvoiceCardWidget(currentItem),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      },
                    ),
                  ),
                ),
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
                        processedDebouncer.debounce(
                          duration: const Duration(milliseconds: 250),
                          onDebounce: () {
                            setState(() {
                              processedSearchTerm = value;
                            });
                            widget.processedPagingController.refresh();
                          }
                        );
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
                    builderDelegate: PagedChildBuilderDelegate<dynamic>(
                      noItemsFoundIndicatorBuilder: (context) => processedSearchTerm.isEmpty 
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Text(
                                'No processed expenses yet',
                                style: TextStyle(
                                  color: Color(0XFF667085),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Text(
                                'No expenses found matching "${processedSearchTerm}"',
                                style: const TextStyle(
                                  color: Color(0XFF667085),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                      itemBuilder: (context, item, index) {
                        // Filter items based on search term
                        final filteredExpenses = widget.processedExpenses.where((expense) {
                          if (processedSearchTerm.isEmpty) return true;
                          
                          final searchLower = processedSearchTerm.toLowerCase();
                          final supplierName = (expense['supplierName'] ?? '').toString().toLowerCase();
                          final accountName = (expense['accountName'] ?? '').toString().toLowerCase();
                          final amount = (expense['amountDue'] ?? '').toString();
                          
                          return supplierName.contains(searchLower) ||
                                 accountName.contains(searchLower) ||
                                 amount.contains(searchLower);
                        }).toList();

                        // Check if current index is within filtered results
                        if (filteredExpenses.isEmpty || index >= filteredExpenses.length) {
                          return const SizedBox.shrink();
                        }

                        final currentItem = filteredExpenses[index];
                        bool isSameDate = true;
                        DateTime? date;

                        if (currentItem['date'] != null) {
                          final dateString = currentItem['date'] as String?;
                          if (dateString != null) {
                            date = DateTime.parse(dateString);
                            if (index == 0) {
                              isSameDate = false;
                            } else if (index > 0 && filteredExpenses[index - 1]['date'] != null) {
                              final prevDateString = filteredExpenses[index - 1]['date'] as String?;
                              if (prevDateString != null) {
                                final DateTime prevDate = DateTime.parse(prevDateString);
                                isSameDate = date.isSameDate(prevDate);
                              }
                            }
                          }
                        }

                        return Column(
                          children: [
                            if (index == 0 || !isSameDate) ...[
                              if (currentItem['date'] != null) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Expanded(child: Divider()),
                                    Text(
                                      ' ${date?.formatDate()} ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 20,
                                        color: Color(0XFF667085),
                                      ),
                                    ),
                                    const Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: 10),
                              ],
                            ],
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  navigatorKey.currentContext!,
                                  MaterialPageRoute(
                                    builder: (context) => UpdateExpenseData(
                                      expense: currentItem,
                                      imagePath: currentItem['invoice_path'],
                                      isProcessed: true,
                                      selectedOrgId: widget.selectedOrgId,
                                    ),
                                  ),
                                );
                              },
                              child: SizedBox(
                                height: 120,
                                child: getInvoiceCardWidget(currentItem),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
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
  final Function(Map<dynamic, dynamic>)? onUpdate; // Add this

  const ExpenseCard({
    Key? key,
    required this.expense,
    required this.isProcessed,
    required this.selectedOrgId,
    this.onUpdate,  // Add this
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {  // Make this async
        final imagePath = expense['invoice_path'] as String?;
        if (imagePath != null) {
          final result = await Navigator.push(  // Get the result
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
          
          // Handle the update result
          if (result != null && result is Map<dynamic, dynamic>) {
            onUpdate?.call(result);  // Call the update callback if provided
          }
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

