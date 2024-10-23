import 'dart:io';
import 'dart:math';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
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
TextEditingController? notesController;
String fileSize = '';
List<String>? imagesPath = [];

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
            imagesPath!.first, selectedOrgId, notesController?.text)
        .then((uploadResp) {
      setState(() {
        showUploadingInvoice = false;
        uploadingData = {};
      });
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
      imagesPath = await CunningDocumentScanner.getPictures(
          noOfPages: 1, isGalleryImportAllowed: true);
      setState(() {});
      if (imagesPath!.isNotEmpty) {
        fileSize = await getFileSize(imagesPath!.first, 1);
        notesController = TextEditingController();
        showDialog(
            context: navigatorKey.currentContext!,
            builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: const Text('Add Note (Optional)',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0XFF2A2A2A))),
                  content: Container(
                    color: Colors.white,
                    height: MediaQuery.of(navigatorKey.currentContext!)
                            .size
                            .height *
                        0.35,
                    width:
                        MediaQuery.of(navigatorKey.currentContext!).size.width *
                            0.9,
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                              focusColor: Colors.grey.shade400,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade400, width: 0.4)),
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
                                          BorderRadius.circular(24.0))),
                              fixedSize: WidgetStateProperty.all(Size(
                                  MediaQuery.of(context).size.width * 0.8,
                                  MediaQuery.of(context).size.height * 0.075)),
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
                                  Navigator.push(
                                      navigatorKey.currentContext!,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              UpdateExpenseData(
                                                  expense: uploadResp,
                                                  imagePath:
                                                      imagesPath!.first)));
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
                ));
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
                getExpensesWidget(context, setState, tabController, mounted),
            "/create-expense": (final context) => Container(),
            "/transactions": (final context) => getTransactionsWidget(
                context, setState, tabController, mounted),
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
                getExpensesWidget(context, setState, tabController, mounted),
            "/create-expense": (final context) => Container(),
            "/transactions": (final context) => getTransactionsWidget(
                context, setState, tabController, mounted),
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
                getExpensesWidget(context, setState, tabController, mounted),
            "/create-expense": (final context) => Container(),
            "/transactions": (final context) => getTransactionsWidget(
                context, setState, tabController, mounted),
          },
        ),
      ),
    ];
  }

  getUnprocessedExpenses() async {
    final resp = await ApiService.getExpenses(false, selectedOrgId, '');
    if (resp.isNotEmpty) {
      reviewExpenses = resp['invoices'];
    }

    setState(() {
      showSpinner = false;
    });

    for (var exp in reviewExpenses) {
      final invoiceResp =
          await ApiService.downloadInvoice(exp['invoicePdfUrl'], selectedOrgId);
      setState(() {
        exp['invoice_path'] = invoiceResp['path'];
      });
      if (kDebugMode) {
        print(invoiceResp);
      }
    }
  }

  getProcessedExpenses() async {
    final resp = await ApiService.getExpenses(true, selectedOrgId, '');
    if (resp.isNotEmpty) {
      processedExpenses = resp['invoices'];
    }

    for (var exp in processedExpenses) {
      final invoiceResp =
          await ApiService.downloadInvoice(exp['invoicePdfUrl'], selectedOrgId);
      setState(() {
        exp['invoice_path'] = invoiceResp['path'];
      });
      if (kDebugMode) {
        print(invoiceResp);
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
      if (selectedOrgId.isEmpty) {
        selectedOrgId = organisations[0]['organisationID'];
      }
    }
    getUnprocessedExpenses();
    getProcessedExpenses();
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
        progressIndicator: CircularProgressIndicator(
          color: clickableColor,
        ),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: const Color(0xfffbfbfb),
          appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: true,
            title: DropdownButtonHideUnderline(
                child: DropdownButton2(
                    onChanged: (value) {
                      setState(() {
                        selectedOrgId = value!;
                      });
                    },
                    items: getDropdownEntries(),
                    value: selectedOrgId)),
            bottom: TabBar(
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
                controller: tabController),
          ),
          body: PersistentTabView(
            navigatorKey.currentContext!,
            controller: _controller,
            screens: [
              getExpensesWidget(navigatorKey.currentContext!, setState,
                  tabController, mounted),
              Container(),
              getTransactionsWidget(context, setState, tabController, mounted),
            ],
            items: _navBarsItems(),
            handleAndroidBackButtonPress: true,
            hideOnScrollSettings:
                const HideOnScrollSettings(hideNavBarOnScroll: true),
            resizeToAvoidBottomInset: true,
            stateManagement: true,
            hideNavigationBarWhenKeyboardAppears: true,
            popBehaviorOnSelectedNavBarItemPress: PopBehavior.all,
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
            navBarHeight: MediaQuery.of(context).size.height * 0.1,
            navBarStyle: NavBarStyle.style15,
            onItemSelected: (index) {
              if (_controller.index == 1) {
                startScan();
              } else {
                setState(() {});
              }
            },
          ),
        ));
  }
}
