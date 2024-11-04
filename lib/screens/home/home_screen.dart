import 'dart:io';
import 'dart:math';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_debouncer/flutter_debouncer.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:synced/main.dart';
import 'package:synced/screens/expenses/update_expense_data.dart';
import 'package:synced/screens/home/expenses_tab_screen.dart';
import 'package:synced/screens/transactions/transactions_tab_screen.dart';
import 'package:synced/utils/api_services.dart';
import 'package:synced/utils/constants.dart';

bool showUploadingInvoice = false;
Map uploadingData = {};
bool showSpinner = false;
List reviewExpenses = [];
List processedExpenses = [];
TextEditingController notesController = TextEditingController();
TextEditingController reviewSearchController = TextEditingController();
TextEditingController processedSearchController = TextEditingController();
RefreshController refreshController = RefreshController();
final Debouncer reviewDebouncer = Debouncer();
final Debouncer processedDebouncer = Debouncer();
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
  final int pageIndex;
  const HomeScreen({super.key, required this.pageIndex});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final PersistentTabController _controller = PersistentTabController();
  List organisations = [];
  late TabController tabController;

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
      _controller.index = 0;
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
            context: navigatorKey.currentContext!,
            builder: (context) => StatefulBuilder(
                builder: (context, setState) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0)),
                      insetPadding: const EdgeInsets.all(10),
                      backgroundColor: Colors.white,
                      title: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: const Color(0XFFF9FAFB),
                        ),
                        height: MediaQuery.of(context).size.height * 0.075,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('  Add Note (Optional)',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: headingColor)),
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
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade400,
                                          width: 0.4)),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
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
                                              BorderRadius.circular(12.0))),
                                  fixedSize: WidgetStateProperty.all(Size(
                                      MediaQuery.of(context).size.width * 0.8,
                                      MediaQuery.of(context).size.height *
                                          0.06)),
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
                                    _controller.index = 0;
                                  });
                                  ApiService.uploadInvoice(
                                          imagesPath!.first, selectedOrgId, '')
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
                    )));
      } else if (imagesPath!.isEmpty) {
        Navigator.pushAndRemoveUntil(
            navigatorKey.currentContext!,
            MaterialPageRoute(
                builder: (context) => const HomeScreen(pageIndex: 0)),
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

  List<PersistentBottomNavBarItem> _navBarsItems() {
    ScrollController scrollController1 = ScrollController();
    ScrollController scrollController2 = ScrollController();
    ScrollController scrollController3 = ScrollController();

    return [
      PersistentBottomNavBarItem(
        icon: Image.asset(
            _controller.index == 0
                ? 'assets/nav_bar/expenses-yellow.png'
                : 'assets/nav_bar/expenses-grey.png',
            height: 60,
            width: 60),
        scrollController: scrollController1,
        routeAndNavigatorSettings: RouteAndNavigatorSettings(
          initialRoute: "/expenses",
          routes: {
            "/expenses": (final context) =>
                ExpensesTabScreen(tabController: tabController),
            "/create-expense": (final context) => Container(),
            "/transactions": (final context) => const TransactionsTabScreen()
          },
        ),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.add, color: Colors.white, size: 35),
        activeColorPrimary: clickableColor,
        inactiveColorPrimary: textColor,
        scrollController: scrollController2,
        routeAndNavigatorSettings: RouteAndNavigatorSettings(
          initialRoute: "/expenses",
          routes: {
            "/expenses": (final context) =>
                ExpensesTabScreen(tabController: tabController),
            "/create-expense": (final context) => Container(),
            "/transactions": (final context) => const TransactionsTabScreen()
          },
        ),
      ),
      PersistentBottomNavBarItem(
        icon: Image.asset(
            _controller.index == 2
                ? 'assets/nav_bar/transactions-yellow.png'
                : 'assets/nav_bar/transactions-grey.png',
            height: 75,
            width: 75),
        scrollController: scrollController3,
        routeAndNavigatorSettings: RouteAndNavigatorSettings(
          initialRoute: "/expenses",
          routes: {
            "/expenses": (final context) =>
                ExpensesTabScreen(tabController: tabController),
            "/create-expense": (final context) => Container(),
            "/transactions": (final context) => const TransactionsTabScreen()
          },
        ),
      ),
    ];
  }

  getUnprocessedExpenses(page) async {
    if (page == 1) {
      reviewExpenses.clear();
    }
    final resp =
        await ApiService.getExpenses(false, selectedOrgId, '', page, pageSize);
    if (resp.isNotEmpty) {
      reviewExpenses += resp['invoices'];
    }

    try {
      final isLastPage = resp['invoices'].length < pageSize;
      if (isLastPage) {
        reviewPagingController.appendLastPage(resp['invoices']);
      } else {
        final nextPageKey = page + resp['invoices'].length;
        reviewPagingController.appendPage(resp['invoices'], nextPageKey);
      }
    } catch (error) {
      reviewPagingController.error = error;
    }

    setState(() {
      showSpinner = false;
      refreshController.refreshCompleted();
    });

    final tempDir = await getTemporaryDirectory();

    for (var exp in reviewExpenses) {
      if (await File('${tempDir.path}/${exp['invoicePdfUrl']}.pdf').exists() ==
          true) {
        setState(() {
          exp['invoice_path'] = '${tempDir.path}/${exp['invoicePdfUrl']}.pdf';
        });
      } else if (await File('${tempDir.path}/${exp['invoicePdfUrl']}.jpeg')
              .exists() ==
          true) {
        setState(() {
          exp['invoice_path'] = '${tempDir.path}/${exp['invoicePdfUrl']}.jpeg';
        });
      } else {
        ApiService.downloadInvoice(exp['invoicePdfUrl'], selectedOrgId)
            .then((invoiceResp) {
          setState(() {
            exp['invoice_path'] = invoiceResp['path'];
          });
          if (kDebugMode) {
            print(invoiceResp);
          }
        });
      }
    }
  }

  getProcessedExpenses(page) async {
    if (page == 1) {
      processedExpenses.clear();
    }
    final resp =
        await ApiService.getExpenses(true, selectedOrgId, '', page, pageSize);
    if (resp.isNotEmpty) {
      processedExpenses += resp['invoices'];
    }

    try {
      final isLastPage = resp['invoices'].length < pageSize;
      if (isLastPage) {
        processedPagingController.appendLastPage(resp['invoices']);
      } else {
        final nextPageKey = page + resp['invoices'].length;
        processedPagingController.appendPage(resp['invoices'], nextPageKey);
      }
    } catch (error) {
      processedPagingController.error = error;
    }

    setState(() {
      showSpinner = false;
    });

    final tempDir = await getTemporaryDirectory();

    for (var exp in processedExpenses) {
      if (await File('${tempDir.path}/${exp['invoicePdfUrl']}.pdf').exists() ==
          true) {
        setState(() {
          exp['invoice_path'] = '${tempDir.path}/${exp['invoicePdfUrl']}.pdf';
        });
      } else if (await File('${tempDir.path}/${exp['invoicePdfUrl']}.jpeg')
              .exists() ==
          true) {
        setState(() {
          exp['invoice_path'] = '${tempDir.path}/${exp['invoicePdfUrl']}.jpeg';
        });
      } else {
        ApiService.downloadInvoice(exp['invoicePdfUrl'], selectedOrgId)
            .then((invoiceResp) {
          setState(() {
            exp['invoice_path'] = invoiceResp['path'];
          });
          if (kDebugMode) {
            print(invoiceResp);
          }
        });
      }
    }
  }

  @override
  void initState() {
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      setState(() {});
    });
    tabController.index = widget.pageIndex;
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
      getUnprocessedExpenses(1);
      getProcessedExpenses(1);
    } else {
      setState(() {
        showSpinner = false;
        refreshController.refreshCompleted();
      });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
        inAsyncCall: showSpinner,
        opacity: 1.0,
        color: Colors.white,
        progressIndicator: appLoader,
        child: SmartRefresher(
          onRefresh: getOrganisations,
          controller: refreshController,
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: const Color(0xfffbfbfb),
            appBar: AppBar(
              backgroundColor: Colors.white,
              centerTitle: true,
              title: DropdownButtonHideUnderline(
                  child: DropdownButton2(
                      dropdownStyleData: const DropdownStyleData(
                          elevation: 1,
                          decoration: BoxDecoration(color: Colors.white)),
                      menuItemStyleData: const MenuItemStyleData(
                          overlayColor: WidgetStatePropertyAll(Colors.white)),
                      onChanged: (value) {
                        setState(() {
                          selectedOrgId = value!;
                        });
                        getUnprocessedExpenses(1);
                        getProcessedExpenses(1);
                      },
                      items: getDropdownEntries(),
                      value: selectedOrgId)),
              bottom: _controller.index == 0
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
            body: PersistentTabView(
              navigatorKey.currentContext!,
              controller: _controller,
              screens: [
                ExpensesTabScreen(tabController: tabController),
                Container(),
                const TransactionsTabScreen()
              ],
              items: _navBarsItems(),
              handleAndroidBackButtonPress: false,
              hideOnScrollSettings:
                  const HideOnScrollSettings(hideNavBarOnScroll: true),
              resizeToAvoidBottomInset: true,
              stateManagement: false,
              hideNavigationBarWhenKeyboardAppears: true,
              popBehaviorOnSelectedNavBarItemPress: PopBehavior.none,
              backgroundColor: Colors.white,
              isVisible: true,
              animationSettings: const NavBarAnimationSettings(
                navBarItemAnimation: ItemAnimationSettings(
                  // Navigation Bar's items animation properties.
                  duration: Duration(milliseconds: 400),
                  curve: Curves.ease,
                ),
                screenTransitionAnimation: ScreenTransitionAnimationSettings(
                  // Screen transition animation on change of selected tab.
                  animateTabTransition: true,
                  duration: Duration(milliseconds: 200),
                  screenTransitionAnimationType:
                      ScreenTransitionAnimationType.fadeIn,
                ),
              ),
              confineToSafeArea: true,
              navBarHeight: MediaQuery.of(context).size.height * 0.085,
              navBarStyle: NavBarStyle.style15,
              onItemSelected: (index) {
                if (_controller.index == 1) {
                  startScan();
                } else {
                  setState(() {
                    _controller.index = index;
                  });
                }
              },
            ),
          ),
        ));
  }
}
