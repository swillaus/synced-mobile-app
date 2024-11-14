import 'dart:io';
import 'dart:math';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_debouncer/flutter_debouncer.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';
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
Map uploadingData = {};
bool showSpinner = false;
List reviewExpenses = [];
List processedExpenses = [];
TextEditingController notesController = TextEditingController();
TextEditingController reviewSearchController = TextEditingController();
TextEditingController processedSearchController = TextEditingController();
final PageController _controller = PageController();
final Debouncer reviewDebouncer = Debouncer();
final Debouncer processedDebouncer = Debouncer();
int selectedNavBarIndex = 0;
String fileSize = '';
List<String>? imagesPath = [];
const pageSize = 15;
final PagingController reviewPagingController =
    PagingController(firstPageKey: 1);
final PagingController processedPagingController =
    PagingController(firstPageKey: 1);
int reviewPageKey = 1;
int processedPageKey = 1;

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
  late TabController tabController;
  final RefreshController refreshController =
      RefreshController(initialRefresh: false);

  Future<String> getFileSize(String filepath, int decimals) async {
    var file = File(filepath);
    int bytes = await file.length();
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  _onPressed() {
    Navigator.pop(navigatorKey.currentContext!);
    setState(() {
      showUploadingInvoice = true;
      uploadingData = {'path': imagesPath!.first, 'size': fileSize};
      selectedNavBarIndex = 0;
    });
    ApiService.uploadInvoice(
            imagesPath!.first, selectedOrgId, notesController.text)
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
        Navigator.push(
            navigatorKey.currentContext!,
            MaterialPageRoute(
                builder: (context) => UpdateExpenseData(
                    expense: uploadResp, imagePath: imagesPath!.first)));
      }
    });
  }

  void startScan() async {
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
      if (imagesPath!.isNotEmpty) {
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
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: const Color(0XFFF9FAFB),
                          ),
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
                          height: MediaQuery.of(navigatorKey.currentContext!)
                                  .size
                                  .height *
                              0.35,
                          width: MediaQuery.of(navigatorKey.currentContext!)
                                  .size
                                  .width *
                              0.9,
                          child: Column(
                            children: [
                              TextField(
                                decoration: InputDecoration(
                                    hintText: 'Add expense details',
                                    focusColor: Colors.grey.shade400,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade400,
                                            width: 0.4)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
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
                                        MediaQuery.of(context).size.width * 0.9,
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
                                    Navigator.pop(navigatorKey.currentContext!);
                                    setState(() {
                                      showUploadingInvoice = true;
                                      uploadingData = {
                                        'path': imagesPath!.first,
                                        'size': fileSize
                                      };
                                      selectedNavBarIndex = 0;
                                    });
                                    ApiService.uploadInvoice(imagesPath!.first,
                                            selectedOrgId, '')
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
                                        getUnprocessedExpenses(1);
                                        getProcessedExpenses(1);
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
      } else if (imagesPath!.isEmpty) {
        Navigator.pushAndRemoveUntil(
            navigatorKey.currentContext!,
            MaterialPageRoute(
                builder: (context) => const HomeScreen(tabIndex: 0)),
            (Route<dynamic> route) => false);
      }
    } else if (await Permission.camera.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  List<DropdownMenuItem> getDropdownEntries() {
    List<DropdownMenuItem> entries = [];
    for (var org in organisations) {
      entries.add(DropdownMenuItem(
          value: org['organisationID'], child: Text(org['organisationName'])));
    }
    return entries;
  }

  getUnprocessedExpenses(page) async {
    if (page == 1) {
      reviewExpenses.clear();
      reviewPageKey = 1;
    }
    final resp =
        await ApiService.getExpenses(false, selectedOrgId, '', page, pageSize);
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

  getProcessedExpenses(page) async {
    if (page == 1) {
      processedExpenses.clear();
      processedPageKey = 1;
    }
    final resp =
        await ApiService.getExpenses(true, selectedOrgId, '', page, pageSize);
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
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      setState(() {});
    });
    tabController.index = widget.tabIndex;
    selectedNavBarIndex = widget.navbarIndex;
    reviewPagingController.addPageRequestListener((pageKey) {
      reviewPageKey = pageKey;
      getUnprocessedExpenses(pageKey);
    });
    processedPagingController.addPageRequestListener((pageKey) {
      processedPageKey = pageKey;
      getProcessedExpenses(pageKey);
    });
    super.initState();
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
      ApiService.getDefaultCurrency(selectedOrgId).then((resp) {
        setState(() {
          defaultCurrency = resp['currency'] ?? 'USD';
        });
      });
      getUnprocessedExpenses(1);
      getProcessedExpenses(1);
    } else {
      setState(() {
        showSpinner = false;
        reviewPageKey = 1;
        processedPageKey = 1;
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
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xfffbfbfb),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.white,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(width: MediaQuery.of(context).size.width * 0.15),
              Center(
                child: DropdownButtonHideUnderline(
                    child: DropdownButton2(
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black),
                        dropdownStyleData: const DropdownStyleData(
                            elevation: 1,
                            decoration: BoxDecoration(color: Colors.white)),
                        menuItemStyleData: const MenuItemStyleData(
                            overlayColor: WidgetStatePropertyAll(Colors.white)),
                        onChanged: (value) {
                          setState(() {
                            selectedOrgId = value!;
                          });
                          ApiService.getDefaultCurrency(selectedOrgId)
                              .then((resp) {
                            setState(() {
                              defaultCurrency = resp['currency'] ?? 'USD';
                            });
                          });
                          getUnprocessedExpenses(1);
                          getProcessedExpenses(1);
                        },
                        items: getDropdownEntries(),
                        value: selectedOrgId)),
              ),
              SizedBox(width: MediaQuery.of(context).size.width * 0.04),
              Align(
                alignment: Alignment.centerRight,
                child: PopupMenuButton<int>(
                  color: Colors.white,
                  icon: const Icon(Icons.more_vert),
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
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0XFFECECEC)))),
          child: StylishBottomBar(
            items: [
              BottomBarItem(
                icon: Image.asset('assets/nav_bar/expenses-grey.png',
                    height: 50, width: 50),
                selectedIcon: Image.asset('assets/nav_bar/expenses-yellow.png',
                    height: 50, width: 50),
                title: const SizedBox(height: 0),
              ),
              BottomBarItem(
                icon: Padding(
                    padding: EdgeInsets.only(
                        left: MediaQuery.of(context).size.width * 0.25),
                    child: Image.asset('assets/nav_bar/transactions-grey.png')),
                selectedIcon: Padding(
                    padding: EdgeInsets.only(
                        left: MediaQuery.of(context).size.width * 0.25),
                    child:
                        Image.asset('assets/nav_bar/transactions-yellow.png')),
                title: const SizedBox(height: 0),
              ),
            ],
            option: AnimatedBarOptions(
                barAnimation: BarAnimation.fade, iconStyle: IconStyle.simple),
            hasNotch: false,
            fabLocation: StylishBarFabLocation.end,
            currentIndex: selectedNavBarIndex,
            notchStyle: NotchStyle.circle,
            onTap: (index) {
              if (index == selectedNavBarIndex) return;
              setState(() {
                selectedNavBarIndex = index;
              });
              _controller.jumpToPage(index);
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
              shadows: <Shadow>[Shadow(color: Colors.white, blurRadius: 10.0)]),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        body: PageView(
          controller: _controller,
          children: [
            SmartRefresher(
              controller: refreshController,
              onRefresh: getOrganisations,
              onLoading: getOrganisations,
              child: ExpensesTabScreen(tabController: tabController),
            ),
            const TransactionsTabScreen()
          ],
        ),
      ),
    );
  }
}
