import 'dart:io';
import 'dart:math';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:synced/main.dart';
import 'package:synced/screens/auth/login.dart';
import 'package:synced/screens/expenses/update_expense_data.dart';
import 'package:synced/screens/home/expenses_tab_screen.dart';
import 'package:synced/screens/transactions/transactions_tab_screen.dart';
import 'package:synced/utils/api_services.dart';
import 'package:synced/utils/constants.dart';
import 'package:synced/utils/database_helper.dart';
import 'package:url_launcher/url_launcher.dart';

bool showUploadingInvoice = false;
Map<String, dynamic> uploadingData = {};
TextEditingController reviewSearchController = TextEditingController();
TextEditingController processedSearchController = TextEditingController();
String reviewSearchTerm = '';
String processedSearchTerm = '';

class HomeScreen extends StatefulWidget {
  final int tabIndex;
  final int navbarIndex;
  const HomeScreen({super.key, this.tabIndex = 0, this.navbarIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  List organisations = [];
  List reviewExpenses = [];
  List processedExpenses = [];
  final RefreshController refreshController =
      RefreshController(initialRefresh: false);
  final pageSize = 15;
  PagingController reviewPagingController = PagingController(firstPageKey: 1);
  PagingController processedPagingController =
      PagingController(firstPageKey: 1);
  List<String>? imagesPath = [];
  int selectedNavBarIndex = 0;
  String fileSize = '';
  bool showSpinner = false;
  TextEditingController notesController = TextEditingController();
  late TabController tabController;

  Future<String> getFileSize(String filepath, int decimals) async {
    var file = File(filepath);
    int bytes = await file.length();
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  uploadCallback(byteCount, totalByteLength) {
    setState(() {
      uploadingData['uploadProgress'] = byteCount / totalByteLength;
    });
  }

  _onPressed() {
    Navigator.pop(navigatorKey.currentContext!);
    setState(() {
      showUploadingInvoice = true;
      uploadingData = {
        'path': imagesPath!.first,
        'size': fileSize,
        'uploadProgress': 0.0
      };
      selectedNavBarIndex = 0;
    });
    ApiService.uploadInvoice(imagesPath!.first, selectedOrgId,
            notesController.text, uploadCallback)
        .then((uploadResp) {
      setState(() {
        showUploadingInvoice = false;
        uploadingData = {};
      });
      notesController.clear();
      if (uploadResp.isEmpty) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            const SnackBar(
                content: Text(
                    'We were unable to process the image, please try again.')));
        return;
      } else {
        reviewPagingController.refresh();
      }
    });
  }

  void startScan() async {
    if (!showUploadingInvoice) {
      if (await Permission.camera.request().isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please scan one page only")));
        imagesPath = await CunningDocumentScanner.getPictures(
            noOfPages: 1, isGalleryImportAllowed: true);
        setState(() {});
        if ((imagesPath?.length ?? 0) > 1) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'You have scanned ${imagesPath?.length} pages, only the first page will be saved')));
        }
        if (imagesPath?.isNotEmpty ?? false) {
          fileSize = await getFileSize(imagesPath!.first, 1);
          showDialog(
              barrierDismissible: false,
              context: navigatorKey.currentContext!,
              builder: (context) => StatefulBuilder(
                  builder: (context, setState) => SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0)),
                          insetPadding: const EdgeInsets.all(10),
                          backgroundColor: Colors.white,
                          title: Container(
                            decoration: const BoxDecoration(
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10)),
                                color: Color(0XFFF9FAFB),
                                border: Border(
                                    bottom: BorderSide(color: Colors.grey))),
                            height: MediaQuery.of(context).size.height * 0.065,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                  padding: EdgeInsets.only(
                                      left: MediaQuery.of(context).size.width *
                                          0.075),
                                  child: Text('Add Note (Optional)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: headingColor))),
                            ),
                          ),
                          titlePadding: const EdgeInsets.all(0),
                          content: Container(
                            color: Colors.white,
                            width: MediaQuery.of(navigatorKey.currentContext!)
                                    .size
                                    .width *
                                0.9,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  keyboardType: TextInputType.multiline,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                      hintText: 'Add expense details',
                                      focusColor: Colors.grey.shade400,
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade400,
                                              width: 0.4)),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade400,
                                              width: 0.4))),
                                  maxLines: 5,
                                  controller: notesController,
                                  autofocus: true,
                                  enabled: true,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  style: ButtonStyle(
                                      shape: WidgetStateProperty.all<
                                              RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0))),
                                      fixedSize: WidgetStateProperty.all(Size(
                                          MediaQuery.of(context).size.width *
                                              0.9,
                                          40)),
                                      backgroundColor: WidgetStateProperty.all(
                                          const Color(0XFF009318))),
                                  onPressed: _onPressed,
                                  child: const Text(
                                    'Submit',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                TextButton(
                                    onPressed: () async {
                                      Navigator.pop(
                                          navigatorKey.currentContext!);
                                      setState(() {
                                        showUploadingInvoice = true;
                                        uploadingData = {
                                          'path': imagesPath!.first,
                                          'size': fileSize
                                        };
                                        selectedNavBarIndex = 0;
                                      });
                                      ApiService.uploadInvoice(
                                              imagesPath!.first,
                                              selectedOrgId,
                                              '',
                                              uploadCallback)
                                          .then((uploadResp) {
                                        showUploadingInvoice = false;
                                        uploadingData = {};
                                        if (uploadResp.isEmpty) {
                                          ScaffoldMessenger.of(
                                                  navigatorKey.currentContext!)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      'We were unable to process the image, please try again.')));
                                          return;
                                        } else {
                                          Navigator.push(
                                              navigatorKey.currentContext!,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      UpdateExpenseData(
                                                          expense: uploadResp,
                                                          imagePath:
                                                              'https://syncedblobstaging.blob.core.windows.net/invoices/${uploadResp['pdfUrl']}',
                                                          isProcessed: false)));
                                        }
                                      });
                                    },
                                    child: const Text('Skip',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0XFFFF4E4E))))
                              ],
                            ),
                          ),
                        ),
                      )));
        }
      } else if (await Permission.camera.isPermanentlyDenied) {
        openAppSettings();
      }
    } else {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(
              content: Text(
                  'Expense currently progressing. Please wait for completion and try again')));
      return;
    }
  }

  List<DropdownMenuItem> getDropdownEntries() {
    List<DropdownMenuItem> entries = [];
    for (var org in organisations) {
      entries.add(DropdownMenuItem(
          value: org['organisationID'],
          child: Text(
            org['organisationName'],
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          )));
    }
    return entries;
  }

  getUnprocessedExpenses(page, searchTerm) async {
    if (page == 1) {
      reviewExpenses.clear();
      reviewPagingController.refresh();
    }
    final resp = await ApiService.getExpenses(
        false, selectedOrgId, searchTerm, page, pageSize);
    if (resp.isNotEmpty) {
      setState(() {
        reviewExpenses += resp['invoices'];
      });
    }

    try {
      final isLastPage = resp['invoices'].length < pageSize;
      if (isLastPage) {
        reviewPagingController.appendLastPage(resp['invoices']);
      } else {
        final nextPageKey = page + 1;
        reviewPagingController.appendPage(resp['invoices'], nextPageKey);
      }
    } catch (error) {
      reviewPagingController.error = error;
    }
    setState(() {
      showSpinner = false;
    });
    refreshController.loadComplete();
    refreshController.refreshCompleted();

    for (var exp in reviewExpenses) {
      exp['invoice_path'] =
          'https://syncedblobstaging.blob.core.windows.net/invoices/${exp['invoicePdfUrl']}';
    }
    setState(() {});
  }

  getProcessedExpenses(page, searchTerm) async {
    if (page == 1) {
      processedExpenses.clear();
      processedPagingController.refresh();
    }
    final resp = await ApiService.getExpenses(
        true, selectedOrgId, searchTerm, page, pageSize);
    if (resp.isNotEmpty) {
      setState(() {
        processedExpenses += resp['invoices'];
      });
    }

    try {
      final isLastPage = resp['invoices'].length < pageSize;
      if (isLastPage) {
        processedPagingController.appendLastPage(resp['invoices']);
      } else {
        final nextPageKey = page + 1;
        processedPagingController.appendPage(resp['invoices'], nextPageKey);
      }
    } catch (error) {
      processedPagingController.error = error;
    }

    setState(() {
      showSpinner = false;
    });
    refreshController.loadComplete();
    refreshController.refreshCompleted();

    for (var exp in processedExpenses) {
      exp['invoice_path'] =
          'https://syncedblobstaging.blob.core.windows.net/invoices/${exp['invoicePdfUrl']}';
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      setState(() {});
    });
    tabController.index = widget.tabIndex;
    selectedNavBarIndex = widget.navbarIndex;
    reviewPagingController.addPageRequestListener((pageKey) {
      setState(() {
        showSpinner = true;
      });
      getUnprocessedExpenses(pageKey, reviewSearchTerm);
      setState(() {
        showSpinner = false;
      });
    });
    processedPagingController.addPageRequestListener((pageKey) {
      getProcessedExpenses(pageKey, processedSearchTerm);
    });
    getOrganisations();
  }

  getOrganisations() async {
    setState(() {
      showSpinner = true;
    });

    final resp = await ApiService.getOrganisations();
    if (!resp['failed']) {
      organisations = resp['data'];
      if (selectedOrgId.isEmpty && organisations.isNotEmpty) {
        selectedOrgId = organisations[0]['organisationID'];
      }
    }
    if (selectedOrgId.isNotEmpty) {
      final resp = await ApiService.getDefaultCurrency(selectedOrgId);
      setState(() {
        defaultCurrency = resp['currency'] ?? 'USD';
      });
      await getUnprocessedExpenses(1, '');
      await getProcessedExpenses(1, '');
    } else {
      setState(() {
        showSpinner = false;
        reviewPagingController.nextPageKey = 1;
        processedPagingController.nextPageKey = 1;
      });
      refreshController.loadComplete();
      refreshController.refreshCompleted();
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(
              content: Text('Please select or create an organization.')));
    }
  }

  @override
  void dispose() {
    tabController.removeListener(() {
      setState(() {});
    });
    tabController.dispose();
    refreshController.dispose();
    reviewPagingController.dispose();
    processedPagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: showSpinner,
      opacity: 1.0,
      color: Colors.white,
      progressIndicator: appLoader,
      child: Scaffold(
          extendBody: true,
          resizeToAvoidBottomInset: false,
          backgroundColor: const Color(0xfffbfbfb),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.white,
            centerTitle: true,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(width: 25),
                SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: DropdownButtonHideUnderline(
                        child: DropdownButton(
                            alignment: AlignmentDirectional.center,
                            dropdownColor: Colors.white,
                            isExpanded: true,
                            selectedItemBuilder: (BuildContext context) {
                              return organisations.map<Widget>((org) {
                                return Container(
                                    alignment: Alignment.center,
                                    child: Center(
                                      child: Text(org['organisationName'],
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center),
                                    ));
                              }).toList();
                            },
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black),
                            onChanged: (value) async {
                              if (showUploadingInvoice) {
                                ScaffoldMessenger.of(
                                        navigatorKey.currentContext!)
                                    .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Expense currently progressing. Please wait for completion and try again')));
                                return;
                              }
                              setState(() {
                                showSpinner = true;
                                selectedOrgId = value!;
                              });
                              reviewPagingController.refresh();
                              processedPagingController.refresh();
                            },
                            menuWidth: MediaQuery.of(context).size.width,
                            items: getDropdownEntries(),
                            value: selectedOrgId))),
                SizedBox(
                  width: 25,
                  child: PopupMenuButton<int>(
                    color: Colors.white,
                    icon: const Icon(Icons.more_vert, size: 25),
                    onSelected: (item) async {
                      switch (item) {
                        case 0:
                          if (!await launchUrl(
                              Uri.parse('https://help.syncedhq.com/en/'))) {
                            throw Exception('Could not launch help center');
                          }
                          break;
                        case 1:
                          final DatabaseHelper _db = DatabaseHelper();
                          await _db.deleteUsers();
                          selectedOrgId = '';
                          Navigator.pushReplacement(
                              navigatorKey.currentContext!,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()));
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<int>(
                          value: 0,
                          child: Row(
                            children: [
                              Icon(Icons.business_center_outlined),
                              SizedBox(width: 10),
                              Text('Help Center')
                            ],
                          )),
                      const PopupMenuItem<int>(
                          value: 1,
                          child: Row(
                            children: [
                              Icon(Icons.logout),
                              SizedBox(width: 10),
                              Text('Logout')
                            ],
                          )),
                    ],
                  ),
                ),
              ],
            ),
            bottom: selectedNavBarIndex == 0
                ? TabBar(
                    indicatorColor: clickableColor,
                    labelColor: clickableColor,
                    unselectedLabelColor: textColor,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(
                        text: 'For Review',
                      ),
                      Tab(
                        text: 'Processed',
                      ),
                    ],
                    controller: tabController)
                : null,
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0XFFECECEC)))),
            child: BottomNavigationBar(
              items: [
                BottomNavigationBarItem(
                    icon: Image.asset('assets/nav_bar/expenses-grey.png',
                        height: 25, width: 25),
                    activeIcon: Image.asset(
                        'assets/nav_bar/expenses-yellow.png',
                        height: 25,
                        width: 25),
                    label: 'Expenses'),
                BottomNavigationBarItem(
                    icon: Image.asset('assets/nav_bar/transactions-grey.png',
                        height: 30, width: 30),
                    activeIcon: Image.asset(
                        'assets/nav_bar/transactions-yellow.png',
                        height: 30,
                        width: 30),
                    label: 'Transactions'),
              ],
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: clickableColor,
              unselectedItemColor: const Color(0XFF888888),
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: clickableColor),
              unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: Color(0XFF888888)),
              showSelectedLabels: true,
              showUnselectedLabels: true,
              currentIndex: selectedNavBarIndex,
              onTap: (index) {
                if (index == selectedNavBarIndex) return;
                setState(() {
                  selectedNavBarIndex = index;
                });
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              startScan();
            },
            shape: const CircleBorder(),
            backgroundColor: clickableColor,
            child: const Icon(Icons.add,
                color: Colors.white,
                size: 35,
                shadows: <Shadow>[
                  Shadow(color: Colors.white, blurRadius: 10.0)
                ]),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          body: selectedNavBarIndex == 0
              ? SmartRefresher(
                  controller: refreshController,
                  onRefresh: () async {
                    if (tabController.index == 0) {
                      setState(() {
                        reviewSearchTerm = '';
                      });
                      reviewPagingController.refresh();
                    } else {
                      setState(() {
                        processedSearchTerm = '';
                      });
                      processedPagingController.refresh();
                    }
                  },
                  onLoading: getOrganisations,
                  child: ExpensesTabScreen(
                    tabController: tabController,
                    reviewPagingController: reviewPagingController,
                    processedPagingController: processedPagingController,
                    reviewExpenses: reviewExpenses,
                    processedExpenses: processedExpenses,
                  ),
                )
              : const TransactionsTabScreen()),
    );
  }
}
