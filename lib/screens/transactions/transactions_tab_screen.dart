import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_render/pdf_render_widgets.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:synced/main.dart';
import 'package:synced/utils/api_services.dart';
import 'package:synced/utils/constants.dart';

class TransactionsTabScreen extends StatefulWidget {
  const TransactionsTabScreen({super.key});

  @override
  State<TransactionsTabScreen> createState() => _TransactionsTabScreenState();
}

class _TransactionsTabScreenState extends State<TransactionsTabScreen> {
  List unreconciledReports = [];
  bool showSpinner = false;
  Widget noTransactionWidget = Container(
    color: Colors.white,
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/no-transactions.png',
            height:
                MediaQuery.of(navigatorKey.currentContext!).size.height * 0.25),
        const SizedBox(height: 30),
        const Text('No Transaction yet!',
            style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const Text('Currently there are no transactions assigned to \nyou.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0XFF667085),
                fontSize: 14,
                fontWeight: FontWeight.w400)),
      ],
    ),
  );

  @override
  void initState() {
    setState(() {
      showSpinner = true;
    });
    ApiService.getUnreconciledReports(selectedOrgId).then((resp) {
      setState(() {
        showSpinner = false;
      });
      if (resp.isEmpty) {
        return noTransactionWidget;
      } else {
        unreconciledReports = resp;
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget getPageContent() {
      return ModalProgressHUD(
          color: Colors.white,
          opacity: 1.0,
          inAsyncCall: showSpinner,
          progressIndicator: appLoader,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: ListView.separated(
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 15);
                },
                itemCount: unreconciledReports.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      PersistentNavBarNavigator.pushNewScreen(
                        context,
                        screen: TransactionsListPage(
                            reportId: '', report: unreconciledReports[index]),
                        withNavBar: true,
                        pageTransitionAnimation:
                            PageTransitionAnimation.cupertino,
                      );
                    },
                    child: Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: clickableColor, width: 2.0)),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                  unreconciledReports[index]['reportName'],
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0XFF344054))),
                            ),
                            const SizedBox(height: 10),
                            IntrinsicHeight(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Image.asset('assets/home_icon.png',
                                      height: 45, width: 45),
                                  const SizedBox(width: 5),
                                  Column(
                                    children: [
                                      const Text('Total Value',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontSize: 10,
                                              color: Color(0XFF667085))),
                                      Text(
                                          unreconciledReports[index]
                                                  ['totalAmount']
                                              .toString(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Color(0XFF101828))),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  const VerticalDivider(
                                    color: Colors.grey,
                                    width: 2.0,
                                  ),
                                  const SizedBox(width: 20),
                                  Image.asset('assets/tick.png',
                                      height: 45, width: 45),
                                  const SizedBox(width: 5),
                                  Column(
                                    children: [
                                      const Text('Total Value',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontSize: 10,
                                              color: Color(0XFF667085))),
                                      Text(
                                          unreconciledReports[index]
                                                  ['totalMatchedAmount']
                                              .toString(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Color(0XFF101828))),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  Column(
                                    children: [
                                      const Text('Total transactions',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontSize: 10,
                                              color: Color(0XFF667085))),
                                      Text(
                                          unreconciledReports[index]
                                                  ['totalCount']
                                              .toString(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Color(0XFF101828))),
                                    ],
                                  ),
                                  const SizedBox(width: 45),
                                  const VerticalDivider(
                                    color: Colors.grey,
                                    width: 2.0,
                                  ),
                                  const SizedBox(width: 45),
                                  Column(
                                    children: [
                                      const Text('Total matches',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontSize: 10,
                                              color: Color(0XFF667085))),
                                      Text(
                                          unreconciledReports[index]
                                                  ['totalMatched']
                                              .toString(),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Color(0XFF101828))),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
          ));
    }

    return getPageContent();
  }
}

class TransactionsListPage extends StatefulWidget {
  final String reportId;
  final Map report;
  const TransactionsListPage(
      {super.key, required this.reportId, required this.report});

  @override
  State<TransactionsListPage> createState() => _TransactionsListPageState();
}

class _TransactionsListPageState extends State<TransactionsListPage> {
  bool showSpinner = false;
  String selectedFilter = 'All';
  List transactions = [];
  List filteredTransactions = [];
  TextEditingController transactionSearchController = TextEditingController();

  @override
  void initState() {
    setState(() {
      showSpinner = true;
    });
    preparePageContent();
    super.initState();
  }

  Future<void> preparePageContent() async {
    final resp = await ApiService.getReportsList('', selectedOrgId);
    if (resp.isEmpty) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(
              content: Text('Something went wrong, please try again.')));
    } else {
      transactions = resp['data'];
      filteredTransactions = resp['data'];
      transactions.forEach((t) async {
        if (t['relatedID'] != null) {
          final resp =
              await ApiService.getRelatedData(t['relatedID'], selectedOrgId);
          t['matchData'] = resp;
        } else {
          t['matchData'] = {};
        }

        final tempDir = await getTemporaryDirectory();
        if (t['matchData'] != null && t['matchData'].isNotEmpty) {
          if (await File('$tempDir.path/${t['matchData']['invoicePdfUrl']}.pdf')
                  .exists() ==
              true) {
            setState(() {
              t['matchData']['invoice_path'] =
                  '$tempDir.path/${t['matchData']['invoicePdfUrl']}.pdf';
            });
          } else if (await File(
                      '$tempDir.path/${t['matchData']['invoicePdfUrl']}.jpeg')
                  .exists() ==
              true) {
            setState(() {
              t['matchData']['invoice_path'] =
                  '$tempDir.path/${t['matchData']['invoicePdfUrl']}.jpeg';
            });
          } else {
            final downloadResp = await ApiService.downloadInvoice(
                t['matchData']['invoicePdfUrl'], selectedOrgId);
            setState(() {
              t['matchData']['invoice_path'] = downloadResp['path'];
            });
            if (kDebugMode) {
              print(downloadResp);
            }
          }
        }
      });
      setState(() {});
    }
    setState(() {
      showSpinner = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
        inAsyncCall: showSpinner,
        opacity: 1.0,
        color: Colors.white,
        progressIndicator: appLoader,
        child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: clickableColor, width: 2.0)),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(widget.report['reportName'],
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0XFF344054))),
                      ),
                      const SizedBox(height: 10),
                      IntrinsicHeight(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Image.asset('assets/home_icon.png',
                                height: 45, width: 45),
                            const SizedBox(width: 5),
                            Column(
                              children: [
                                const Text('Total Value',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 10,
                                        color: Color(0XFF667085))),
                                Text(widget.report['totalAmount'].toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0XFF101828))),
                              ],
                            ),
                            const SizedBox(width: 20),
                            const VerticalDivider(
                              color: Colors.grey,
                              width: 2.0,
                            ),
                            const SizedBox(width: 20),
                            Image.asset('assets/tick.png',
                                height: 45, width: 45),
                            const SizedBox(width: 5),
                            Column(
                              children: [
                                const Text('Total Value',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 10,
                                        color: Color(0XFF667085))),
                                Text(
                                    widget.report['totalMatchedAmount']
                                        .toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0XFF101828))),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            Column(
                              children: [
                                const Text('Total transactions',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 10,
                                        color: Color(0XFF667085))),
                                Text(widget.report['totalCount'].toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0XFF101828))),
                              ],
                            ),
                            const SizedBox(width: 45),
                            const VerticalDivider(
                              color: Colors.grey,
                              width: 2.0,
                            ),
                            const SizedBox(width: 45),
                            Column(
                              children: [
                                const Text('Total matches',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 10,
                                        color: Color(0XFF667085))),
                                Text(widget.report['totalMatched'].toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0XFF101828))),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
                onChanged: (value) {},
                controller: transactionSearchController,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFilter = 'All';
                      });
                      filteredTransactions = transactions;
                      setState(() {});
                    },
                    child: Chip(
                      label: const Text('All'),
                      avatar:
                          const Icon(Icons.filter_list, color: Colors.black),
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                              color: selectedFilter == 'All'
                                  ? clickableColor
                                  : const Color(0XFFD0D5DD))),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFilter = 'Matched';
                      });
                      filteredTransactions = [];
                      transactions.forEach((transaction) {
                        if (transaction['status'] != 'Unassigned') {
                          filteredTransactions.add(transaction);
                        }
                      });
                      setState(() {});
                    },
                    child: Chip(
                      label: const Text('Matched'),
                      avatar:
                          const Icon(Icons.filter_list, color: Colors.black),
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                              color: selectedFilter == 'Matched'
                                  ? clickableColor
                                  : const Color(0XFFD0D5DD))),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFilter = 'Unmatched';
                      });
                      filteredTransactions = [];
                      transactions.forEach((transaction) {
                        if (transaction['status'] == 'Unassigned') {
                          filteredTransactions.add(transaction);
                        }
                      });
                      setState(() {});
                    },
                    child: Chip(
                      label: const Text('Unmatched'),
                      avatar:
                          const Icon(Icons.filter_list, color: Colors.black),
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                              color: selectedFilter == 'Unmatched'
                                  ? clickableColor
                                  : const Color(0XFFD0D5DD))),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: Colors.white,
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                              backgroundColor: Colors.white,
                              showTrailingIcon: false,
                              title: Container(
                                  color: Colors.white,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Image.asset('assets/home_icon.png',
                                          height: 50, width: 50),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              filteredTransactions[index]
                                                  ['description'],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: Color(0XFF344054))),
                                          Text(
                                              'Due: ${DateFormat('d MMM, y').format(DateTime.parse(filteredTransactions[index]['relatedDate'])).toString()}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 12,
                                                  color: Color(0XFF667085)))
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            color: filteredTransactions[index]
                                                        ['status'] ==
                                                    'Unassigned'
                                                ? const Color(0XFFFFEFEF)
                                                : const Color(0XFFE5FFE9),
                                            child: Text(
                                                filteredTransactions[index]
                                                            ['status'] ==
                                                        'Unassigned'
                                                    ? 'Unmatched'
                                                    : 'Matched',
                                                style: TextStyle(
                                                    color: filteredTransactions[
                                                                    index]
                                                                ['status'] ==
                                                            'Unassigned'
                                                        ? const Color(
                                                            0XFFFF1B1B)
                                                        : const Color(
                                                            0XFF009318))),
                                          ),
                                          filteredTransactions[index][
                                                      'amount'] !=
                                                  null
                                              ? Text(
                                                  '${filteredTransactions[index]['matchData']['currency'].runtimeType == String ? NumberFormat().simpleCurrencySymbol(filteredTransactions[index]['matchData']['currency']) : ''}${filteredTransactions[index]['amount'].toString()}',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 16,
                                                      color:
                                                          filteredTransactions[
                                                                          index]
                                                                      ['amount']
                                                                  .toString()
                                                                  .startsWith(
                                                                      '-')
                                                              ? const Color(
                                                                  0XFFFF1B1B)
                                                              : const Color(
                                                                  0XFF009318)))
                                              : const SizedBox()
                                        ],
                                      ),
                                    ],
                                  )),
                              tilePadding:
                                  const EdgeInsets.only(left: 10, right: 10),
                              children: [
                                if (filteredTransactions[index]['matchData'] !=
                                    null) ...[
                                  Theme(
                                    data: Theme.of(context).copyWith(
                                        dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                        tilePadding: const EdgeInsets.only(
                                            left: 10, right: 10),
                                        backgroundColor: Colors.white,
                                        showTrailingIcon: false,
                                        title: Container(
                                          color: Colors.white,
                                          child: Column(children: [
                                            const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Expanded(child: Divider()),
                                                Text('Suggested match',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontSize: 12,
                                                        color:
                                                            Color(0XFF667085))),
                                                Expanded(child: Divider()),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Card(
                                              color: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  side: BorderSide(
                                                      color: clickableColor,
                                                      width: 2.0)),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(5),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    filteredTransactions[index]
                                                                    ['matchData']
                                                                [
                                                                'invoice_path'] !=
                                                            null
                                                        ? SizedBox(
                                                            height: 75,
                                                            width: 75,
                                                            child: filteredTransactions[index]['matchData']
                                                                            [
                                                                            'invoice_path']
                                                                        .toString()
                                                                        .split(
                                                                            '.')
                                                                        .last ==
                                                                    'pdf'
                                                                ? PdfViewer.openFile(
                                                                    filteredTransactions[index]
                                                                            ['matchData']
                                                                        ['invoice_path'])
                                                                : Image.file(File(filteredTransactions[index]['matchData']['invoice_path'])))
                                                        : appLoader,
                                                    SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.4,
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                              filteredTransactions[
                                                                              index]
                                                                          ['matchData']
                                                                      [
                                                                      'supplierName'] ??
                                                                  '',
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: const TextStyle(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Color(
                                                                      0XFF344054))),
                                                          if (filteredTransactions[
                                                                          index]
                                                                      [
                                                                      'matchData']
                                                                  ['date'] !=
                                                              null) ...[
                                                            Align(
                                                              alignment:
                                                                  Alignment
                                                                      .topLeft,
                                                              child: Text(
                                                                  'Due: ${DateFormat('d MMM, y').format(DateTime.parse(filteredTransactions[index]['matchData']['date'])).toString()}'),
                                                            )
                                                          ],
                                                          if (filteredTransactions[
                                                                          index]
                                                                      [
                                                                      'matchData']
                                                                  [
                                                                  'accountName'] !=
                                                              null) ...[
                                                            Align(
                                                              alignment: Alignment
                                                                  .bottomLeft,
                                                              child: Chip(
                                                                shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            24)),
                                                                side:
                                                                    BorderSide(
                                                                  color:
                                                                      clickableColor,
                                                                ),
                                                                label: Text(filteredTransactions[
                                                                            index]
                                                                        [
                                                                        'matchData']
                                                                    [
                                                                    'accountName']),
                                                                color: const WidgetStatePropertyAll(
                                                                    Color(
                                                                        0XFFFFFEF4)),
                                                                labelStyle: const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color: Color(
                                                                        0XFF667085)),
                                                              ),
                                                            )
                                                          ]
                                                        ],
                                                      ),
                                                    ),
                                                    Align(
                                                      alignment:
                                                          Alignment.centerRight,
                                                      child: Text(
                                                        '${filteredTransactions[index]['matchData']['currency'].runtimeType == String ? NumberFormat().simpleCurrencySymbol(filteredTransactions[index]['matchData']['currency']) : ''}${filteredTransactions[index]['matchData']['amountDue']}',
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 12,
                                                            color: Color(
                                                                0XFF101828)),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10)
                                          ]),
                                        )),
                                  )
                                ]
                              ]),
                        ),
                      );
                    }),
              )
            ])));
  }
}
