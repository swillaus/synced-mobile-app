import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:synced/main.dart';
import 'package:synced/screens/home/home_screen.dart';
import 'package:synced/utils/api_services.dart';
import 'package:synced/utils/constants.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class TransactionsTabScreen extends StatefulWidget {
  const TransactionsTabScreen({super.key});

  @override
  State<TransactionsTabScreen> createState() => _TransactionsTabScreenState();
}

class _TransactionsTabScreenState extends State<TransactionsTabScreen> {
  List unreconciledReports = [];
  bool showSpinner = false;
  RefreshController reportsRefreshController =
      RefreshController(initialRefresh: false);
  Widget noTransactionWidget = Container(
    color: Colors.white,
    padding: const EdgeInsets.all(20),
    width: MediaQuery.of(navigatorKey.currentContext!).size.width,
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
    super.initState();
    preparePageContent();
  }

  @override
  void dispose() {
    reportsRefreshController.dispose();
    super.dispose();
  }

  Future<void> preparePageContent() async {
    setState(() {
      showSpinner = true;
    });
    final resp = await ApiService.getUnreconciledReports(selectedOrgId);
    if (mounted) {
      setState(() {
        showSpinner = false;
        unreconciledReports = resp;
      });
    }
    reportsRefreshController.loadComplete();
    reportsRefreshController.refreshCompleted();
  }

  Widget _buildTransactionRow(Map<String, dynamic> transaction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon or Image
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 12),

              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction['title'] ?? 'Transaction Title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction['date'] ?? 'Transaction Date',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),

              // Amount
              Flexible(
                child: Text(
                  transaction['amount'] ?? '\$0.00',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: transaction['isCredit'] == true
                        ? Colors.green
                        : Colors.red,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        child: SmartRefresher(
          controller: reportsRefreshController,
          onRefresh: preparePageContent,
          onLoading: preparePageContent,
          child: ModalProgressHUD(
              color: Colors.white,
              opacity: 1.0,
              inAsyncCall: showSpinner,
              progressIndicator: appLoader,
              child: unreconciledReports.isNotEmpty
                  ? Container(
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          TransactionsListPage(
                                              reportId:
                                                  unreconciledReports[index]
                                                      ['id'],
                                              report:
                                                  unreconciledReports[index])),
                                );
                              },
                              child: Card(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: clickableColor, width: 2.0)),
                                child: Container(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                            unreconciledReports[index]
                                                ['reportName'],
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0XFF344054))),
                                      ),
                                      const SizedBox(height: 10),
                                      IntrinsicHeight(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.1,
                                                  child: Image.asset(
                                                      'assets/home_icon.png'),
                                                )
                                              ],
                                            ),
                                            const SizedBox(width: 10),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.25,
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Text('Total Value',
                                                        textAlign:
                                                            TextAlign.start,
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            fontSize: 10,
                                                            color: Color(
                                                                0XFF667085))),
                                                    Text(
                                                        unreconciledReports[
                                                                        index][
                                                                    'totalAmount']
                                                                .toString()
                                                                .startsWith('-')
                                                            ? '(${(unreconciledReports[index]['totalAmount']).abs().toString()})'
                                                            : unreconciledReports[
                                                                        index][
                                                                    'totalAmount']
                                                                .toString(),
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 14,
                                                            color: Color(
                                                                0XFF101828))),
                                                    const SizedBox(height: 10),
                                                    const Text(
                                                        'Total transactions',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            fontSize: 10,
                                                            color: Color(
                                                                0XFF667085))),
                                                    Text(
                                                        unreconciledReports[
                                                                    index]
                                                                ['totalCount']
                                                            .toString(),
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 14,
                                                            color: Color(
                                                                0XFF101828))),
                                                  ]),
                                            ),
                                            SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.025),
                                            const VerticalDivider(
                                              color: Colors.grey,
                                              width: 2.0,
                                            ),
                                            SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.025),
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.1,
                                                  child: Image.asset(
                                                      'assets/tick.png'),
                                                )
                                              ],
                                            ),
                                            const SizedBox(width: 10),
                                            SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.25,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Text('Total Value',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: 10,
                                                          color: Color(
                                                              0XFF667085))),
                                                  Text(
                                                      unreconciledReports[index]
                                                                  [
                                                                  'totalMatchedAmount']
                                                              .toString()
                                                              .startsWith('-')
                                                          ? '(${(unreconciledReports[index]['totalMatchedAmount']).abs().toString()})'
                                                          : unreconciledReports[
                                                                      index][
                                                                  'totalMatchedAmount']
                                                              .toString(),
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                          color: Color(
                                                              0XFF101828))),
                                                  const SizedBox(height: 10),
                                                  const Text('Total matches',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: 10,
                                                          color: Color(
                                                              0XFF667085))),
                                                  Text(
                                                      unreconciledReports[index]
                                                              ['totalMatched']
                                                          .toString(),
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                          color: Color(
                                                              0XFF101828))),
                                                ],
                                              ),
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
                    )
                  : noTransactionWidget),
        ),
        onPopInvokedWithResult: (didPop, result) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const HomeScreen(navbarIndex: 2)));
        });
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
  RefreshController transactionRefreshController =
      RefreshController(initialRefresh: false);
  int? expandedTileIndex;

  @override
  void initState() {
    super.initState();
    preparePageContent();
  }

  @override
  void dispose() {
    transactionRefreshController.dispose();
    super.dispose();
  }

  Future<void> preparePageContent() async {
    setState(() {
      showSpinner = true;
    });
    final resp =
        await ApiService.getReportsList(widget.reportId, selectedOrgId);
    if (resp.isEmpty) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(
              content: Text('Something went wrong, please try again.')));
    } else {
      transactions = resp['data'];
      filteredTransactions = resp['data'];

      setState(() {
        showSpinner = false;
      });
      transactionRefreshController.loadComplete();
      transactionRefreshController.refreshCompleted();

      for (var t in filteredTransactions) {
        final relatedDataResp =
            await ApiService.getRelatedData(t['relatedID'], selectedOrgId);
        final matchDataResp = await ApiService.getMatchData(
            t['unreconciledReportId'], selectedOrgId);

        t['relatedData'] = relatedDataResp;
        t['matchData'] = matchDataResp;

        if (t['matchData'] != null &&
            t['matchData'].isNotEmpty &&
            t['matchData'] != null &&
            t['relatedData'].isEmpty) {
          t['matchData']['invoice_path'] =
              'https://syncedblobstaging.blob.core.windows.net/invoices/${t['matchData']['pdfUrl']}';
        } else if (t['relatedData'] != null && t['relatedData'].isNotEmpty) {
          t['relatedData']['invoice_path'] =
              'https://syncedblobstaging.blob.core.windows.net/invoices/${t['relatedData']['invoicePdfUrl']}';
        }
        setState(() {});
      }
    }
  }

  Widget getInvoiceWidget(Map matchData) {
    late Widget invoiceImage;
    invoiceImage = CachedNetworkImage(
      imageUrl: matchData['invoice_path'],
      errorWidget: (context, url, error) {
        return SfPdfViewer.network(matchData['invoice_path'],
            enableDoubleTapZooming: false,
            enableTextSelection: false,
            enableDocumentLinkAnnotation: false,
            enableHyperlinkNavigation: false,
            canShowPageLoadingIndicator: false,
            canShowScrollHead: false,
            canShowScrollStatus: false);
      },
    );
    return invoiceImage;
  }

  Widget getMatchWidget(Map matchData, String type, int index) {
    return Card(
      elevation: 4,
      shadowColor: Colors.grey,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: type == 'match' && expandedTileIndex == index
              ? BorderSide(color: clickableColor, width: 2.0)
              : const BorderSide(color: Colors.transparent, width: 0.0)),
      child: Container(
        height: 100,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: Row(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.175,
              child: matchData['invoice_path'] != null
                  ? SizedBox(
                      height: MediaQuery.of(context).size.width * 0.175,
                      width: MediaQuery.of(context).size.width * 0.175,
                      child: getInvoiceWidget(matchData))
                  : appLoader,
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.38,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: matchData['supplierName'] != null
                            ? Text(matchData['supplierName'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0XFF344054)))
                            : SizedBox(
                                width:
                                    MediaQuery.of(context).size.width * 0.38),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.2,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Text(
                          matchData['amountDue'].toString(),
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Color(0XFF101828)),
                        ),
                      ),
                    )
                  ],
                ),
                if (matchData['date'] != null) ...[
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(DateFormat('d MMM, y')
                        .format(DateTime.parse(matchData['date']))
                        .toString()),
                  )
                ],
                if (matchData['accountName'] != null) ...[
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Chip(
                      padding: const EdgeInsets.fromLTRB(2, 10, 2, 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100)),
                      side: BorderSide(
                        color: clickableColor,
                      ),
                      label: Text(matchData['accountName']),
                      color: const WidgetStatePropertyAll(Color(0XFFFFFEF4)),
                      labelStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
        child: ModalProgressHUD(
            inAsyncCall: showSpinner,
            opacity: 1.0,
            color: Colors.white,
            progressIndicator: appLoader,
            child: Scaffold(
              appBar: PreferredSize(
                  preferredSize: const Size(double.maxFinite, 40),
                  child: AppBar(
                    centerTitle: true,
                    surfaceTintColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () {
                        Navigator.of(navigatorKey.currentContext!)
                            .popUntil((route) => route.isFirst);
                      },
                    ),
                    title: Text('Transactions',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: headingColor)),
                    backgroundColor: Colors.white,
                  )),
              body: SmartRefresher(
                  controller: transactionRefreshController,
                  onLoading: preparePageContent,
                  onRefresh: preparePageContent,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    height: double.maxFinite,
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredTransactions.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Container(
                              child: Column(
                                children: [
                                  Card(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                            color: clickableColor, width: 2.0)),
                                    child: Container(
                                      padding: const EdgeInsets.all(15),
                                      child: Column(
                                        children: [
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                                widget.report['reportName'],
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0XFF344054))),
                                          ),
                                          const SizedBox(height: 10),
                                          IntrinsicHeight(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.1,
                                                      child: Image.asset(
                                                          'assets/home_icon.png'),
                                                    )
                                                  ],
                                                ),
                                                const SizedBox(width: 10),
                                                SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.25,
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        const Text(
                                                            'Total Value',
                                                            textAlign:
                                                                TextAlign.start,
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                fontSize: 10,
                                                                color: Color(
                                                                    0XFF667085))),
                                                        Text(
                                                            widget.report[
                                                                        'totalAmount']
                                                                    .toString()
                                                                    .startsWith(
                                                                        '-')
                                                                ? '(${(widget.report['totalAmount']).abs().toString()})'
                                                                : widget.report[
                                                                        'totalAmount']
                                                                    .toString(),
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 14,
                                                                color: Color(
                                                                    0XFF101828))),
                                                        const SizedBox(
                                                            height: 10),
                                                        const Text(
                                                            'Total transactions',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                fontSize: 10,
                                                                color: Color(
                                                                    0XFF667085))),
                                                        Text(
                                                            widget
                                                                .report[
                                                                    'totalCount']
                                                                .toString(),
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 14,
                                                                color: Color(
                                                                    0XFF101828))),
                                                      ]),
                                                ),
                                                SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.025),
                                                const VerticalDivider(
                                                  color: Colors.grey,
                                                  width: 2.0,
                                                ),
                                                SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.025),
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.1,
                                                      child: Image.asset(
                                                          'assets/tick.png'),
                                                    )
                                                  ],
                                                ),
                                                const SizedBox(width: 10),
                                                SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.25,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      const Text('Total Value',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              fontSize: 10,
                                                              color: Color(
                                                                  0XFF667085))),
                                                      Text(
                                                          widget.report[
                                                                      'totalMatchedAmount']
                                                                  .toString()
                                                                  .startsWith(
                                                                      '-')
                                                              ? '(${(widget.report['totalMatchedAmount']).abs().toString()})'
                                                              : widget.report[
                                                                      'totalMatchedAmount']
                                                                  .toString(),
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 14,
                                                              color: Color(
                                                                  0XFF101828))),
                                                      const SizedBox(
                                                          height: 10),
                                                      const Text(
                                                          'Total matches',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              fontSize: 10,
                                                              color: Color(
                                                                  0XFF667085))),
                                                      Text(
                                                          widget.report[
                                                                  'totalMatched']
                                                              .toString(),
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 14,
                                                              color: Color(
                                                                  0XFF101828))),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                      height: 48,
                                      child: TextField(
                                        decoration: InputDecoration(
                                            filled: true,
                                            fillColor: const Color(0xfff3f3f3),
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5.0),
                                                borderSide: const BorderSide(
                                                    color: Colors.transparent)),
                                            enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5.0),
                                                borderSide: const BorderSide(
                                                    color: Colors.transparent)),
                                            focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5.0),
                                                borderSide: const BorderSide(
                                                    color: Colors.transparent)),
                                            focusColor: const Color(0XFF8E8E8E),
                                            hintText: 'Search',
                                            hintStyle: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                                color: Color(0XFF8E8E8E)),
                                            prefixIcon:
                                                const Icon(Icons.search),
                                            prefixIconColor:
                                                const Color(0XFF8E8E8E)),
                                        onChanged: (value) {
                                          filteredTransactions = [];
                                          for (var transaction
                                              in transactions) {
                                            if (transaction['description']
                                                .toString()
                                                .toLowerCase()
                                                .contains(
                                                    value.toLowerCase())) {
                                              filteredTransactions
                                                  .add(transaction);
                                            }
                                          }
                                          setState(() {});
                                        },
                                        controller: transactionSearchController,
                                      )),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                          avatar: const Icon(Icons.filter_list,
                                              color: Colors.black),
                                          backgroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              side: BorderSide(
                                                  color: selectedFilter == 'All'
                                                      ? clickableColor
                                                      : const Color(
                                                          0XFFD0D5DD))),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedFilter = 'Matched';
                                          });
                                          filteredTransactions = [];
                                          for (var transaction
                                              in transactions) {
                                            if (transaction['status'] !=
                                                    'Unassigned' &&
                                                transaction['status'] !=
                                                    'Assigned') {
                                              filteredTransactions
                                                  .add(transaction);
                                            }
                                          }
                                          setState(() {});
                                        },
                                        child: Chip(
                                          label: const Text('Matched'),
                                          avatar: const Icon(Icons.filter_list,
                                              color: Colors.black),
                                          backgroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              side: BorderSide(
                                                  color: selectedFilter ==
                                                          'Matched'
                                                      ? clickableColor
                                                      : const Color(
                                                          0XFFD0D5DD))),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedFilter = 'Unmatched';
                                          });
                                          filteredTransactions = [];
                                          for (var transaction
                                              in transactions) {
                                            if (transaction['status'] ==
                                                    'Unassigned' ||
                                                transaction['status'] ==
                                                    'Assigned') {
                                              filteredTransactions
                                                  .add(transaction);
                                            }
                                          }
                                          setState(() {});
                                        },
                                        child: Chip(
                                          label: const Text('Unmatched'),
                                          avatar: const Icon(Icons.filter_list,
                                              color: Colors.black),
                                          backgroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              side: BorderSide(
                                                  color: selectedFilter ==
                                                          'Unmatched'
                                                      ? clickableColor
                                                      : const Color(
                                                          0XFFD0D5DD))),
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            );
                          }
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
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Image.asset('assets/home_icon.png',
                                              height: 50, width: 50),
                                          const SizedBox(width: 10),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.45,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                      filteredTransactions[
                                                              index - 1]
                                                          ['description'],
                                                      style: const TextStyle(
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                          color: Color(
                                                              0XFF344054))),
                                                ),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                      DateFormat('d MMM, y')
                                                          .format(DateTime.parse(
                                                              filteredTransactions[
                                                                      index - 1]
                                                                  [
                                                                  'transactionDate']))
                                                          .toString(),
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: 12,
                                                          color: Color(
                                                              0XFF667085))),
                                                )
                                              ],
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Container(
                                                    height: 20,
                                                    width: 75,
                                                    color: filteredTransactions[
                                                                        index -
                                                                            1][
                                                                    'status'] ==
                                                                'Unassigned' ||
                                                            filteredTransactions[
                                                                        index -
                                                                            1][
                                                                    'status'] ==
                                                                'Assigned'
                                                        ? const Color(
                                                            0XFFFFEFEF)
                                                        : const Color(
                                                            0XFFE5FFE9),
                                                    child: Center(
                                                      child: Text(
                                                          filteredTransactions[index - 1]['status'] ==
                                                                      'Unassigned' ||
                                                                  filteredTransactions[index - 1]['status'] ==
                                                                      'Assigned'
                                                              ? 'Unmatched'
                                                              : 'Matched',
                                                          style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: filteredTransactions[index - 1]['status'] ==
                                                                          'Unassigned' ||
                                                                      filteredTransactions[index - 1]['status'] ==
                                                                          'Assigned'
                                                                  ? const Color(
                                                                      0XFFFF1B1B)
                                                                  : const Color(
                                                                      0XFF009318))),
                                                    ),
                                                  ),
                                                ),
                                                filteredTransactions[index - 1]
                                                            ['amount'] !=
                                                        null
                                                    ? Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: Text(
                                                            filteredTransactions[index - 1]['amount']
                                                                    .toString()
                                                                    .startsWith(
                                                                        '-')
                                                                ? '(${(filteredTransactions[index - 1]['amount']).abs().toString()})'
                                                                : filteredTransactions[index - 1][
                                                                        'amount']
                                                                    .toString(),
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 16,
                                                                color: filteredTransactions[index - 1]['amount']
                                                                        .toString()
                                                                        .startsWith(
                                                                            '-')
                                                                    ? const Color(
                                                                        0XFFFF1B1B)
                                                                    : const Color(
                                                                        0XFF009318))),
                                                      )
                                                    : const SizedBox()
                                              ],
                                            ),
                                          ),
                                        ],
                                      )),
                                  tilePadding: const EdgeInsets.only(
                                      left: 10, right: 10),
                                  children: [
                                    if ((filteredTransactions[index - 1]
                                                    ['matchData'] !=
                                                null &&
                                            filteredTransactions[index - 1]
                                                    ['matchData']
                                                .isNotEmpty) ||
                                        (filteredTransactions[index - 1]
                                                    ['relatedData'] !=
                                                null &&
                                            filteredTransactions[index - 1]
                                                    ['relatedData']
                                                .isNotEmpty)) ...[
                                      Theme(
                                        data: Theme.of(context).copyWith(
                                            dividerColor: Colors.transparent),
                                        child: ExpansionTile(
                                          tilePadding: const EdgeInsets.only(
                                              left: 10, right: 10),
                                          backgroundColor: Colors.white,
                                          showTrailingIcon: false,
                                          onExpansionChanged: (selected) {
                                            if (selected) {
                                              expandedTileIndex = index;
                                            } else if (expandedTileIndex ==
                                                index) {
                                              expandedTileIndex = null;
                                            }
                                            setState(() {});
                                          },
                                          title: Container(
                                            color: Colors.white,
                                            child: Column(children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Expanded(
                                                      child: Divider()),
                                                  Text(
                                                      filteredTransactions[
                                                                          index -
                                                                              1]
                                                                      [
                                                                      'matchData'] !=
                                                                  null &&
                                                              filteredTransactions[
                                                                          index -
                                                                              1]
                                                                      [
                                                                      'matchData']
                                                                  .isNotEmpty &&
                                                              filteredTransactions[
                                                                          index -
                                                                              1]
                                                                      [
                                                                      'matchData'] !=
                                                                  null &&
                                                              filteredTransactions[
                                                                          index -
                                                                              1]
                                                                      [
                                                                      'relatedData']
                                                                  .isEmpty
                                                          ? ' Suggested match '
                                                          : ' Matched To ',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: 12,
                                                          color: Color(
                                                              0XFF667085))),
                                                  const Expanded(
                                                      child: Divider()),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              filteredTransactions[index - 1]
                                                              ['matchData'] !=
                                                          null &&
                                                      filteredTransactions[index - 1]
                                                              ['matchData']
                                                          .isNotEmpty &&
                                                      filteredTransactions[index - 1]
                                                              ['matchData'] !=
                                                          null &&
                                                      filteredTransactions[index - 1]
                                                              ['relatedData']
                                                          .isEmpty
                                                  ? getMatchWidget(
                                                      filteredTransactions[index - 1]
                                                          ['matchData'],
                                                      'match',
                                                      index)
                                                  : getMatchWidget(
                                                      filteredTransactions[
                                                              index - 1]
                                                          ['relatedData'],
                                                      'related',
                                                      index),
                                              const SizedBox(height: 10)
                                            ]),
                                          ),
                                          children: [
                                            if (filteredTransactions[index - 1]
                                                        ['matchData'] !=
                                                    null &&
                                                filteredTransactions[index - 1]
                                                        ['matchData']
                                                    .isNotEmpty &&
                                                filteredTransactions[index - 1]
                                                        ['matchData'] !=
                                                    null &&
                                                filteredTransactions[index - 1]
                                                        ['relatedData']
                                                    .isEmpty) ...[
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                height: MediaQuery.of(
                                                            navigatorKey
                                                                .currentContext!)
                                                        .size
                                                        .height *
                                                    0.4,
                                                color: Colors.white,
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      height: 40,
                                                      width: double.maxFinite,
                                                      color: const Color(
                                                          0XFFF9FAFB),
                                                      child: const Text(
                                                          'Reconcile',
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: Color(
                                                                  0XFF101828))),
                                                    ),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      color: Colors.white,
                                                      height: 40,
                                                      width: double.maxFinite,
                                                      child: const Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Expanded(
                                                              child: Divider()),
                                                          Text(' Transactions ',
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                  fontSize: 12,
                                                                  color: Color(
                                                                      0XFF667085))),
                                                          Expanded(
                                                              child: Divider()),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      color: Colors.white,
                                                      height: 40,
                                                      width: double.maxFinite,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                              filteredTransactions[
                                                                      index - 1]
                                                                  [
                                                                  'description'],
                                                              style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontSize: 12,
                                                                  color: Color(
                                                                      0XFF667085))),
                                                          Text(
                                                              (filteredTransactions[
                                                                          index -
                                                                              1]
                                                                      [
                                                                      'amount'])
                                                                  .abs()
                                                                  .toString(),
                                                              style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontSize: 12,
                                                                  color: Color(
                                                                      0XFF101828))),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      color: Colors.white,
                                                      height: 40,
                                                      width: double.maxFinite,
                                                      child: const Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Expanded(
                                                              child: Divider()),
                                                          Text(' Expense ',
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                  fontSize: 12,
                                                                  color: Color(
                                                                      0XFF667085))),
                                                          Expanded(
                                                              child: Divider()),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      color: Colors.white,
                                                      height: 40,
                                                      width: double.maxFinite,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                              filteredTransactions[index -
                                                                              1]
                                                                          ['matchData']
                                                                      [
                                                                      'supplierName'] ??
                                                                  'Supplier',
                                                              style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontSize: 12,
                                                                  color: Color(
                                                                      0XFF667085))),
                                                          Text(
                                                              (filteredTransactions[index -
                                                                              1]
                                                                          ['matchData']
                                                                      [
                                                                      'amountDue'])
                                                                  .abs()
                                                                  .toString(),
                                                              style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontSize: 12,
                                                                  color: Color(
                                                                      0XFF101828))),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      color: const Color(
                                                          0XFFFFFCDE),
                                                      height: 50,
                                                      width: double.maxFinite,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          const Text(
                                                              'Difference',
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 12,
                                                                  color: Color(
                                                                      0XFF101828))),
                                                          Text(
                                                              (filteredTransactions[index - 1]
                                                                              [
                                                                              'matchData']
                                                                          [
                                                                          'amountDue'] +
                                                                      filteredTransactions[index -
                                                                              1]
                                                                          [
                                                                          'amount'])
                                                                  .toString(),
                                                              style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 12,
                                                                  color: Color(
                                                                      0XFF101828))),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    ElevatedButton(
                                                      style: ButtonStyle(
                                                          shape: WidgetStateProperty.all<
                                                                  RoundedRectangleBorder>(
                                                              RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                          8.0))),
                                                          fixedSize:
                                                              WidgetStateProperty
                                                                  .all(const Size(
                                                                      double
                                                                          .maxFinite,
                                                                      48)),
                                                          backgroundColor:
                                                              WidgetStateProperty.all(
                                                                  clickableColor)),
                                                      onPressed: () async {
                                                        setState(() {
                                                          showSpinner = true;
                                                        });
                                                        final updateResp = await ApiService.updateSuggestedMatches(
                                                            filteredTransactions[
                                                                        index -
                                                                            1][
                                                                    'matchData']
                                                                [
                                                                'unreconciledReportId'],
                                                            filteredTransactions[
                                                                        index -
                                                                            1][
                                                                    'matchData']
                                                                ['id'],
                                                            selectedOrgId);
                                                        await preparePageContent();
                                                        if (updateResp ==
                                                            false) {
                                                          ScaffoldMessenger.of(
                                                                  navigatorKey
                                                                      .currentContext!)
                                                              .showSnackBar(
                                                                  const SnackBar(
                                                                      content: Text(
                                                                          'We were unable to update the transaction, please try again.')));
                                                        }
                                                      },
                                                      child: const Text(
                                                        'Match',
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 14),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ]
                                          ],
                                        ),
                                      )
                                    ]
                                  ]),
                            ),
                          );
                        }),
                  )),
            )),
        onPopInvokedWithResult: (didPop, result) {
          Navigator.of(navigatorKey.currentContext!)
              .popUntil((route) => route.isFirst);
        });
  }
}
